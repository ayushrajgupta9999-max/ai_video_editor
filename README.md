# AI Video Editor

A production-ready, cross-platform AI-powered video editor built with Flutter. Features human-in-the-loop editing with automated AI assistance for transcription, scene detection, silence removal, beat synchronization, and more.

## Features

### Core Editing
- **Multi-track Timeline**: Video, Audio, Text, and Overlay tracks
- **Non-linear Editing**: Trim, split, move, and arrange clips
- **Keyframe Animation**: Position, scale, rotation, opacity
- **Real-time Preview**: Hardware-accelerated video playback
- **Project Management**: Save, load, and organize projects

### AI Automation (Human-in-the-Loop)
- **Auto-Transcription**: Speech-to-text with Whisper (local/cloud)
- **Scene Detection**: Automatic cut detection
- **Silence Removal**: Auto-detect and remove silent segments
- **Beat Synchronization**: Cut to music beats
- **Auto-Reframe**: Crop for vertical/horizontal formats
- **Caption Generation**: Styled captions from transcripts
- **Smart Workflows**: Social media cuts, podcast cleanup, music videos, interview polish

### Export & Quality
- **Multiple Formats**: MP4, MOV, MKV, WebM
- **Codecs**: H.264, H.265, VP9, AV1, ProRes
- **Quality Presets**: Low (720p), Medium (1080p), High (4K)
- **Custom Settings**: Bitrate, framerate, preset, hardware acceleration
- **Platform Optimization**: Native encoding on each platform

### Cross-Platform
- **Android**: Full native FFmpeg support
- **iOS**: Full native FFmpeg support
- **macOS/Windows/Linux**: Desktop native FFmpeg
- **Web**: FFmpeg.wasm with graceful degradation

## Architecture

```
lib/
├── core/
│   ├── constants/          # App constants
│   ├── errors/             # Media error types
│   ├── platform/           # Platform detection
│   ├── permissions/        # Permission handling
│   └── logging/            # Structured logging
├── models/
│   ├── media.dart          # Media info, export settings
│   ├── timeline.dart       # Timeline, tracks, clips
│   └── ai_models.dart      # AI tasks, segments
├── services/
│   ├── media/              # Media processing abstraction
│   ├── ffmpeg/             # Platform-specific FFmpeg
│   ├── storage/            # Project/media storage
│   ├── export/             # Export orchestration
│   └── ai/                 # AI editing service
├── repositories/           # Data access layer
├── features/
│   ├── home/               # Project dashboard
│   ├── editor/             # Main editing interface
│   ├── projects/           # Project management
│   ├── settings/           # App settings
│   ├── import_media/       # Media import
│   └── export_media/       # Export workflow
├── widgets/                # Reusable UI components
├── providers/              # State management
├── screens/                # Screen compositions
└── main.dart               # App entry point
```

## Platform Support

| Platform | Architectures | Status |
|----------|---------------|--------|
| Android  | arm64-v8a, armeabi-v7a, x86_64 | ✅ Full |
| iOS      | arm64         | ✅ Full |
| macOS    | arm64, x86_64 | ✅ Full |
| Windows  | x86_64        | ✅ Full |
| Linux    | x86_64        | ✅ Full |
| Web      | WASM          | ✅ Full |

## Getting Started

### Prerequisites
- Flutter 3.24+ (stable)
- Android Studio / Xcode / VS Code
- Git

### Quick Start
```bash
# Clone
git clone <repository>
cd ai_video_editor

# Install dependencies
flutter pub get

# Run on available device
flutter run
```

### Platform-Specific Setup

#### Android
```bash
flutter config --enable-android
flutter build apk --debug
```

#### iOS/macOS
```bash
flutter config --enable-ios --enable-macos
cd ios && pod install && cd ..
cd macos && pod install && cd ..
flutter run -d ios --debug
```

#### Web
```bash
flutter config --enable-web
flutter run -d chrome --debug
```

#### Desktop
```bash
flutter config --enable-linux --enable-macos --enable-windows
flutter run -d linux --debug  # or macos/windows
```

## Building for Release

### Android
```bash
# App Bundle (Play Store)
flutter build appbundle --release

# Split APKs (direct distribution)
flutter build apk --release --split-per-abi

# Universal APK
flutter build apk --release
```

### iOS/macOS
```bash
flutter build ios --release
flutter build macos --release
```

### Web (PWA)
```bash
flutter build web --release --pwa-strategy=offline-first
```

### Desktop
```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

### CI/CD (GitHub Actions)
See `.github/workflows/` for example workflows.

## FFmpeg Integration

The app uses **FFmpegKitNext** (actively maintained fork) for native platforms and **ffmpeg.wasm** for web.

### Supported Operations
- Trim, concatenate, convert, compress
- Audio extraction
- Thumbnail/preview generation
- Complex filter graphs for export
- Hardware acceleration (where available)

### Web Limitations
- No hardware acceleration
- Memory limited (~2-4GB)
- Virtual filesystem
- Long operations may be throttled

## Development

### Project Structure
- **Clean Architecture**: UI → Providers → Services → Platform implementations
- **Dependency Injection**: Platform services via factory
- **Error Handling**: Typed errors with user-friendly messages
- **State Management**: Provider + ChangeNotifier
- **Null Safety**: Full Dart 3+ null safety

### Running Tests
```bash
flutter test
flutter test test/widget_test.dart
flutter test integration_test/
```

### Code Quality
```bash
flutter analyze
dart format --set-exit-if-changed .
```

## Configuration

### Environment Variables
- `ANDROID_HOME`: Android SDK path
- `JAVA_HOME`: JDK 17 path

### App Settings
- AI Provider: Local (Whisper.cpp) / OpenAI / AssemblyAI
- Export Defaults: Format, quality, codec
- Theme: Dark/Light/System
- Performance: Low-end device mode

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Run `flutter analyze` and `flutter test`
5. Submit PR

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [FFmpegKitNext](https://github.com/tanersener/ffmpeg-kit) - FFmpeg integration
- [ffmpeg.wasm](https://github.com/ffmpegwasm/ffmpeg.wasm) - Web FFmpeg
- [Google Fonts](https://fonts.google.com/) - Typography
- [Provider](https://pub.dev/packages/provider) - State management