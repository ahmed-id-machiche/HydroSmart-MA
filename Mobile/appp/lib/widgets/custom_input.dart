import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;

  const CustomInput({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F8FF),
        prefixIcon: Icon(icon, color: Colors.redAccent, size: 20),
        suffixIcon: obscure
            ? const Icon(Icons.visibility_off_outlined, size: 20)
            : null,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}