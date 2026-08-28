# AI Video Editor - Build Documentation

## Overview

This document describes how to build the AI Video Editor application for all supported platforms.

## Prerequisites

### Required Software

- **Flutter SDK**: 3.24+ (stable channel)
- **Dart SDK**: 3.5+ (included with Flutter)
- **Android Studio**: Latest stable with Android SDK
- **Xcode**: 15+ (for iOS/macOS builds)
- **Visual Studio 2022**: (for Windows builds)
- **CMake**: 3.20+ (for Linux/desktop builds)
- **Git**: Latest

### Platform-Specific Requirements

#### Android
- Android SDK 34 (API level 34)
- NDK 26.1+
- Java 17 (JDK)
- Gradle 8.5+

#### iOS/macOS
- Xcode 15+
- iOS Deployment Target: 13.0+
- macOS Deployment Target: 10.15+

#### Web
- Chrome/Edge/Firefox latest
- WebAssembly support

#### Windows
- Windows 10/11 SDK
- Visual Studio 2022 with C++ workload

#### Linux
- GTK 3.0+
- CMake 3.20+
- ninja-build
- clang/lldb

## Environment Setup

### 1. Flutter Setup

```bash
# Verify Flutter installation
flutter doctor -v

# Enable platforms
flutter config --enable-android --enable-ios --enable-web --enable-linux --enable-macos --enable-windows
```

### 2. Android Setup

```bash
# Set Android SDK path (if not auto-detected)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Accept licenses
flutter doctor --android-licenses
```

### 3. iOS/macOS Setup

```bash
# Install CocoaPods
sudo gem install cocoapods
cd ios && pod install && cd ..

# For macOS desktop
cd macos && pod install && cd ..
```

## Building

### Development Builds

#### Android Debug APK
```bash
flutter build apk --debug
```

#### iOS Debug
```bash
flutter build ios --debug --no-codesign
```

#### Web Debug
```bash
flutter run -d chrome --debug
```

#### Desktop Debug
```bash
# Linux
flutter run -d linux --debug

# macOS
flutter run -d macos --debug

# Windows
flutter run -d windows --debug
```

### Release Builds

#### Android Release

**Universal APK (larger, runs on all architectures):**
```bash
flutter build apk --release
```

**Split APKs (smaller, architecture-specific):**
```bash
flutter build apk --release --split-per-abi
```
This produces:
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

#### iOS Release
```bash
flutter build ios --release
# Then archive in Xcode for distribution
```

#### macOS Release
```bash
flutter build macos --release
# Creates .app bundle in build/macos/Build/Products/Release/
```

#### Windows Release
```bash
flutter build windows --release
# Creates executable in build/windows/x64/runner/Release/
```

#### Linux Release
```bash
flutter build linux --release
# Creates executable in build/linux/x64/release/bundle/
```

#### Web Release (PWA)
```bash
flutter build web --release --pwa-strategy=offline-first
# Output in build/web/
```

### CI/CD Build (x86_64 Linux)

For production Android releases, use an x86_64 Linux environment:

```yaml
# .github/workflows/android-release.yml
name: Android Release
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.3'
          channel: 'stable'
      - name: Install dependencies
        run: flutter pub get
      - name: Build App Bundle
        run: flutter build appbundle --release
      - name: Build Split APKs
        run: flutter build apk --release --split-per-abi
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-release
          path: |
            build/app/outputs/bundle/release/*.aab
            build/app/outputs/flutter-apk/*.apk
```

## FFmpeg Integration

### Native Platforms (Android/iOS/Desktop)

The app uses **FFmpegKitNext** - the actively maintained fork of FFmpegKit.

#### Version
- FFmpegKitNext: 6.0+
- FFmpeg: 6.1+

#### Supported Architectures
- Android: armeabi-v7a, arm64-v8a, x86_64
- iOS: arm64
- Desktop: x86_64

