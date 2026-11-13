import 'dart:io';

import 'package:flutter/services.dart';

class BatteryService {
  static const _channel = MethodChannel('dev.explorefaith.monora/battery');

  Future<bool> isIgnoring() async {
    if (!Platform.isAndroid) return true;
    try {
      final v = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return v ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Returns true when the direct exemption dialog was shown, false when it
  /// was blocked and the app details settings opened instead.
  Future<bool> requestIgnore() async {
    if (!Platform.isAndroid) return true;
    try {
      final shown = await _channel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return shown ?? false;
    } on PlatformException {
      return false;
    }
  }
}
