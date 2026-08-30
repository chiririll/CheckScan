import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

typedef _CStrFn = Pointer<Utf8> Function();
typedef _CStr2Fn = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _CFreeFn = Void Function(Pointer<Utf8>);

class NativeProvidersLib {
  NativeProvidersLib._(DynamicLibrary lib)
      : _match = lib.lookupFunction<_CStr2Fn, _CStr2Fn>('checkscan_match'),
        _resolve = lib.lookupFunction<_CStr2Fn, _CStr2Fn>('checkscan_resolve'),
        _providers = lib.lookupFunction<_CStrFn, _CStrFn>('checkscan_providers'),
        _free = lib.lookupFunction<_CFreeFn, void Function(Pointer<Utf8>)>('checkscan_free');
  final _CStr2Fn _match;
  final _CStr2Fn _resolve;
  final _CStrFn _providers;
  final void Function(Pointer<Utf8>) _free;

  static NativeProvidersLib open() {
    if (!Platform.isAndroid) {
      throw UnsupportedError('CheckScanProviders native library is Android-only in this build');
    }
    return NativeProvidersLib._(DynamicLibrary.open('libcheckscan.so'));
  }

  String match(String rawQr, {String hint = ''}) => _call2(_match, rawQr, hint);

  String resolve(String rawQr, {String hint = ''}) => _call2(_resolve, rawQr, hint);

  String providers() {
    final ptr = _providers();
    if (ptr == nullptr) {
      throw StateError('checkscan_providers returned null');
    }
    try {
      return ptr.toDartString();
    } finally {
      _free(ptr);
    }
  }

  String _call2(_CStr2Fn fn, String rawQr, String hint) {
    final rawPtr = rawQr.toNativeUtf8();
    final hintPtr = hint.toNativeUtf8();
    try {
      final result = fn(rawPtr, hintPtr);
      if (result == nullptr) {
        throw StateError('native call returned null');
      }
      try {
        return result.toDartString();
      } finally {
        _free(result);
      }
    } finally {
      malloc.free(rawPtr);
      malloc.free(hintPtr);
    }
  }
}

class IsolatedNativeProviders {
  IsolatedNativeProviders();

  Future<String> match(String rawQr, {String hint = ''}) {
    return Isolate.run(() => NativeProvidersLib.open().match(rawQr, hint: hint));
  }

  Future<String> resolve(String rawQr, {String hint = ''}) {
    return Isolate.run(() => NativeProvidersLib.open().resolve(rawQr, hint: hint));
  }

  Future<String> providers() {
    return Isolate.run(() => NativeProvidersLib.open().providers());
  }
}
