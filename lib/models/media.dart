// Media models for cross-platform video editing
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum MediaType { video, audio, image }

enum VideoCodec { h264, h265, vp8, vp9, av1, proRes, unknown }

enum AudioCodec { aac, mp3, opus, flac, pcm, unknown }

enum ContainerFormat { mp4, mov, mkv, webm, mp3, wav, flac, unknown }

class MediaInfo {
  final String id;
  final String path;
  final MediaType type;
  final Duration duration;
  final int width;
  final int height;
  final VideoCodec videoCodec;
  final AudioCodec audioCodec;
  final ContainerFormat container;
  final int bitrate;
  final int frameRate;
  final bool hasAudio;
  final int audioChannels;
  final int audioSampleRate;
  final int fileSize;
  final Map<String, dynamic> metadata;

  MediaInfo({
    String? id,
    required this.path,
    required this.type,
    required this.duration,
    required this.width,
    required this.height,
    required this.videoCodec,
    required this.audioCodec,
    required this.container,
    required this.bitrate,
    required this.frameRate,
    required this.hasAudio,
    required this.audioChannels,
    required this.audioSampleRate,
    required this.fileSize,
    this.metadata = const {},
  }) : id = id ?? _uuid.v4();

  MediaInfo copyWith({
    String? path,
    MediaType? type,
    Duration? duration,
    int? width,
    int? height,
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    ContainerFormat? container,
    int? bitrate,
    int? frameRate,
    bool? hasAudio,
    int? audioChannels,
    int? audioSampleRate,
    int? fileSize,
    Map<String, dynamic>? metadata,
  }) {
    return MediaInfo(
      id: id,
      path: path ?? this.path,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      container: container ?? this.container,
      bitrate: bitrate ?? this.bitrate,
      frameRate: frameRate ?? this.frameRate,
      hasAudio: hasAudio ?? this.hasAudio,
      audioChannels: audioChannels ?? this.audioChannels,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      fileSize: fileSize ?? this.fileSize,
      metadata: metadata ?? this.metadata,
    );
  }

  static MediaInfo unknown(String path) {
    return MediaInfo(
      path: path,
      type: MediaType.video,
      duration: Duration.zero,
      width: 0,
      height: 0,
      videoCodec: VideoCodec.unknown,
      audioCodec: AudioCodec.unknown,
      container: ContainerFormat.unknown,
      bitrate: 0,
      frameRate: 0,
      hasAudio: false,
      audioChannels: 0,
      audioSampleRate: 0,
      fileSize: 0,
    );
  }
}

class ExportSettings {
  final ContainerFormat format;
  final VideoCodec videoCodec;
  final AudioCodec audioCodec;
  final int videoBitrate; // kbps
  final int audioBitrate; // kbps
  final int frameRate;
  final int width;
  final int height;
  final String preset; // ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
  final double audioVolume;
  final bool hardwareAcceleration;

  const ExportSettings({
    this.format = ContainerFormat.mp4,
    this.videoCodec = VideoCodec.h264,
    this.audioCodec = AudioCodec.aac,
    this.videoBitrate = 8000,
    this.audioBitrate = 128,
    this.frameRate = 30,
    this.width = 1920,
    this.height = 1080,
    this.preset = 'medium',
    this.audioVolume = 1.0,
    this.hardwareAcceleration = true,
  });

  ExportSettings copyWith({
    ContainerFormat? format,
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    int? videoBitrate,
    int? audioBitrate,
    int? frameRate,
    int? width,
    int? height,
    String? preset,
    double? audioVolume,
    bool? hardwareAcceleration,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      frameRate: frameRate ?? this.frameRate,
      width: width ?? this.width,
      height: height ?? this.height,
      preset: preset ?? this.preset,
      audioVolume: audioVolume ?? this.audioVolume,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format.name,
        'videoCodec': videoCodec.name,
        'audioCodec': audioCodec.name,
        'videoBitrate': videoBitrate,
        'audioBitrate': audioBitrate,
        'frameRate': frameRate,
        'width': width,
        'height': height,
        'preset': preset,
        'audioVolume': audioVolume,
        'hardwareAcceleration': hardwareAcceleration,
      };

  factory ExportSettings.fromJson(Map<String, dynamic> json) => ExportSettings(
        format: ContainerFormat.values.firstWhere((e) => e.name == json['format'], orElse: () => ContainerFormat.mp4),
        videoCodec: VideoCodec.values.firstWhere((e) => e.name == json['videoCodec'], orElse: () => VideoCodec.h264),
        audioCodec: AudioCodec.values.firstWhere((e) => e.name == json['audioCodec'], orElse: () => AudioCodec.aac),
        videoBitrate: json['videoBitrate'] ?? 8000,
        audioBitrate: json['audioBitrate'] ?? 128,
        frameRate: json['frameRate'] ?? 30,
        width: json['width'] ?? 1920,
        height: json['height'] ?? 1080,
        preset: json['preset'] ?? 'medium',
        audioVolume: (json['audioVolume'] ?? 1.0).toDouble(),
        hardwareAcceleration: json['hardwareAcceleration'] ?? true,
      );
}

class ProcessingProgress {
  final double progress; // 0.0 to 1.0
  final String stage;
  final String? currentFile;
  final int processedBytes;
  final int totalBytes;
  final Duration elapsedTime;
  final Duration? estimatedRemaining;

  const ProcessingProgress({
    required this.progress,
    required this.stage,
    this.currentFile,
    this.processedBytes = 0,
    this.totalBytes = 0,
    required this.elapsedTime,
    this.estimatedRemaining,
  });
}

class ExportResult {
  final String exportId;
  final bool success;
  final String? outputPath;
  final String? error;
  final Duration duration;

  ExportResult({
    required this.exportId,
    required this.success,
    this.outputPath,
    this.error,
    required this.duration,
  });
}

class ExportProgress {
  final String exportId;
  final double progress;
  final String stage;
  final Duration elapsedTime;
  final Duration? estimatedRemaining;

  ExportProgress({
    required this.exportId,
    required this.progress,
    required this.stage,
    required this.elapsedTime,
    this.estimatedRemaining,
  });
}