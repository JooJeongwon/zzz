import 'dart:io';
import 'package:flutter/services.dart';

class NativeBridgeService {
  static const MethodChannel _channel = MethodChannel('com.joo.zzz.app/heartbeat');

  /// Starts the iOS Live Activity.
  /// [status] - The current status (e.g., "SLEEP", "STUDY").
  /// [message] - A short message to display.
  static Future<void> startLiveActivity(String status, String message) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('startLiveActivity', {
        'status': status,
        'message': message,
      });
    } on PlatformException catch (e) {
      print("Failed to start Live Activity: '${e.message}'.");
    }
  }

  /// Updates the existing iOS Live Activity.
  static Future<void> updateLiveActivity(String status, String message) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('updateLiveActivity', {
        'status': status,
        'message': message,
      });
    } on PlatformException catch (e) {
      print("Failed to update Live Activity: '${e.message}'.");
    }
  }

  /// Ends the iOS Live Activity.
  static Future<void> stopLiveActivity() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('stopLiveActivity');
    } on PlatformException catch (e) {
      print("Failed to stop Live Activity: '${e.message}'.");
    }
  }
}
