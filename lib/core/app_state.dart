import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/receipt_record.dart';
import 'scan/scan_session.dart';
import 'storage/receipt_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.repository,
    required this.session,
  });

  final ReceiptRepository repository;
  final ScanSession session;

  static const _onboardingKey = 'onboarding_done';

  bool onboardingDone = false;
  List<ReceiptRecord> receipts = const [];
  bool ready = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingDone = prefs.getBool(_onboardingKey) ?? false;
    receipts = await repository.listAll();
    ready = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    onboardingDone = true;
    notifyListeners();
  }

  Future<void> reload() async {
    receipts = await repository.listAll();
    notifyListeners();
  }

  ReceiptRecord? byId(String id) {
    for (final receipt in receipts) {
      if (receipt.id == id) return receipt;
    }
    return null;
  }

  Future<void> deleteReceipt(String id) async {
    await repository.deleteById(id);
    receipts = receipts.where((receipt) => receipt.id != id).toList();
    notifyListeners();
  }
}
