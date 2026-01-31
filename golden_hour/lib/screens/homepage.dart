// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:golden_hour/components/custom_textformfields.dart';
import 'package:golden_hour/services/auth_service.dart';

// ignore: camel_case_types
class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

// ignore: camel_case_types
class _homepageState extends State<homepage> {
  int _currentIndex = 0;
  Completer<GoogleMapController> _mapController = Completer();
  bool _locationPermissionGranted = false;
  LatLng? _currentPosition;
  Key _googleMapKey = UniqueKey();
  bool _mapCreationFailed = false;
  bool _mapCreated = false;
  bool _mapCreationCheckScheduled = false;
  Timer? _cameraAnimationTimer;
  bool _isCameraAnimating = false;
  Set<Marker> _additionalMarkers = {};
  String? _nearestHospitalName;
  String? _nearestHospitalLocation;
  double? _nearestHospitalDistance;

  // Controllers and state for profile form (first name + last name فقط)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _StreetController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _CityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _AgeController = TextEditingController();
  final TextEditingController _MapController = TextEditingController();
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  bool _isSavingProfile = false;
  bool _profileLoadedOnce = false;

  @override
  void dispose() {
    // Cancel any pending camera animations to prevent buffer leaks
    _cameraAnimationTimer?.cancel();
    // Map controller is automatically managed by Flutter
    // No need for explicit disposal
    _nameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndFetch();
  }

