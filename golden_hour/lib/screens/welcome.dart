import 'package:flutter/material.dart';
import 'package:golden_hour/components/custum_buttons.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _LogInState();
}

class _LogInState extends State<Welcome> {
  bool _value = false;
  bool _value1 = false;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
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
                  vertical: size.height * 0.04,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.04),
                        const Text(
                          "Welcome To",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: const Text(
                            "Golden Hour Application",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        FractionallySizedBox(
                          widthFactor: size.width >= 600 ? 0.6 : 0.9,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  height: 150,
                                  child: Center(child: Text('error')),
                                ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.04),
                        Card(
                          color: Colors.white.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                _buildToggleRow(
                                  label: "Paramedic",
                                  value: _value,
                                  onChanged: (v) => setState(() {
                                    _value = v;
                                    if (v) _value1 = false;
                                  }),
                                ),
                                const Divider(),
                                _buildToggleRow(
                                  label: "Hospital",
                                  value: _value1,
                                  onChanged: (v) => setState(() {
                                    _value1 = v;
                                    if (v) _value = false;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.15),
                        CustumButtons().buildButton(
                          text: "LOGIN",
                          color: Colors.lightBlueAccent,
                          onPressed: () {
                            if (_value == true) {
                              Navigator.pushNamed(context, 'log_in');
                            } else if (_value1 == true) {
                              Navigator.pushNamed(context, 'hospital_login');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select Paramedic or Hospital',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                        CustumButtons().buildButton(
                          text: "REGISTER",
                          color: Colors.lightBlueAccent,
                          onPressed: () {
                            if (_value == true) {
                              Navigator.pushNamed(context, 'register');
                            } else if (_value1 == true) {
                              Navigator.pushNamed(context, 'hospital_register');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select Paramedic or Hospital',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(height: size.height * 0.02),
                      ],
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

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Switch.adaptive(
          activeColor: Colors.blueAccent,
          inactiveThumbColor: Colors.black,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
