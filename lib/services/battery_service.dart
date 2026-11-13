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

  Future<void> requestIgnore() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException {
      // some OEMs block the direct dialog — the user can still allow it
      // from system battery settings
    }
  }
}
