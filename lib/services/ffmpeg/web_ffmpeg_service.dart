// Web FFmpeg implementation using browser APIs and WebAssembly
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop' as js_interop;
import 'package:uuid/uuid.dart';
import '../models/media.dart';
import '../core/errors/media_errors.dart';
import '../core/platform/platform.dart';
import 'media_processing_service.dart';

const _uuid = Uuid();

class WebFFmpegService implements MediaProcessingService {
  bool _initialized = false;
  bool _disposed = false;
  late final _WebFFmpeg _webFFmpeg;

  WebFFmpegService() {
    _webFFmpeg = _WebFFmpeg();
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (!PlatformUtils.isWeb) {
      throw UnsupportedPlatformError('WebFFmpegService requires web platform');
    }
    await _webFFmpeg.load();
    _initialized = true;
  }

  @override
  bool get isAvailable => PlatformUtils.isWeb && _initialized;

  @override
  String get serviceName => 'FFmpeg.wasm (Web)';

  @override
  Future<MediaInfo> probeMedia(String path) async {
    _ensureInitialized();
    // On web, we can't easily probe local files without user interaction
    // Return basic info from the file
    final file = await _getFileFromPath(path);
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
      fileSize: file?.size ?? 0,
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
    _ensureInitialized();
    outputPath ??= 'trim_${_uuid.v4()}.mp4';
    await _runFFmpeg(
      '-ss ${start.inMilliseconds / 1000} -t ${duration.inMilliseconds / 1000} -i "$inputPath" -c copy "$outputPath"',
      onProgress,
    );
    return outputPath;
  }

  @override
  Future<String> concatenate({
    required List<String> inputPaths,
    String? outputPath,
    void Function(ProcessingProgress)? onProgress,
  }) async {
    _ensureInitialized();
    outputPath ??= 'concat_${_uuid.v4()}.mp4';
    // Write concat list to virtual FS
    final listContent = inputPaths.map((p) => "file '$p'").join('\n');
    await _webFFmpeg.writeFile('concat_list.txt', listContent);
    await _runFFmpeg('-f concat -safe 0 -i concat_list.txt -c copy "$outputPath"', onProgress);
    await _webFFmpeg.deleteFile('concat_list.txt');
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
    outputPath ??= 'audio_${_uuid.v4()}.${codec.name}';
    await _runFFmpeg('-i "$inputPath" -vn -c:a ${_audioCodecFlag(codec)} -b:a ${bitrate}k "$outputPath"', onProgress);
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
    outputPath ??= 'convert_${_uuid.v4()}.${format?.name ?? 'mp4'}';
    final videoFilter = _buildVideoFilter(width, height, frameRate);
    final cmd = [
      '-i "$inputPath"',
      if (videoCodec != null) '-c:v ${_videoCodecFlag(videoCodec)}',
      if (audioCodec != null) '-c:a ${_audioCodecFlag(audioCodec)}',
      if (videoBitrate != null) '-b:v ${videoBitrate}k',
      if (audioBitrate != null) '-b:a ${audioBitrate}k',
      if (videoFilter.isNotEmpty) '-vf "$videoFilter"',
      '-preset $preset',
      '"$outputPath"',
    ].join(' ');
    await _runFFmpeg(cmd, onProgress);
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
    outputPath ??= 'thumb_${_uuid.v4()}.jpg';
    await _runFFmpeg('-ss ${position.inMilliseconds / 1000} -i "$inputPath" -vframes 1 -vf "scale=$width:$height" "$outputPath"');
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
    outputPath ??= 'preview_${_uuid.v4()}.mp4';
    await _runFFmpeg('-ss ${start.inMilliseconds / 1000} -t ${duration.inMilliseconds / 1000} -i "$inputPath" -vf "scale=$width:$height" "$outputPath"');
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
      '"${request.outputPath}"',
    ].join(' ');
    await _runFFmpeg(cmd, onProgress);
    return request.outputPath;
  }

  @override
  Future<void> cancel() async {
    _webFFmpeg.terminate();
  }

  @override
  Future<void> cleanup() async {
    await _webFFmpeg.cleanup();
  }

  @override
  Future<void> dispose() async {
    await _webFFmpeg.dispose();
    _disposed = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('WebFFmpegService not initialized. Call initialize() first.');
    }
    if (_disposed) {
      throw StateError('WebFFmpegService has been disposed.');
    }
  }

  Future<void> _runFFmpeg(String command, void Function(ProcessingProgress)? onProgress) async {
    final completer = Completer<void>();
    var progress = 0.0;

    _webFFmpeg.setProgressCallback((p) {
      progress = p;
      onProgress?.call(ProcessingProgress(
        progress: p,
        stage: 'Processing',
        elapsedTime: Duration.zero,
      ));
    });

    try {
      await _webFFmpeg.run(command);
      completer.complete();
      onProgress?.call(ProcessingProgress(progress: 1.0, stage: 'Complete', elapsedTime: Duration.zero));
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      await completer.future;
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

  Future<html.File?> _getFileFromPath(String path) async {
    // On web, paths are typically blob URLs or object URLs
    // This would need to be integrated with the file picker
    return null;
  }
}

// Web FFmpeg wrapper using ffmpeg.wasm
class _WebFFmpeg {
  final _jsInterop = _JSInterop();
  Function(double)? _progressCallback;

  Future<void> load() async {
    // Load ffmpeg.wasm from CDN
    await _jsInterop.loadFFmpeg();
  }

  void setProgressCallback(Function(double) callback) {
    _progressCallback = callback;
  }

  Future<void> writeFile(String name, String content) async {
    await _jsInterop.writeFile(name, content);
  }

  Future<void> deleteFile(String name) async {
    await _jsInterop.deleteFile(name);
  }

  Future<void> run(String command) async {
    await _jsInterop.run(command);
  }

  void terminate() {
    _jsInterop.terminate();
  }

  Future<void> cleanup() async {
    await _jsInterop.cleanup();
  }

  Future<void> dispose() async {
    await _jsInterop.dispose();
  }
}

class _JSInterop {
  @js_interop.JS('ffmpeg')
  external static _FFmpegModule get _ffmpegModule;

  Future<void> loadFFmpeg() async {
    // Load from CDN
    await _loadScript('https://unpkg.com/@ffmpeg/ffmpeg@0.12.0/dist/ffmpeg.min.js');
    await _loadScript('https://unpkg.com/@ffmpeg/core@0.12.0/dist/ffmpeg-core.js');
  }

  Future<void> _loadScript(String url) async {
    final script = html.ScriptElement()
      ..src = url
      ..async = true
      ..defer = true;
    html.document.head!.append(script);
    await script.onLoad.first;
  }

  Future<void> writeFile(String name, String content) async {
    await _ffmpegModule.writeFile(name, content);
  }

  Future<void> deleteFile(String name) async {
    await _ffmpegModule.deleteFile(name);
  }

  Future<void> run(String command) async {
    await _ffmpegModule.run(command.toJS);
  }

  void terminate() {
    _ffmpegModule.terminate();
  }

  Future<void> cleanup() async {
    await _ffmpegModule.cleanup();
  }

  Future<void> dispose() async {
    await _ffmpegModule.dispose();
  }
}

@js_interop.JS()
@js_interop.anonymous
class _FFmpegModule {
  external Future<void> writeFile(String name, String content);
  external Future<void> deleteFile(String name);
  external Future<void> run(js_interop.JSString command);
  external void terminate();
  external Future<void> cleanup();
  external Future<void> dispose();
}