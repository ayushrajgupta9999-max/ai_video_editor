// FFmpegKit wrapper for Android (uses FFmpegKitNext)
import 'dart:async';
import 'package:flutter/services.dart';

class FFmpegKitWrapper {
  static const MethodChannel _channel = MethodChannel('com.arthenica.ffmpegkit');

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod('initialize');
      _initialized = true;
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize FFmpegKit: ${e.message}');
    }
  }

  Future<FFmpegKitResult> execute(String command) async {
    if (!_initialized) {
      throw StateError('FFmpegKit not initialized');
    }
    try {
      final result = await _channel.invokeMethod('execute', {'command': command});
      return FFmpegKitResult(
        returnCode: result['returnCode'] ?? -1,
        output: result['output'] ?? '',
        success: result['returnCode'] == 0,
      );
    } on PlatformException catch (e) {
      throw Exception('FFmpeg execution failed: ${e.message}');
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('cancelAll');
    } on PlatformException {
      // Ignore cancel errors
    }
  }

  Future<void> dispose() async {
    _initialized = false;
  }
}

class FFmpegKitResult {
  final int returnCode;
  final String output;
  final bool success;

  FFmpegKitResult({
    required this.returnCode,
    required this.output,
    required this.success,
  });
}