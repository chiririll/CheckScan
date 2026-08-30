import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'core/scan/providers_backend.dart';
import 'core/scan/scan_session.dart';
import 'core/storage/receipt_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final repository = ReceiptRepository();
  final state = AppState(
    repository: repository,
    session: ScanSession(repository: repository, backend: NativeProvidersBackend()),
  );
  await state.load();
  runApp(CheckScanApp(state: state));
}
