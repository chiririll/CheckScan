# CheckScan

Flutter Android app: scan a receipt QR, resolve it through an embedded Go library, store locally, show history.

Setup, run, native build: [README.md](README.md).
App deps and SDK bounds: [pubspec.yaml](pubspec.yaml).
Lint: [analysis_options.yaml](analysis_options.yaml).

## Map

| Path | What |
| --- | --- |
| [lib/](lib/) | Flutter UI and app logic |
| [packages/eq_models](packages/eq_models/) | Shared receipt JSON (`EqReceipt`) |
| [packages/providers_native](packages/providers_native/) | FFI to `libcheckscan.so` |
| [services/providers](services/providers/) | Go providers (git submodule). Rules: [AGENTS.md](services/providers/AGENTS.md) |
| [scripts/build_android_native.ps1](scripts/build_android_native.ps1) | Builds `.so` into the FFI plugin |
| [test/](test/) | Dart tests (`flutter test`) |

`packages/adapter_*` is leftover Dart code. Live resolve is Go, not those packages.

## Flow

1. Wire-up: [lib/main.dart](lib/main.dart)
2. Scan pipeline (match → dedupe → resolve → persist): [lib/core/scan/scan_session.dart](lib/core/scan/scan_session.dart)
3. Native JSON bridge: [lib/core/scan/providers_backend.dart](lib/core/scan/providers_backend.dart)
4. FFI: [packages/providers_native/lib/src/native_lib.dart](packages/providers_native/lib/src/native_lib.dart)
5. Providers: [services/providers/AGENTS.md](services/providers/AGENTS.md)
6. Local DB: [lib/core/storage/receipt_repository.dart](lib/core/storage/receipt_repository.dart), [lib/core/models/receipt_record.dart](lib/core/models/receipt_record.dart)
7. UI shell: [lib/app.dart](lib/app.dart), [lib/features/shell/app_shell.dart](lib/features/shell/app_shell.dart)

QR formats and provider IDs live in the Go submodule. Do not add Dart-side adapters.

## Conventions

- Android first. UI is Russian only (`ru`). Strings: [lib/l10n/app_ru.arb](lib/l10n/app_ru.arb); gen config: [l10n.yaml](l10n.yaml).
- `services/providers` is a separate repo (submodule). Change it there ([AGENTS.md](services/providers/AGENTS.md)); rebuild the `.so` after.
- New code needs tests. Dart: [test/](test/) (`flutter test`; scan path uses [fake_providers_backend.dart](test/scan/fake_providers_backend.dart)).
- Keep files small. Split growing files into modules; split a module when it starts doing more than one job.
