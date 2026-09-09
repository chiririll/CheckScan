import 'package:flutter/material.dart';

import '../../theme.dart';

class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFFE4E4E4)),
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: const TextStyle(color: Color(0xFF1B1B1B)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: _border,
        enabledBorder: _border,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
