# CheckScan

Flutter Android app: scan a receipt QR, resolve it through an embedded Go library, store locally, show history.

Setup and run: [README.md](README.md).
App deps and SDK bounds: [pubspec.yaml](pubspec.yaml).
Lint: [analysis_options.yaml](analysis_options.yaml).

## Map

| Path | What |
| --- | --- |
| [lib/](lib/) | Flutter UI and app logic |
| [packages/eq_models](packages/eq_models/) | Shared receipt JSON (`EqReceipt`) |
| [test/](test/) | Dart tests (`flutter test`) |

Providers and FFI: [CheckScanProviders](https://github.com/chiririll/CheckScanProviders) (`providers_native` git dep, `ref` in [pubspec.yaml](pubspec.yaml)). Native `.so` comes from that repo's GitHub Release.

## Flow

1. Wire-up: [lib/main.dart](lib/main.dart)
2. Scan pipeline (match → dedupe → resolve → persist): [lib/core/scan/scan_session.dart](lib/core/scan/scan_session.dart)
3. Native adapter: [lib/core/scan/native_adapter.dart](lib/core/scan/native_adapter.dart)
4. FFI: CheckScanProviders `adapters/flutter/` plugin. Host attaches `checkscan_set_log` and prints `[checkscan]` lines.
5. Local DB: [lib/core/storage/receipt_repository.dart](lib/core/storage/receipt_repository.dart), [lib/core/models/receipt_record.dart](lib/core/models/receipt_record.dart)
6. UI shell: [lib/app.dart](lib/app.dart), [lib/features/shell/app_shell.dart](lib/features/shell/app_shell.dart)

QR formats and provider IDs live in CheckScanProviders. Do not add Dart-side adapters.

## Conventions

- Android first. UI is Russian only (`ru`). Strings: [lib/l10n/app_ru.arb](lib/l10n/app_ru.arb); gen config: [l10n.yaml](l10n.yaml).
- Provider changes go in CheckScanProviders. Bump the `providers_native` git `ref` here after a release.
- Settings schema comes from CheckScanProviders `checkscan_settings`. Persist locally and `configure` the native library. Do not hardcode API names or tokens.
- New code needs tests. Dart: [test/](test/) (`flutter test`; scan path uses [fake_providers_backend.dart](test/scan/fake_providers_backend.dart)).
- Keep files small. Split growing files into modules; split a module when it starts doing more than one job.
