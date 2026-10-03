import 'package:flutter/foundation.dart';

import '../catalog/catalog_store.dart';
import '../catalog/data/catalog_repository.dart';
import '../manual/manual_receipt.dart';
import '../merchant/merchant_store.dart';
import '../models/receipt_record.dart';
import '../scan/native_adapter.dart';
import '../scan/scan_outcome.dart';
import '../scan/scan_session.dart';
import '../settings/onboarding_store.dart';
import '../settings/settings_store.dart';
import '../storage/receipt_repository.dart';
import '../util/collections.dart';
import 'tab_request.dart';

/// App-wide state: receipts plus the catalog and merchant stores derived from them.
class AppState extends ChangeNotifier {
  AppState({
    required ReceiptRepository repository,
    required NativeAdapter adapter,
    SettingsStore? settings,
    ScanSession? session,
    CatalogStore? catalog,
    MerchantStore? merchants,
    OnboardingStore? onboarding,
  })  : _repository = repository,
        _adapter = adapter,
        settings = settings ?? SettingsStore(),
        _session = session ?? ScanSession(repository: repository, adapter: adapter),
        catalog = catalog ?? CatalogStore(repository: CatalogRepository(database: repository.database)),
        merchants = merchants ?? MerchantStore(repository: repository.merchants),
        _onboarding = onboarding ?? OnboardingStore() {
    this.catalog.addListener(notifyListeners);
    this.merchants.addListener(notifyListeners);
  }

  final ReceiptRepository _repository;
  final NativeAdapter _adapter;
  final SettingsStore settings;
  final ScanSession _session;
  final CatalogStore catalog;
  final MerchantStore merchants;
  final OnboardingStore _onboarding;

  /// Which catalog tab to show next time the catalog is opened.
  final catalogTab = TabRequest();

  List<ReceiptRecord> receipts = const [];
  List<SettingField> settingFields = const [];
  bool ready = false;
  String? loadError;

  bool get onboardingDone => _onboarding.done;

  /// Catalog syncs run one at a time so a startup sync cannot interleave with a post-scan one.
  Future<void> _syncQueue = Future.value();

  /// Startup in two phases. [ready] flips as soon as stored data is on screen, so the
  /// scanner is usable at once; loading the native library for the settings schema
  /// and re-syncing the catalog finish in the background. Completes after both.
  Future<void> load() async {
    final watch = Stopwatch()..start();
    try {
      await Future.wait([_onboarding.load(), settings.load()]);
      _adapter.configure(settings.snapshot());
      receipts = await _repository.listAll();
      await merchants.reload();
      await catalog.restore(receipts, merchants: merchants.all);
      loadError = null;
    } catch (error) {
      loadError = '$error';
    }
    ready = true;
    notifyListeners();
    debugPrint('[checkscan] startup ready in ${watch.elapsedMilliseconds} ms');
    if (loadError != null) return;

    await Future.wait([_loadSettingFields(), _syncCatalog()]);
    debugPrint('[checkscan] startup synced in ${watch.elapsedMilliseconds} ms');
  }

  /// The stored catalog is already shown; this only adds names and purchases it missed.
  Future<void> _syncCatalog() async {
    try {
      await _sync(() => catalog.ingest(receipts, merchants: merchants.all));
    } catch (error) {
      debugPrint('[checkscan] catalog sync failed: $error');
    }
  }

  Future<void> _loadSettingFields() async {
    try {
      settingFields = await _adapter.settings();
      notifyListeners();
    } catch (error) {
      debugPrint('[checkscan] settings schema failed: $error');
    }
  }

  Future<void> _sync(Future<void> Function() task) {
    final run = _syncQueue.then((_) => task());
    _syncQueue = run.catchError((_) {});
    return run;
  }

  @override
  void dispose() {
    catalog.removeListener(notifyListeners);
    merchants.removeListener(notifyListeners);
    catalogTab.dispose();
    super.dispose();
  }

  // Settings and onboarding.

  Future<void> setSetting(String key, String value) async {
    await settings.set(key, value);
    _adapter.configure(settings.snapshot());
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _onboarding.complete();
    notifyListeners();
  }

  // Receipts.

  /// Re-reads receipts and merchants and re-derives the catalog from them.
  Future<void> reload() {
    return _sync(() async {
      receipts = await _repository.listAll();
      await merchants.reload();
      await catalog.ingest(receipts, merchants: merchants.all);
    });
  }

  ReceiptRecord? byId(String id) => receipts.firstWhereOrNull((receipt) => receipt.id == id);

  Future<void> deleteReceipt(String id) async {
    await _repository.deleteById(id);
    receipts = receipts.where((receipt) => receipt.id != id).toList();
    await catalog.syncPurchases(receipts, merchants: merchants.all);
    notifyListeners();
  }

  /// The policy decides whether a merchant's items enter the catalog, so the catalog is rebuilt.
  Future<void> setMerchantPolicy(String merchantId, String policy) async {
    await merchants.update(merchantId, policy: policy);
    await reload();
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

  /// Saves a hand-entered receipt and pins each line to the product it was picked for.
  Future<ReceiptRecord> saveManualReceipt({
    required String merchantName,
    required DateTime issuedAt,
    required List<ManualLine> lines,
    String currency = 'RUB',
  }) async {
    final receipt = manualReceiptOf(merchantName: merchantName, issuedAt: issuedAt, lines: lines, currency: currency);
    final saved = await _repository.upsertParsed(
      qrHash: manualStorageKey(receipt),
      adapterId: manualProviderId,
      rawQr: '',
      receipt: receipt,
      lastStatus: statusOk,
    );
    await reload();
    final wanted = {for (final line in lines) line.description: line.productId};
    for (final MapEntry(key: description, value: productId) in wanted.entries) {
      final hit = catalog.resolver.resolve(description);
      if (hit == null || hit.position.productId == productId) continue;
      await catalog.assignPosition(hit.position.id, productId);
    }
    return byId(saved.id) ?? saved;
  }
}
