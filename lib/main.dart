import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/scan/native_adapter.dart';
import 'core/settings/settings_store.dart';
import 'core/state/app_state.dart';
import 'core/storage/receipt_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final repository = ReceiptRepository();
  final settings = SettingsStore();
  final adapter = IsolatedNativeAdapter();
  final state = AppState(repository: repository, adapter: adapter, settings: settings);
  runApp(CheckScanApp(state: state));
  await state.load();
}
