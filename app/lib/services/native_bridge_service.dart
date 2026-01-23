import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class INativeBridgeService {
  Future<void> startLiveActivity(String status, String message);
  Future<void> updateLiveActivity(String status, String message);
  Future<void> stopLiveActivity();
  Future<String> startHeartbeat(String userId, String accessToken, String baseUrl);
}

class NativeBridgeService implements INativeBridgeService {
  static const MethodChannel _channel = MethodChannel('com.joo.zzz.app/heartbeat');

  @override
  Future<void> startLiveActivity(String status, String message) async {
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

  @override
  Future<void> updateLiveActivity(String status, String message) async {
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

  @override
  Future<void> stopLiveActivity() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('stopLiveActivity');
    } on PlatformException catch (e) {
      print("Failed to stop Live Activity: '${e.message}'.");
    }
  }

  @override
  Future<String> startHeartbeat(String userId, String accessToken, String baseUrl) async {
    try {
      final String result = await _channel.invokeMethod('startHeartbeat', {
        'userId': userId,
        'accessToken': accessToken,
        'baseUrl': baseUrl,
      });
      return 'Success: $result';
    } on PlatformException catch (e) {
      return "Failed to start service: '${e.message}'.";
    }
  }
}

final nativeBridgeServiceProvider = Provider<INativeBridgeService>((ref) {
  return NativeBridgeService();
});
