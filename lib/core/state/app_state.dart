import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receipt_model/receipt_model.dart';

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

/// App-wide state: receipts, merchants and provider settings.
class AppState extends ChangeNotifier {
  AppState({
    required ReceiptRepository repository,
    required NativeAdapter adapter,
    SettingsStore? settings,
    ScanSession? session,
    MerchantStore? merchants,
    OnboardingStore? onboarding,
  })  : _repository = repository,
        _adapter = adapter,
        settings = settings ?? SettingsStore(),
        _session = session ?? ScanSession(repository: repository, adapter: adapter),
        merchants = merchants ?? MerchantStore(repository: repository.merchants),
        _onboarding = onboarding ?? OnboardingStore() {
    this.merchants.addListener(notifyListeners);
  }

  final ReceiptRepository _repository;
  final NativeAdapter _adapter;
  final SettingsStore settings;
  final ScanSession _session;
  final MerchantStore merchants;
  final OnboardingStore _onboarding;

  List<ReceiptRecord> receipts = const [];
  List<SettingField> settingFields = const [];
  bool ready = false;
  String? loadError;

  bool get onboardingDone => _onboarding.done;

  /// Startup in two phases. [ready] flips as soon as stored data is on screen, so the
  /// scanner is usable at once; loading the native library for the settings schema
  /// finishes in the background. Completes after both.
  Future<void> load() async {
    final watch = Stopwatch()..start();
    try {
      await Future.wait([_onboarding.load(), settings.load()]);
      _adapter.configure(settings.snapshot());
      await reload();
      loadError = null;
    } catch (error) {
      loadError = '$error';
    }
    ready = true;
    notifyListeners();
    debugPrint('[checkscan] startup ready in ${watch.elapsedMilliseconds} ms');
    if (loadError != null) return;

    await _loadSettingFields();
    debugPrint('[checkscan] startup synced in ${watch.elapsedMilliseconds} ms');
  }

  Future<void> _loadSettingFields() async {
    try {
      settingFields = await _adapter.settings();
      notifyListeners();
    } catch (error) {
      debugPrint('[checkscan] settings schema failed: $error');
    }
  }

  @override
  void dispose() {
    merchants.removeListener(notifyListeners);
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

  /// Re-reads receipts and merchants.
  Future<void> reload() async {
    receipts = await _repository.listAll();
    await merchants.reload();
    notifyListeners();
  }

  ReceiptRecord? byId(String id) => receipts.firstWhereOrNull((receipt) => receipt.id == id);

  Future<void> deleteReceipt(String id) async {
    await _repository.deleteById(id);
    receipts = receipts.where((receipt) => receipt.id != id).toList();
    notifyListeners();
  }

  /// Currency of the latest receipt: the best guess for a new manual one.
  String get defaultCurrency => receipts.isEmpty ? 'RUB' : receipts.first.currency;

  /// Stores a hand-typed receipt, or the edited version of [existing]. [label] is the provider chip text.
  Future<ReceiptRecord> saveManual(Receipt receipt, {required String label, ReceiptRecord? existing}) async {
    final record = await _repository.upsertParsed(
      id: existing?.id,
      qrHash: existing?.qrHash ?? '$manualAdapterId:${receipt.id}',
      adapterId: manualAdapterId,
      rawQr: '',
      receipt: withProviderLabel(receipt, label),
      lastStatus: statusOk,
      scannedAt: existing?.scannedAt,
      keepMerchant: false,
    );
    await merchants.reload();
    _put(record);
    return record;
  }

  /// Saves the scan offline and returns at once; the network fetch runs in the
  /// background ([isFetching] / [fetchDone]).
  Future<ScanOutcome> processScan(String rawQr, {void Function()? onMatched}) async {
    final result = await _session.process(rawQr, onMatched: onMatched);
    final record = result.record;
    if (record != null) {
      _put(record);
      if (record.canRetry) unawaited(_fetchInBackground(record));
    }
    return result;
  }

  final _fetches = <String, Future<void>>{};

  /// True while the provider is being asked for this receipt's full data.
  bool isFetching(String receiptId) => _fetches.containsKey(receiptId);

  /// Completes when the background fetch for [receiptId] (if any) is over.
  Future<void> fetchDone(String receiptId) => _fetches[receiptId] ?? Future.value();

  Future<void> _fetchInBackground(ReceiptRecord record) {
    final running = _fetches[record.id];
    if (running != null) return running;
    final fetch = _fetchAndReload(record).whenComplete(() {
      _fetches.remove(record.id);
      notifyListeners();
    });
    _fetches[record.id] = fetch;
    notifyListeners();
    return fetch;
  }

  Future<void> _fetchAndReload(ReceiptRecord record) async {
    try {
      if (await _session.fetchRemote(record) != null) await reload();
    } catch (error) {
      debugPrint('[checkscan] background fetch failed: $error');
    }
  }

  /// Shows a just-saved receipt before the next reload.
  void _put(ReceiptRecord record) {
    receipts = [record, for (final receipt in receipts) if (receipt.id != record.id) receipt]
      ..sort((a, b) => b.at.compareTo(a.at));
    notifyListeners();
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
