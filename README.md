# CheckScan

Flutter Android app: scan a receipt QR, resolve it via the embedded CheckScanProviders library, store the receipt locally, then show history and simple stats.

Providers live in the `services/providers` submodule (`CheckScanProviders`). The app talks to them through FFI (`libcheckscan.so`).

## Run

```
git submodule update --init --recursive
flutter pub get
flutter test
```

Build the native library (Go + Android NDK), then run:

```
./scripts/build_android_native.ps1
flutter run
```

Needs Go 1.22+ and an Android NDK (`ANDROID_NDK_HOME` or `ndk.dir` in `android/local.properties`).

Scan fetches items immediately when the provider API answers. If it returns 403/429/503 (or `Retry-After`), the native library pauses further calls to that host and keeps the local total. History → **Догрузить состав** retries receipts that still have no items.

Pass the proverkacheka token at native build time via `PROVERKACHEKA_TOKEN` or `proverkacheka.token` in `android/local.properties` (gitignored).

Android first. UI is Russian (`ru` only in v1).
