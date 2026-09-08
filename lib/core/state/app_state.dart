import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../catalog/catalog_repository.dart';
import '../catalog/catalog_store.dart';
import '../merchant/merchant.dart';
import '../merchant/merchant_repository.dart';
import '../models/receipt_record.dart';
import '../scan/native_adapter.dart';
import '../scan/scan_outcome.dart';
import '../scan/scan_session.dart';
import '../settings/settings_store.dart';
import '../storage/receipt_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    required ReceiptRepository repository,
    required NativeAdapter adapter,
    SettingsStore? settings,
    ScanSession? session,
    CatalogStore? catalog,
    MerchantRepository? merchants,
  })  : _repository = repository,
        _adapter = adapter,
        settings = settings ?? SettingsStore(),
        _session = session ?? ScanSession(repository: repository, adapter: adapter),
        catalog = catalog ?? CatalogStore(repository: CatalogRepository(database: repository.database)),
        merchants = merchants ?? MerchantRepository(database: repository.database) {
    this.catalog.addListener(notifyListeners);
  }

  final ReceiptRepository _repository;
  final NativeAdapter _adapter;
  final SettingsStore settings;
  final ScanSession _session;
  final CatalogStore catalog;
  final MerchantRepository merchants;

  List<Merchant> merchantList = const [];

  static const _onboardingKey = 'onboarding_done';

  bool onboardingDone = false;
  List<ReceiptRecord> receipts = const [];
  List<SettingField> settingFields = const [];
  bool ready = false;
  String? loadError;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingDone = prefs.getBool(_onboardingKey) ?? false;
      await settings.load();
      settingFields = await _adapter.settings();
      _adapter.configure(settings.snapshot());
      receipts = await _repository.listAll();
      merchantList = await merchants.listAll();
      await catalog.ingest(receipts, merchants: merchantList);
      loadError = null;
    } catch (error) {
      loadError = '$error';
    }
    ready = true;
    notifyListeners();
  }

  Future<void> setSetting(String key, String value) async {
    await settings.set(key, value);
    _adapter.configure(settings.snapshot());
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    onboardingDone = true;
    notifyListeners();
  }

  Future<void> reload() async {
    receipts = await _repository.listAll();
    merchantList = await merchants.listAll();
    await catalog.ingest(receipts, merchants: merchantList);
  }

  Merchant? merchantById(String? id) {
    if (id == null) return null;
    for (final merchant in merchantList) {
      if (merchant.id == id) return merchant;
    }
    return null;
  }

  Future<void> reloadMerchants() async {
    merchantList = await merchants.listAll();
    notifyListeners();
  }

  @override
  void dispose() {
    catalog.removeListener(notifyListeners);
    super.dispose();
  }

  ReceiptRecord? byId(String id) {
    for (final receipt in receipts) {
      if (receipt.id == id) return receipt;
    }
    return null;
  }

  Future<void> deleteReceipt(String id) async {
    await _repository.deleteById(id);
    receipts = receipts.where((receipt) => receipt.id != id).toList();
    await catalog.syncPurchases(receipts, merchants: merchantList);
    notifyListeners();
  }

  Future<ScanOutcome> processScan(String rawQr, {void Function()? onMatched}) async {
    final result = await _session.process(rawQr, onMatched: onMatched);
    if (result.record != null) await reload();
    return result;
  }

  Future<ReceiptRecord?> refreshReceipt(ReceiptRecord record) async {
    final updated = await _session.refresh(record);
    await reload();
    return updated;
  }

  Future<int> refreshPending() async {
    final done = await _session.refreshPending();
    await reload();
    return done;
  }
}
