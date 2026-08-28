// Factory for creating platform-appropriate FFmpeg services
import 'dart:io';
import '../core/platform/platform.dart';
import 'media_processing_service.dart';
import 'android_ffmpeg_service.dart';
import 'ios_ffmpeg_service.dart';
import 'desktop_ffmpeg_service.dart';
import 'web_ffmpeg_service.dart';
import 'ffmpeg_kit_wrapper.dart';

class FFmpegServiceFactory {
  static MediaProcessingService? _instance;

  static Future<MediaProcessingService> create() async {
    if (_instance != null) return _instance!;

    final platform = PlatformUtils.currentPlatform;
    MediaProcessingService service;

    switch (platform) {
      case TargetPlatform.android:
        service = AndroidFFmpegService(FFmpegKitWrapper());
        break;
      case TargetPlatform.ios:
        service = IosFFmpegService(FFmpegKitWrapper());
        break;
      case TargetPlatform.windows:
      case TargetPlatform.macos:
      case TargetPlatform.linux:
        service = DesktopFFmpegService(FFmpegKitWrapper());
        break;
      case TargetPlatform.web:
        service = WebFFmpegService();
        break;
      default:
        throw UnsupportedError('Unsupported platform: $platform');
    }

    await service.initialize();
    _instance = service;
    return service;
  }

  static MediaProcessingService? get instance => _instance;

  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }

  // For testing - allows injecting a mock
  static void setInstance(MediaProcessingService service) {
    _instance = service;
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

// Mock service for testing and development
class MockMediaProcessingService implements MediaProcessingService {
  MockMediaProcessingService();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  bool get isAvailable => true;

  @override
  String get serviceName => 'Mock (Testing)';

  @override
  Future<String> getTempDir() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/ai_video_editor';
  }

  @override
  Future<MediaInfo> probeMedia(String path) async {
    return MediaInfo(
      path: path,
      type: MediaType.video,
      duration: const Duration(seconds: 10),
      width: 1920,
      height: 1080,
      videoCodec: VideoCodec.h264,
      audioCodec: AudioCodec.aac,
      container: ContainerFormat.mp4,
      bitrate: 8000,
      frameRate: 30,
      hasAudio: true,
      audioChannels: 2,
      audioSampleRate: 44100,
      fileSize: 1000000,
    );
  }

  @override
  Future<String> trim({
    required String inputPath,
    required Duration start,
    required Duration duration,
    String? outputPath,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return outputPath ?? 'trim_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  @override
  Future<String> concatenate({
    required List<String> inputPaths,
    String? outputPath,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return outputPath ?? 'concat_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  @override
  Future<String> extractAudio({
    required String inputPath,
    String? outputPath,
    AudioCodec codec = AudioCodec.aac,
    int bitrate = 128,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return outputPath ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.${codec.name}';
  }

  @override
  Future<String> convert({
    required String inputPath,
    String? outputPath,
    ContainerFormat? format,
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    int? videoBitrate,
    int? audioBitrate,
    int? width,
    int? height,
    int? frameRate,
    String preset = 'medium',
    void Function(ProcessingProgress)? onProgress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return outputPath ?? 'convert_${DateTime.now().millisecondsSinceEpoch}.${format?.name ?? 'mp4'}';
  }

  @override
  Future<String> compress({
    required String inputPath,
    String? outputPath,
    required int targetBitrate,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    return convert(inputPath: inputPath, outputPath: outputPath, videoBitrate: targetBitrate, onProgress: onProgress);
  }

  @override
  Future<String> generateThumbnail({
    required String inputPath,
    required Duration position,
    String? outputPath,
    int width = 320,
    int height = 180,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return outputPath ?? 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<String> generatePreview({
    required String inputPath,
    required Duration start,
    required Duration duration,
    String? outputPath,
    int width = 640,
    int height = 360,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return outputPath ?? 'preview_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  @override
  Future<String> export({
    required ExportRequest request,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return request.outputPath;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> cleanup() async {}

  @override
  Future<void> dispose() async {}
}