#### Licensing
- LGPL 2.1 (default)
- GPL 3.0 (full GPL variant available)

### Web Platform

The web version uses **ffmpeg.wasm** (FFmpeg compiled to WebAssembly).

#### Version
- @ffmpeg/ffmpeg: 0.12+
- @ffmpeg/core: 0.12+

#### Limitations
- No hardware acceleration
- Memory limited by browser (~2-4GB)
- No direct filesystem access (uses virtual FS)
- Long-running operations may be throttled

## Troubleshooting

### Common Issues

#### Android Build Fails with "Namespace not specified"
```bash
# Ensure namespace is set in build.gradle.kts
android {
    namespace = "com.aivideo.ai_video_editor"
}
```

#### FFmpegKit Not Found
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

#### Out of Memory on Android
```gradle
# In android/app/build.gradle.kts
android {
    defaultConfig {
        multiDexEnabled = true
    }
}
```

#### Web Build Fails - CORS Issues
```bash
# Serve with proper headers
flutter build web --release
# Serve with: python3 -m http.server -d build/web 8080
```

#### iOS Build Fails - CocoaPods
```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### Desktop Build Fails - Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# Fedora
sudo dnf install clang cmake ninja-build pkg-config gtk3-devel

# Arch
sudo pacman -S clang cmake ninja pkg-config gtk3
```

### Performance Tuning

#### Android
- Enable R8/ProGuard for release
- Use App Bundle for Play Store
- Configure appropriate minSdk (21+ recommended)

#### iOS
- Enable bitcode (if needed)
- Strip debug symbols
- Optimize for size

#### Web
- Enable compression (gzip/brotli)
- Use service workers for offline
- Configure proper cache headers

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter test integration_test/
```

### Platform-Specific Tests
```bash
# Android
flutter test --platform android

# iOS
flutter test --platform ios
```

## Distribution

### Android
1. **Google Play Store**: Use App Bundle (.aab)
2. **Direct Distribution**: Use split APKs or universal APK
3. **Internal Testing**: Use debug APK

### iOS/macOS
1. **App Store**: Archive in Xcode, upload via Transporter
2. **TestFlight**: For beta testing
3. **Direct**: Export .ipa/.app from Xcode

### Web
1. **Firebase Hosting**: `firebase deploy`
2. **Netlify/Vercel**: Connect repository
3. **Custom Server**: Serve `build/web/` with proper headers

### Desktop
1. **GitHub Releases**: Upload artifacts
2. **Microsoft Store**: Package as MSIX
3. **Snap/Flatpak**: For Linux distribution

## Versioning

Follow Semantic Versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes

Update version in `pubspec.yaml`:
```yaml
version: 1.2.3+45
```

Build number (after +) increments with each build.

## Support Matrix

| Platform | Architectures | Min Version | Status |
|----------|---------------|-------------|--------|
| Android  | arm64-v8a, armeabi-v7a, x86_64 | API 21+ | ✅ Full |
| iOS      | arm64         | iOS 13+     | ✅ Full |
| macOS    | arm64, x86_64 | 10.15+      | ✅ Full |
| Windows  | x86_64        | 10+         | ✅ Full |
| Linux    | x86_64        | GTK 3.24+   | ✅ Full |
| Web      | WASM          | Modern browsers | ✅ Full |

## Security Considerations

- No arbitrary command execution
- All FFmpeg arguments constructed from validated data
- Temporary files cleaned up automatically
- No sensitive data in logs
- Network access only for AI cloud features (user consent required)

## Maintenance

### Updating Dependencies
```bash
flutter pub upgrade
flutter pub upgrade --major-versions
```

### Updating FFmpeg
1. Update `ffmpeg_kit_flutter_next` version in pubspec.yaml
2. Run `flutter pub get`
3. Test on all platforms
4. Check for API changes

### Monitoring
- Track crash reports (Firebase Crashlytics, Sentry)
- Monitor performance metrics
- Review user feedback for platform-specific issues