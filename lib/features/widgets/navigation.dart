import 'package:flutter/material.dart';

Future<T?> pushPage<T>(BuildContext context, Widget page, {String? name, bool fullscreenDialog = false}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      settings: RouteSettings(name: name),
      fullscreenDialog: fullscreenDialog,
      builder: (_) => page,
    ),
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
