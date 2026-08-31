# CheckScan

Flutter Android app: scan a receipt QR, resolve it via CheckScanProviders, store the receipt locally, then show history and simple stats.

Providers live in [CheckScanProviders](https://github.com/chiririll/CheckScanProviders). The app depends on that repo's Flutter FFI plugin (`providers_native` → `libcheckscan.so`).

## Run

```
flutter pub get
flutter test
flutter run
```

`flutter run` downloads `libcheckscan.so` from the CheckScanProviders GitHub Release that matches the plugin version (tag `vX.Y.Z` in [pubspec.yaml](pubspec.yaml)).

Scan fetches items immediately when the provider API answers. If it returns 403/429/503 (or `Retry-After`), the native library pauses further calls to that host and keeps the local total. History → **Догрузить состав** retries receipts that still have no items.

The prebuilt Release bakes in `PROVERKACHEKA_TOKEN` from the CheckScanProviders repo secret. Do not commit the token.

Android first. UI is Russian (`ru` only in v1).
