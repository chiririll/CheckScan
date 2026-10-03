import 'package:flutter/material.dart';

import '../../app/theme.dart';

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
    borderSide: BorderSide(color: AppColors.border),
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.muted,
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
