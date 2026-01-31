import 'package:flutter/material.dart';

class CustomTextformfields extends StatelessWidget {
  final String hintText;
  final TextEditingController mycontroller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? labeltext;
  final int? hintMaxLines;
  final TextAlign? textAlign;
  const CustomTextformfields({
    super.key,
    required this.hintText,
    required this.mycontroller,
    this.validator,
    this.suffixIcon,
    this.obscureText = false,
    this.labeltext,
    this.hintMaxLines,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextFormField(
        obscureText: obscureText,
        validator: validator,
        controller: mycontroller,
        textAlign: textAlign ?? TextAlign.start,
        decoration: InputDecoration(
          hintText: hintText,
          hintMaxLines: hintMaxLines,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