  Future<void> _checkLocationPermissionAndFetch() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, we can't request permission programmatically.
      if (mounted) {
        setState(() {
          _locationPermissionGranted = false;
        });
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          _locationPermissionGranted = false;
        });
      }
      return;
    }

    // permission granted
    if (mounted) {
      setState(() {
        _locationPermissionGranted = true;
      });
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Ensure double precision for coordinates to prevent geometry unpacker errors
      final latLng = LatLng(pos.latitude.toDouble(), pos.longitude.toDouble());
      if (mounted) {
        setState(() {
          _currentPosition = latLng;
        });
      }

      if (_mapController.isCompleted && !_isCameraAnimating) {
        _isCameraAnimating = true;
        final controller = await _mapController.future;
        // Ensure double precision for camera animation
        final cameraPosition = LatLng(
          latLng.latitude.toDouble(),
          latLng.longitude.toDouble(),
        );
        // Cancel any pending animation
        _cameraAnimationTimer?.cancel();
        // Debounce camera animation to prevent buffer overflow
        _cameraAnimationTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && _mapController.isCompleted) {
            controller.animateCamera(CameraUpdate.newLatLng(cameraPosition));
            _isCameraAnimating = false;
          }
        });
      }
    } catch (e) {
      // ignore errors getting current position
    }
  }

  Future<void> _findNearestHospital(String disease) async {
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location or wait for current location',
            ),
          ),
        );
      }
      return;
    }

    // map disease keywords to doctor types (simple mapping)
    final Map<String, List<String>> diseaseToDoctor = {
      'heart': ['Cardiologist', 'Emergency Medicine'],
      'chest': ['Cardiologist', 'Emergency Medicine'],
      'skin': ['Dermatologist'],
      'bone': ['Orthopedic'],
      'child': ['Pediatrician'],
      'brain': ['Neurologist'],
      'surgery': ['Surgeon', 'Emergency Medicine'],
      'mental': ['Psychiatrist'],
      'tooth': ['Dentist'],
      'emergency': ['Emergency Medicine'],
    };

    final queryTypes = <String>{};
    final lower = disease.toLowerCase();
    diseaseToDoctor.forEach((k, v) {
      if (lower.contains(k)) queryTypes.addAll(v);
    });
    // also use disease text as a fallback to match doctorType directly
    if (queryTypes.isEmpty) queryTypes.add(disease);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('hospital')
          .get();
      double? bestDist;
      DocumentSnapshot? bestDoc;

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final docType = (data['doctorType'] ?? '').toString();
        bool matches = false;
        for (final t in queryTypes) {
          if (docType.toLowerCase().contains(t.toLowerCase())) {
            matches = true;
            break;
          }
        }
        if (!matches) continue;

        final loc = (data['location'] ?? '').toString();
        final parts = loc.split(',');
        if (parts.length < 2) continue;
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat == null || lng == null) continue;

        final dist = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );

        if (bestDist == null || dist < bestDist) {
          bestDist = dist;
          bestDoc = doc;
        }
      }

      if (bestDoc != null && bestDist != null) {
        // place marker and move camera
        final ddata = bestDoc.data() as Map<String, dynamic>;
        final loc = (ddata['location'] ?? '').toString();
        final parts = loc.split(',');
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        final marker = Marker(
          markerId: MarkerId('hospital_${bestDoc.id}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: ddata['name'] ?? 'Hospital',
            snippet:
                '${ddata['doctorType'] ?? ''} - ${(bestDist / 1000).toStringAsFixed(2)} km',
          ),
        );

        if (mounted) {
          setState(() {
            _additionalMarkers = {marker};
            _nearestHospitalName = ddata['name'] as String? ?? 'Unknown';
            _nearestHospitalLocation = loc;
            _nearestHospitalDistance = bestDist! / 1000; // convert to km
          });
        }

        if (_mapController.isCompleted) {
          final controller = await _mapController.future;
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No matching hospital found nearby')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching hospitals: $e')),
        );
      }
    }
  }

  void _logout() async {
    try {
      await AuthService().signOut();
      // The AuthenticationWrapper will automatically handle navigation to Welcome
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  void _retryMap() {
    setState(() {
      _mapCreationFailed = false;
      _mapCreated = false;
      _mapController =
          Completer(); // recreate completer so map can be reinitialized
      _googleMapKey = UniqueKey();
    });
    // re-check permissions and position
    _checkLocationPermissionAndFetch();
  }

  Set<Marker> _buildMarkers() {
    // Ensure coordinates are properly formatted as doubles to prevent precision loss
    final defaultPosition = const LatLng(24.7136, 46.6753);
    final position = _currentPosition ?? defaultPosition;

    // Explicitly ensure double precision for coordinates
    final markerPosition = LatLng(
      position.latitude.toDouble(),
      position.longitude.toDouble(),
    );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('default_marker'),
        position: markerPosition,
        infoWindow: InfoWindow(
          title: _currentPosition != null
              ? 'Your Location'
              : 'Default Location',
        ),
      ),
    };

    markers.addAll(_additionalMarkers);
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final List<Widget> pages = [
      _buildHomePage(size),
      _buildMapPage(size),
      _buildProfilePage(size),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Golden Hour',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout, size: 30, color: Colors.black),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white10, Colors.blue.shade200],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rawPadding = constraints.maxWidth * 0.08;
              final horizontalPadding = rawPadding.clamp(16.0, 32.0);

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: size.height * 0.03,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                        size.height * 0.06, // قريب من قيمة الـ padding
                  ),
                  child: IndexedStack(index: _currentIndex, children: pages),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomePage(Size size) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'You are not logged in.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    }

    final profileDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: profileDoc.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load profile'));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] as String? ?? 'Unknown';
        final lastname = data?['lastname'] as String? ?? 'Unknown';
        final phone = data?['phone'] as String? ?? 'Not set';
        final city = data?['City'] as String? ?? 'Not set';
        final id = data?['id'] as String? ?? 'Not set';
        final Street = data?['Street'] as String? ?? 'Not set';
        final email = data?['email'] as String? ?? 'Not set';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $name $lastname',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width > 400 ? 28 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Phone: $phone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width > 400 ? 28 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'id: $id',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width > 400 ? 28 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'City: $city',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width > 400 ? 28 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Street: $Street',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width > 400 ? 28 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'email: $email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width > 400 ? 28 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapPage(Size size) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Find Nearest Hospital",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: CustomTextformfields(
                  hintText: "Enter Type Of Patient Disease",
                  mycontroller: _MapController,
                  hintMaxLines: 2,
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    final disease = _MapController.text.trim();
                    if (disease.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter disease/type'),
                        ),
                      );
                      return;
                    }
                    await _findNearestHospital(disease);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      Colors.lightBlueAccent,
                    ),
                  ),
                  child: Text("Submit", style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
          SizedBox(
            height: size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: RepaintBoundary(
                  child: Builder(
                    builder: (context) {
                      // schedule a quick check to detect map creation failure
                      if (!_mapCreationCheckScheduled) {
                        _mapCreationCheckScheduled = true;
                        Future.delayed(const Duration(seconds: 4), () {
                          if (!_mapCreated && mounted) {
                            setState(() {
                              _mapCreationFailed = true;
                            });
                          }
                        });
                      }

                      // Show error message if map creation failed
                      if (_mapCreationFailed) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'فشل تحميل الخريطة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'تأكد من:\n'
                                    '1. وجود Google Maps API Key في AndroidManifest.xml\n'
                                    '2. تفعيل Maps SDK في Google Cloud Console\n'
                                    '3. استخدام Google APIs System Image في المحاكي',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return GoogleMap(
                        key: _googleMapKey,
                        onMapCreated: (controller) {
                          try {
                            if (!_mapController.isCompleted) {
                              _mapController.complete(controller);
                            }
                            if (mounted) {
                              setState(() {
                                _mapCreated = true;
                                _mapCreationFailed = false;
                              });
                            }
                            // if we already have current position, move camera
                            if (_currentPosition != null &&
                                !_isCameraAnimating) {
                              _isCameraAnimating = true;
                              // Use a delayed camera update to prevent buffer overflow
                              // Ensure double precision for camera position
                              final cameraPosition = LatLng(
                                _currentPosition!.latitude.toDouble(),
                                _currentPosition!.longitude.toDouble(),
                              );
                              // Cancel any pending animation
                              _cameraAnimationTimer?.cancel();
                              // Debounce camera animation to prevent buffer overflow
                              _cameraAnimationTimer = Timer(
                                const Duration(milliseconds: 500),
                                () {
                                  if (mounted && _mapController.isCompleted) {
                                    controller.animateCamera(
                                      CameraUpdate.newLatLng(cameraPosition),
                                    );
                                    _isCameraAnimating = false;
                                  }
                                },
                              );
                            }
                          } catch (e) {
                            // Log error and show failure state
                            debugPrint('Google Maps Error: $e');
                            if (mounted) {
                              setState(() {
                                _mapCreated = false;
                                _mapCreationFailed = true;
                              });
                            }
                          }
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            (_currentPosition?.latitude ?? 24.7136).toDouble(),
                            (_currentPosition?.longitude ?? 46.6753).toDouble(),
                          ),
                          zoom: 12.0,
                        ),
                        mapType: MapType.normal,
                        myLocationEnabled: _locationPermissionGranted,
                        myLocationButtonEnabled: _locationPermissionGranted,
                        zoomControlsEnabled: true,
                        // Reduce buffer usage by limiting concurrent operations
                        liteModeEnabled: false,
                        markers: _buildMarkers(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_mapCreationFailed)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                children: [
                  const Text(
                    'Map failed to initialize. Try retrying or check emulator/device settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _retryMap,
                        child: const Text('Retry'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await Geolocator.openAppSettings();
                        },
                        child: const Text('Open App Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_nearestHospitalName != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearest Hospital',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.local_hospital, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _nearestHospitalName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _nearestHospitalLocation ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.directions, color: Colors.green.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'Distance: ${_nearestHospitalDistance?.toStringAsFixed(2) ?? '0'} km',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: size.height * 0.05),
          if (_nearestHospitalLocation != null &&
              _nearestHospitalLocation!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Hospital Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Text(
                      _nearestHospitalLocation ?? 'No location',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_nearestHospitalLocation == null ||
              _nearestHospitalLocation!.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    'Search for a hospital to see location',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(Size size) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'You are not logged in.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    }

    final profileDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: profileDoc.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_profileLoadedOnce) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load profile'));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        if (!_profileLoadedOnce && data != null) {
          _nameController.text = data['name'] as String? ?? '';
          _lastnameController.text = data['lastname'] as String? ?? '';
          _phoneController.text = data['phone'] as String? ?? '';
          _StreetController.text = data['Street'] as String? ?? '';
          _idController.text = data['id'] as String? ?? '';
          _CityController.text = data['City'] as String? ?? '';
          _emailController.text = data['email'] as String? ?? '';
          _AgeController.text = data['Age'] as String? ?? '';
          _profileLoadedOnce = true;
        }
        return Form(
          key: _profileFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width > 400 ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Column(
                children: [
                  SizedBox(height: size.height * 0.04),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextformfields(
                          hintText: 'First name',
                          mycontroller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextformfields(
                          hintText: 'Last name',
                          mycontroller: _lastnameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextformfields(
                    hintText: 'phone number',
                    mycontroller: _phoneController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextformfields(
                          hintText: 'id',
                          mycontroller: _idController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your id';
                            }
                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: CustomTextformfields(
                          hintText: 'City',
                          mycontroller: _CityController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: CustomTextformfields(
                          hintText: 'Street',
                          mycontroller: _StreetController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  CustomTextformfields(
                    hintText: 'Email',
                    mycontroller: _emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  CustomTextformfields(
                    hintText: 'Age',
                    mycontroller: _AgeController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.05),
                  SizedBox(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Colors.lightBlueAccent,
                        ),
                      ),
                      onPressed: _isSavingProfile
                          ? null
                          : () async {
                              if (!_profileFormKey.currentState!.validate()) {
                                return;
                              }
                              setState(() {
                                _isSavingProfile = true;
                              });
                              try {
                                await profileDoc.set({
                                  'name': _nameController.text.trim(),
                                  'lastname': _lastnameController.text.trim(),
                                  'phone': _phoneController.text.trim(),
                                  'id': _idController.text.trim(),
                                  'City': _CityController.text.trim(),
                                  'Street': _StreetController.text.trim(),
                                  'email': _emailController.text.trim(),
                                  'Age': _AgeController.text.trim(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile saved successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to save profile: $e',
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSavingProfile = false;
                                  });
                                }
                              }
                            },
                      child: _isSavingProfile
                          ? const SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
