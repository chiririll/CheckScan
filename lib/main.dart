import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'core/scan/provider_secrets.dart';
import 'core/scan/providers_backend.dart';
import 'core/scan/scan_session.dart';
import 'core/storage/receipt_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final repository = ReceiptRepository();
  final secrets = ProviderSecrets();
  final backend = NativeProvidersBackend(config: () => secrets.values);
  final state = AppState(
    repository: repository,
    session: ScanSession(repository: repository, backend: backend),
    secrets: secrets,
  );
  await state.load();
  runApp(CheckScanApp(state: state));
}
