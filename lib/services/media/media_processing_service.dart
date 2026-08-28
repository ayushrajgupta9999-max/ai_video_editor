// FFmpeg abstraction interface for cross-platform media processing
import 'dart:async';
import '../models/media.dart';
import '../core/errors/media_errors.dart';

abstract class MediaProcessingService {
  /// Initialize the service (load native libraries, etc.)
  Future<void> initialize();

  /// Check if the service is available on this platform
  bool get isAvailable;

  /// Get the service name/version for debugging
  String get serviceName;

  /// Get the temporary directory for this service
  Future<String> getTempDir();

  /// Probe a media file to get its info
  Future<MediaInfo> probeMedia(String path);

  /// Trim a media file
  Future<String> trim({
    required String inputPath,
    required Duration start,
    required Duration duration,
    String? outputPath,
    void Function(ProcessingProgress)? onProgress,
  });

  /// Concatenate multiple media files
  Future<String> concatenate({
    required List<String> inputPaths,
    String? outputPath,
    void Function(ProcessingProgress)? onProgress,
  });

  /// Extract audio from a video file
  Future<String> extractAudio({
    required String inputPath,
    String? outputPath,
    AudioCodec codec = AudioCodec.aac,
    int bitrate = 128,
    void Function(ProcessingProgress)? onProgress,
  });

  /// Convert/transcode a media file
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
  });

  /// Compress a media file
  Future<String> compress({
    required String inputPath,
    String? outputPath,
    required int targetBitrate,
    void Function(ProcessingProgress)? onProgress,
  });

  /// Generate a thumbnail from a video
  Future<String> generateThumbnail({
    required String inputPath,
    required Duration position,
    String? outputPath,
    int width = 320,
    int height = 180,
  });

  /// Generate a preview (short clip) from a video
  Future<String> generatePreview({
    required String inputPath,
    required Duration start,
    required Duration duration,
    String? outputPath,
    int width = 640,
    int height = 360,
  });

  /// Export a project with complex filter graph
  Future<String> export({
    required ExportRequest request,
    void Function(ProcessingProgress)? onProgress,
  });

  /// Cancel an ongoing operation
  Future<void> cancel();

  /// Clean up temporary files
  Future<void> cleanup();

  /// Dispose resources
  Future<void> dispose();
}

class ExportRequest {
  final List<ExportTrack> videoTracks;
  final List<ExportTrack> audioTracks;
  final ExportSettings settings;
  final String outputPath;
  final Map<String, dynamic>? filterGraph;

  const ExportRequest({
    required this.videoTracks,
    required this.audioTracks,
    required this.settings,
    required this.outputPath,
    this.filterGraph,
  });
}

class ExportTrack {
  final String sourcePath;
  final Duration startTime;
  final Duration duration;
  final Duration? trimStart;
  final Duration? trimEnd;
  final Map<String, dynamic> properties;
  final List<ExportFilter> filters;

  const ExportTrack({
    required this.sourcePath,
    required this.startTime,
    required this.duration,
    this.trimStart,
    this.trimEnd,
    this.properties = const {},
    this.filters = const [],
  });
}

class ExportFilter {
  final String name;
  final Map<String, dynamic> parameters;
  final Duration startTime;
  final Duration endTime;

  const ExportFilter({
    required this.name,
    this.parameters = const {},
    required this.startTime,
    required this.endTime,
  });
}