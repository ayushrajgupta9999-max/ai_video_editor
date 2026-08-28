// Platform abstraction for cross-platform compatibility
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum TargetPlatform {
  android,
  ios,
  windows,
  macos,
  linux,
  web,
  unknown,
}

class PlatformUtils {
  static TargetPlatform get currentPlatform {
    if (kIsWeb) return TargetPlatform.web;
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.ios;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isMacOS) return TargetPlatform.macos;
    if (Platform.isLinux) return TargetPlatform.linux;
    return TargetPlatform.unknown;
  }

  static bool get isMobile => currentPlatform == TargetPlatform.android || currentPlatform == TargetPlatform.ios;
  static bool get isDesktop => currentPlatform == TargetPlatform.windows || currentPlatform == TargetPlatform.macos || currentPlatform == TargetPlatform.linux;
  static bool get isWeb => currentPlatform == TargetPlatform.web;
  static bool get supportsNativeFFmpeg => isMobile || isDesktop;
  static bool get supportsWebFFmpeg => isWeb;

  static String get platformName => currentPlatform.name;

  static bool get canUseDartIO => !kIsWeb;
}