import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _CLogNative = Void Function(Int32, Pointer<Utf8>);
typedef _CSetLogNative = Void Function(Pointer<NativeFunction<_CLogNative>>);
typedef _CFreeFn = Void Function(Pointer<Utf8>);

/// Host adapter: library calls [checkscan_set_log], Flutter prints the line.
final class NativeHostLog {
  NativeHostLog._();

  static final NativeHostLog instance = NativeHostLog._();

  NativeCallable<_CLogNative>? _callable;
  void Function(Pointer<Utf8>)? _free;

  void attach() {
    if (_callable != null) return;
    if (!Platform.isAndroid) return;
    final lib = DynamicLibrary.open('libcheckscan.so');
    final setLog = lib.lookupFunction<_CSetLogNative, void Function(Pointer<NativeFunction<_CLogNative>>)>(
      'checkscan_set_log',
    );
    _free = lib.lookupFunction<_CFreeFn, void Function(Pointer<Utf8>)>('checkscan_free');
    _callable = NativeCallable<_CLogNative>.listener(_onLog);
    setLog(_callable!.nativeFunction);
  }

  void _onLog(int level, Pointer<Utf8> message) {
    try {
      developer.log(message.toDartString(), name: 'checkscan', level: _dartLevel(level));
    } finally {
      _free?.call(message);
    }
  }

  static int _dartLevel(int native) {
    return switch (native) {
      3 => 500,
      5 => 900,
      6 => 1000,
      _ => 800,
    };
  }
}
