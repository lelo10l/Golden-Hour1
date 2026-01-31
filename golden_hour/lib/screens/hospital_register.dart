import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golden_hour/components/custom_textformfields.dart';
import 'package:golden_hour/components/custum_buttons.dart';
import 'package:golden_hour/screens/hospital.dart';

class HospitalRegister extends StatefulWidget {
  const HospitalRegister({super.key});

  @override
  State<HospitalRegister> createState() => _HospitalRegisterState();
}

class _HospitalRegisterState extends State<HospitalRegister> {
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController hospitalName = TextEditingController();
  final TextEditingController location = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    phone.dispose();
    email.dispose();
    password.dispose();
    hospitalName.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'create Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  child: SizedBox(
                    width: double.infinity,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * 0.04),
                          CustomTextformfields(
                            obscureText: false,
                            hintText: "Hospital name",
                            mycontroller: hospitalName,
                            suffixIcon: const Icon(Icons.local_hospital),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your hospital name';
                              }
                              return null;
                            },
                          ),
                          CustomTextformfields(
                            obscureText: false,
                            hintText: "phone",
                            mycontroller: phone,
                            suffixIcon: const Icon(Icons.phone),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          CustomTextformfields(
                            obscureText: false,
                            hintText: "email",
                            mycontroller: email,
                            suffixIcon: const Icon(Icons.email),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          CustomTextformfields(
                            obscureText: true,
                            hintText: "password",
                            mycontroller: password,
                            suffixIcon: const Icon(Icons.lock),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          CustomTextformfields(
                            obscureText: false,
                            hintText: "Pharmacy Address",
                            mycontroller: location,
                            suffixIcon: const Icon(Icons.location_on),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your pharmacy address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: size.height * 0.26),
                          CustumButtons().buildButton(
                            text: "Register",
                            color: Colors.lightBlueAccent,
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  // ignore: unused_local_variable
                                  final credential = await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(
                                        email: email.text,
                                        password: password.text,
                                      );
                                  Navigator.of(
                                    // ignore: use_build_context_synchronously
                                    context,
                                  ).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const Hospital(),
                                    ),
                                    (route) => false,
                                  );
                                } on FirebaseAuthException catch (e) {
                                  if (e.code == 'weak-password') {
                                    String message =
                                        'The password provided is too weak.';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  } else if (e.code == 'email-already-in-use') {
                                    String message =
                                        'The account already exists for that email.';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                } catch (e) {
                                  // ignore: avoid_print
                                  print(e);
                                }
                              }
                            },
                          ),
                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
