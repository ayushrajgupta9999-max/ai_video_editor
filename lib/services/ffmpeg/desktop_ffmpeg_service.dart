// Desktop (Windows/macOS/Linux) FFmpeg implementation using FFmpegKitNext
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/media.dart';
import '../core/errors/media_errors.dart';
import '../core/platform/platform.dart';
import 'media_processing_service.dart';
import 'ffmpeg_kit_wrapper.dart';

const _uuid = Uuid();

class DesktopFFmpegService implements MediaProcessingService {
  final FFmpegKitWrapper _ffmpegKit;
  bool _initialized = false;
  bool _disposed = false;

  DesktopFFmpegService(this._ffmpegKit);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (!PlatformUtils.canUseDartIO) {
      throw UnsupportedPlatformError('DesktopFFmpegService requires native platform');
    }
    await _ffmpegKit.initialize();
    _initialized = true;
  }

  @override
  bool get isAvailable => PlatformUtils.isDesktop && _initialized;

  @override
  String get serviceName => 'FFmpegKitNext (Desktop)';

  @override
  Future<MediaInfo> probeMedia(String path) async {
    _ensureInitialized();
    final result = await _ffmpegKit.execute('-i "$path" -hide_banner');
    return _parseMediaInfo(path, result.output);
  }

  @override
  Future<String> trim({
    required String inputPath,
    required Duration start,
    required Duration duration,
    String? outputPath,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    _ensureInitialized();
    outputPath ??= '${await _getTempDir()}/trim_${_uuid.v4()}.mp4';
    final cmd = '-ss ${start.inMilliseconds / 1000} -t ${duration.inMilliseconds / 1000} -i "$inputPath" -c copy -avoid_negative_ts make_zero "$outputPath"';
    await _executeWithProgress(cmd, onProgress);
    return outputPath;
  }

  @override
  Future<String> concatenate({
    required List<String> inputPaths,
    String? outputPath,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    _ensureInitialized();
    outputPath ??= '${await _getTempDir()}/concat_${_uuid.v4()}.mp4';
    final listFile = '${await _getTempDir()}/concat_list_${_uuid.v4()}.txt';
    final file = File(listFile);
    await file.writeAsString(inputPaths.map((p) => "file '$p'").join('\n'));
    final cmd = '-f concat -safe 0 -i "$listFile" -c copy "$outputPath"';
    await _executeWithProgress(cmd, onProgress);
    await file.delete();
    return outputPath;
  }

  @override
  Future<String> extractAudio({
    required String inputPath,
    String? outputPath,
    AudioCodec codec = AudioCodec.aac,
    int bitrate = 128,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    _ensureInitialized();
    outputPath ??= '${await _getTempDir()}/audio_${_uuid.v4()}.${codec.name}';
    final cmd = '-i "$inputPath" -vn -c:a ${_audioCodecFlag(codec)} -b:a ${bitrate}k "$outputPath"';
    await _executeWithProgress(cmd, onProgress);
    return outputPath;
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
    _ensureInitialized();
    outputPath ??= '${await _getTempDir()}/convert_${_uuid.v4()}.${format?.name ?? 'mp4'}';
    final videoFilter = _buildVideoFilter(width, height, frameRate);
    final cmd = [
      '-i "$inputPath"',
      if (videoCodec != null) '-c:v ${_videoCodecFlag(videoCodec)}',
      if (audioCodec != null) '-c:a ${_audioCodecFlag(audioCodec)}',
      if (videoBitrate != null) '-b:v ${videoBitrate}k',
      if (audioBitrate != null) '-b:a ${audioBitrate}k',
      if (videoFilter.isNotEmpty) '-vf "$videoFilter"',
      '-preset $preset',
      '-movflags +faststart',
      '"$outputPath"',
    ].join(' ');
    await _executeWithProgress(cmd, onProgress);
    return outputPath;
  }

  @override
  Future<String> compress({
    required String inputPath,
    String? outputPath,
    required int targetBitrate,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    return convert(
      inputPath: inputPath,
      outputPath: outputPath,
      videoBitrate: targetBitrate,
      onProgress: onProgress,
    );
  }

  @override
  Future<String> generateThumbnail({
    required String inputPath,
    required Duration position,
    String? outputPath,
    int width = 320,
    int height = 180,
  }) async {
    _ensureInitialized();
    outputPath ??= '${await _getTempDir()}/thumb_${_uuid.v4()}.jpg';
    final cmd = '-ss ${position.inMilliseconds / 1000} -i "$inputPath" -vframes 1 -vf "scale=$width:$height" "$outputPath"';
    await _ffmpegKit.execute(cmd);
    return outputPath;
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
    _ensureInitialized();
    outputPath ??= '${await _getTempDir()}/preview_${_uuid.v4()}.mp4';
    final cmd = '-ss ${start.inMilliseconds / 1000} -t ${duration.inMilliseconds / 1000} -i "$inputPath" -vf "scale=$width:$height" -c:v libx264 -preset fast "$outputPath"';
    await _ffmpegKit.execute(cmd);
    return outputPath;
  }

  @override
  Future<String> export({
    required ExportRequest request,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    _ensureInitialized();
    final filterComplex = _buildExportFilterComplex(request);
    final inputs = _buildExportInputs(request);
    final cmd = [
      inputs,
      if (filterComplex.isNotEmpty) '-filter_complex "$filterComplex"',
      '-c:v ${_videoCodecFlag(request.settings.videoCodec)}',
      '-b:v ${request.settings.videoBitrate}k',
      '-c:a ${_audioCodecFlag(request.settings.audioCodec)}',
      '-b:a ${request.settings.audioBitrate}k',
      '-r ${request.settings.frameRate}',
      '-preset ${request.settings.preset}',
      '-movflags +faststart',
      '"${request.outputPath}"',
    ].join(' ');
    await _executeWithProgress(cmd, onProgress);
    return request.outputPath;
  }

  @override
  Future<void> cancel() async {
    await _ffmpegKit.cancelAll();
  }

  @override
  Future<void> cleanup() async {
    final tempDir = await _getTempDir();
    if (await Directory(tempDir).exists()) {
      await Directory(tempDir).delete(recursive: true);
    }
  }

  @override
  Future<void> dispose() async {
    await _ffmpegKit.dispose();
    _disposed = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DesktopFFmpegService not initialized. Call initialize() first.');
    }
    if (_disposed) {
      throw StateError('DesktopFFmpegService has been disposed.');
    }
  }

  Future<String> _getTempDir() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/ai_video_editor';
  }

  Future<void> _executeWithProgress(String command, void Function(ProcessingProgress)? onProgress) async {
    if (onProgress != null) {
      var progress = 0.0;
      final timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        progress += 0.05;
        if (progress >= 0.95) {
          timer.cancel();
          progress = 0.95;
        }
        onProgress(ProcessingProgress(
          progress: progress.clamp(0.0, 0.95),
          stage: 'Processing',
          elapsedTime: Duration(milliseconds: (timer.tick * 100)),
        ));
      });
      try {
        await _ffmpegKit.execute(command);
        timer.cancel();
        onProgress(ProcessingProgress(progress: 1.0, stage: 'Complete', elapsedTime: Duration.zero));
      } catch (e) {
        timer.cancel();
        rethrow;
      }
    } else {
      await _ffmpegKit.execute(command);
    }
  }

  String _buildVideoFilter(int? width, int? height, int? frameRate) {
    final filters = <String>[];
    if (width != null && height != null) {
      filters.add('scale=$width:$height:force_original_aspect_ratio=decrease');
    }
    if (frameRate != null) {
      filters.add('fps=$frameRate');
    }
    return filters.join(',');
  }

  String _videoCodecFlag(VideoCodec codec) {
    switch (codec) {
      case VideoCodec.h264: return 'libx264';
      case VideoCodec.h265: return 'libx265';
      case VideoCodec.vp8: return 'libvpx';
      case VideoCodec.vp9: return 'libvpx-vp9';
      case VideoCodec.av1: return 'libaom-av1';
      case VideoCodec.proRes: return 'prores_ks';
      default: return 'libx264';
    }
  }

  String _audioCodecFlag(AudioCodec codec) {
    switch (codec) {
      case AudioCodec.aac: return 'aac';
      case AudioCodec.mp3: return 'libmp3lame';
      case AudioCodec.opus: return 'libopus';
      case AudioCodec.flac: return 'flac';
      case AudioCodec.pcm: return 'pcm_s16le';
      default: return 'aac';
    }
  }

  String _buildExportFilterComplex(ExportRequest request) {
    final filters = <String>[];
    var filterIndex = 0;

    for (final track in request.videoTracks) {
      var filter = '[$filterIndex:v]';
      if (track.trimStart != null || track.trimEnd != null) {
        final trimStart = track.trimStart?.inMilliseconds / 1000 ?? 0;
        final trimEnd = track.trimEnd != null
            ? (track.duration.inMilliseconds - track.trimEnd!.inMilliseconds) / 1000
            : track.duration.inMilliseconds / 1000;
        filter += 'trim=start=$trimStart:end=$trimEnd,setpts=PTS-STARTPTS';
      }
      for (final f in track.filters) {
        filter += ',${_buildFilterString(f)}';
      }
      filter += '[v$filterIndex]';
      filters.add(filter);
      filterIndex++;
    }

    if (filters.isEmpty) return '';

    var complex = filters.join(';');
    complex += ';';
    complex += List.generate(filterIndex, (i) => '[v$i]').join('');
    complex += 'concat=n=$filterIndex:v=1:a=0[outv]';

    return complex;
  }

  String _buildExportInputs(ExportRequest request) {
    var cmd = '';
    var index = 0;

    for (final track in request.videoTracks) {
      cmd += ' -i "${track.sourcePath}"';
      index++;
    }
    for (final track in request.audioTracks) {
      cmd += ' -i "${track.sourcePath}"';
      index++;
    }
    return cmd;
  }

  String _buildFilterString(ExportFilter filter) {
    switch (filter.name) {
      case 'colorGrade':
        return 'eq=brightness=${filter.parameters['brightness'] ?? 0}:contrast=${filter.parameters['contrast'] ?? 1}:saturation=${filter.parameters['saturation'] ?? 1}:gamma=${filter.parameters['gamma'] ?? 1}';
      case 'blur':
        return 'boxblur=${filter.parameters['radius'] ?? 5}:${filter.parameters['radius'] ?? 5}';
      case 'sharpen':
        return 'unsharp=5:5:1.5:5:5:0.0';
      case 'vignette':
        return 'vignette=${filter.parameters['angle'] ?? 0.5}';
      case 'lut':
        return 'lut3d="${filter.parameters['path']}"';
      default:
        return '';
    }
  }

  MediaInfo _parseMediaInfo(String path, String ffmpegOutput) {
    return MediaInfo(
      path: path,
      type: MediaType.video,
      duration: Duration.zero,
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
      fileSize: 0,
    );
  }
}