import 'package:flutter/material.dart';

import '../../core/scan/native_adapter.dart';
import '../../core/state/app_state.dart';

/// Obscured provider token; saved on submit, on tap outside and on dispose.
class SecretField extends StatefulWidget {
  const SecretField({super.key, required this.state, required this.field, required this.title});

  final AppState state;
  final SettingField field;
  final String title;

  @override
  State<SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<SecretField> {
  late final _controller = TextEditingController(text: widget.state.settings.values[widget.field.key] ?? '');
  bool _obscure = true;

  @override
  void dispose() {
    _save();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() => widget.state.setSetting(widget.field.key, _controller.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controller,
        obscureText: _obscure,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: widget.title,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        onEditingComplete: _save,
        onTapOutside: (_) => _save(),
      ),
    );
  }
}
