// ignore_for_file: file_names, use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golden_hour/components/custom_textformfields.dart';
import 'package:golden_hour/components/custum_buttons.dart';

// ignore: camel_case_types
class loginparamedic extends StatefulWidget {
  const loginparamedic({super.key});

  @override
  State<loginparamedic> createState() => _loginparamedicState();
}

// ignore: camel_case_types
class _loginparamedicState extends State<loginparamedic> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isloading = false;
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
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
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: double.infinity,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Welcome Back!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomTextformfields(
                              obscureText: false,
                              hintText: "email",
                              mycontroller: emailController,
                              suffixIcon: const Icon(Icons.email),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                final email = value.trim();
                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );
                                if (!emailRegex.hasMatch(email)) {
                                  return "Invalid email format";
                                }
                                if (!email.toLowerCase().endsWith('.com')) {
                                  return 'Email must end with .com';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextformfields(
                              obscureText: true,
                              hintText: "password",
                              mycontroller: passwordController,
                              suffixIcon: const Icon(Icons.lock),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.trim().length < 8) {
                                  return 'Password must be at least 8 characters long';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            CustumButtons().buildButton(
                              text: "Log In",
                              color: Colors.lightBlueAccent,
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    isloading = true;
                                    // ignore: unused_local_variable
                                    final credential = await FirebaseAuth
                                        .instance
                                        .signInWithEmailAndPassword(
                                          email: emailController.text,
                                          password: passwordController.text,
                                        );
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('homepage');
                                  } on FirebaseAuthException catch (e) {
                                    isloading = false;
                                    if (e.code == 'user-not-found') {
                                      print('No user found for that email.');
                                    } else if (e.code == 'wrong-password') {
                                      print(
                                        'Wrong password provided for that user.',
                                      );
                                    }
                                  }
                                } else {
                                  print('not validate');
                                }
                              },
                            ),
                            TextButton(
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all<Color>(
                                  Colors.blue[600]!,
                                ),
                              ),
                              onPressed: () {},
                              child: const Text("ForgetPassword?"),
                            ),
                          ],
                        ),
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
