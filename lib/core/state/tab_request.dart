import 'package:flutter/foundation.dart';

/// One-shot "switch to tab N" request for a page that may already be on screen.
class TabRequest extends ChangeNotifier {
  int? _pending;

  void request(int index) {
    _pending = index;
    notifyListeners();
  }

  /// Returns the pending index once, then clears it.
  int? take() {
    final index = _pending;
    _pending = null;
    return index;
  }
}
