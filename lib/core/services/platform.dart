import 'package:flutter/services.dart';

/// Small native bridge (see MainActivity.kt): FLAG_SECURE to block
/// screenshots / screen recording when the user asks for it, and the
/// Android 13+ notification permission for the route-recording notification.
class PlatformBridge {
  static const _ch = MethodChannel('beat_mitra/window');

  static Future<void> setSecure(bool secure) async {
    try {
      await _ch.invokeMethod('setSecure', secure);
    } on MissingPluginException {
      // Tests / unsupported platform.
    } on PlatformException {
      // ignore
    }
  }

  static Future<void> requestNotificationPermission() async {
    try {
      await _ch.invokeMethod('requestNotifications');
    } on MissingPluginException {
      // Tests / unsupported platform.
    } on PlatformException {
      // ignore
    }
  }
}
