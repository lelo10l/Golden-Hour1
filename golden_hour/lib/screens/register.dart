import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golden_hour/components/custom_textformfields.dart';
import 'package:golden_hour/components/custum_buttons.dart';
import 'package:golden_hour/screens/homepage.dart';
import 'package:golden_hour/screens/log_In_p.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
                          SizedBox(height: size.height * 0.14),
                          CustomTextformfields(
                            obscureText: false,
                            hintText: "name",
                            mycontroller: name,
                            suffixIcon: const Icon(Icons.person),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
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
                              } else if (!RegExp(
                                r'^\d+$',
                              ).hasMatch(value.trim())) {
                                return 'Phone number must contain only digits';
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
                          SizedBox(height: size.height * 0.2),
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
                                      builder: (context) => const homepage(),
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
                          Align(
                            alignment: Alignment.center,
                            child: Text("ALREADY HAVE AN ACCOUNT?"),
                          ),
                          SizedBox(height: size.height * 0.015),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const loginparamedic(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.lightBlueAccent,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                Colors.lightBlueAccent,
                              ),
                            ),
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(color: Colors.black),
                            ),
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
