import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

typedef _CStrFn = Pointer<Utf8> Function();
typedef _CStr2Fn = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _CStr3Fn = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _CFreeFn = Void Function(Pointer<Utf8>);

class NativeProvidersLib {
  NativeProvidersLib._(DynamicLibrary lib)
      : _match = lib.lookupFunction<_CStr2Fn, _CStr2Fn>('checkscan_match'),
        _resolve = lib.lookupFunction<_CStr3Fn, _CStr3Fn>('checkscan_resolve'),
        _providers = lib.lookupFunction<_CStrFn, _CStrFn>('checkscan_providers'),
        _free = lib.lookupFunction<_CFreeFn, void Function(Pointer<Utf8>)>('checkscan_free');
  final _CStr2Fn _match;
  final _CStr3Fn _resolve;
  final _CStrFn _providers;
  final void Function(Pointer<Utf8>) _free;

  static NativeProvidersLib open() {
    if (!Platform.isAndroid) {
      throw UnsupportedError('CheckScanProviders native library is Android-only in this build');
    }
    return NativeProvidersLib._(DynamicLibrary.open('libcheckscan.so'));
  }

  String match(String rawQr, {String hint = ''}) => _call2(_match, rawQr, hint);

  String resolve(String rawQr, {String hint = '', bool remote = false, bool wait = false}) {
    final mode = wait ? 'wait' : (remote ? 'remote' : '');
    return _call3(_resolve, rawQr, hint, mode);
  }

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
      return _read(fn(rawPtr, hintPtr));
    } finally {
      malloc.free(rawPtr);
      malloc.free(hintPtr);
    }
  }

  String _call3(_CStr3Fn fn, String rawQr, String hint, String mode) {
    final rawPtr = rawQr.toNativeUtf8();
    final hintPtr = hint.toNativeUtf8();
    final modePtr = mode.toNativeUtf8();
    try {
      return _read(fn(rawPtr, hintPtr, modePtr));
    } finally {
      malloc.free(rawPtr);
      malloc.free(hintPtr);
      malloc.free(modePtr);
    }
  }

  String _read(Pointer<Utf8> result) {
    if (result == nullptr) {
      throw StateError('native call returned null');
    }
    try {
      return result.toDartString();
    } finally {
      _free(result);
    }
  }
}

class IsolatedNativeProviders {
  IsolatedNativeProviders();

  Future<String> match(String rawQr, {String hint = ''}) {
    return Isolate.run(() => NativeProvidersLib.open().match(rawQr, hint: hint));
  }

  Future<String> resolve(String rawQr, {String hint = '', bool remote = false, bool wait = false}) {
    return Isolate.run(
      () => NativeProvidersLib.open().resolve(rawQr, hint: hint, remote: remote, wait: wait),
    );
  }

  Future<String> providers() {
    return Isolate.run(() => NativeProvidersLib.open().providers());
  }
}
