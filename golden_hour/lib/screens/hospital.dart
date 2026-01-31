import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:golden_hour/components/custom_textformfields.dart';

class Hospital extends StatefulWidget {
  const Hospital({super.key});

  @override
  State<Hospital> createState() => _HospitalState();
}

class _HospitalState extends State<Hospital> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doctorTypeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isGettingLocation = false;
  String? _selectedDoctorType;

  final List<String> _doctorTypes = [
    'General Practitioner',
    'Cardiologist',
    'Dermatologist',
    'Orthopedic',
    'Pediatrician',
    'Neurologist',
    'Surgeon',
    'Psychiatrist',
    'Dentist',
    'Emergency Medicine',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _doctorTypeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationController.text =
            '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _saveHospital() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not signed in. Please sign in to save data.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('hospital').add({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'doctorType': _selectedDoctorType ?? _doctorTypeController.text.trim(),
        'location': _locationController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hospital information saved successfully'),
          ),
        );
        _nameController.clear();
        _doctorTypeController.clear();
        _locationController.clear();
        setState(() {
          _selectedDoctorType = null;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        final message = e.code == 'permission-denied'
            ? 'Permission denied saving to Firestore. Check your Firestore security rules and authentication.'
            : 'Error saving hospital: ${e.message ?? e.code}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving hospital: $e')));
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final availableHeight =
        size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
        title: const Text('Add Hospital Information'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white10, Colors.blue.shade200],
          ),
        ),
        child: SizedBox(
          height: availableHeight,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(size.width * 0.05),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availableHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hospital Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size.width > 400 ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    // Hospital Name
                    CustomTextformfields(
                      hintText: 'Hospital Name',
                      mycontroller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter hospital name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: size.height * 0.02),
                    // Doctor Type (Dropdown)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Select Doctor Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      initialValue: _selectedDoctorType,
                      items: _doctorTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDoctorType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a doctor type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: size.height * 0.02),
                    // Or add custom doctor type
                    if (_selectedDoctorType == null)
                      Column(
                        children: [
                          CustomTextformfields(
                            hintText: 'Or enter custom doctor type',
                            mycontroller: _doctorTypeController,
                          ),
                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    // Location
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextformfields(
                            hintText: 'Location (Latitude, Longitude)',
                            mycontroller: _locationController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter location';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: size.width * 0.02),
                        ElevatedButton.icon(
                          onPressed: _isGettingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: _isGettingLocation
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.location_on),
                          label: const Text('Get'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.2),
                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveHospital,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Save Hospital',
                              style: TextStyle(
                                fontSize: size.width > 400 ? 18 : 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
