import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:golden_hour/screens/homepage.dart';
import 'package:golden_hour/screens/hospital_register.dart';
import 'package:golden_hour/screens/login_hospital.dart';
import 'package:golden_hour/screens/register.dart';
import 'package:golden_hour/screens/welcome.dart';
import 'package:golden_hour/screens/log_In_p.dart';
import 'package:golden_hour/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // initialize analytics to ensure native analytics lib is included
  // this prevents FCM warning about missing analytics library
  try {
    FirebaseAnalytics.instance;
  } catch (_) {}
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Golden Hour',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthenticationWrapper(),
      routes: {
        'welcome': (context) => const Welcome(),
        'log_in': (context) => const loginparamedic(),
        'register': (context) => const Register(),
        'hospital_login': (context) => const LoginHospital(),
        'hospital_register': (context) => const HospitalRegister(),
        'homepage': (context) => const homepage(),
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // While checking authentication status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user has a valid session/token
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in and has valid token
          return const homepage();
        }

        // User is not logged in or token is invalid, show welcome screen
        return const Welcome();
      },
    );
  }
}
