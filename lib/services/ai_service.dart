import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_models.dart';
import '../models/timeline.dart';
import 'ffmpeg_service.dart';

const _uuid = Uuid();

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final FFmpegService _ffmpeg = FFmpegService();
  AiSettings _settings = AiSettings();

  AiSettings get settings => _settings;

  void updateSettings(AiSettings settings) {
    _settings = settings;
  }

  Future<String> _getWhisperModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/whisper_models');
    await modelDir.create(recursive: true);
    final modelFile = File('${modelDir.path}/ggml-${_settings.whisperModelSize}.bin');
    return modelFile.path;
  }

  Future<bool> _ensureWhisperModel() async {
    final modelPath = await _getWhisperModelPath();
    if (await File(modelPath).exists()) return true;
    
    final url = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${_settings.whisperModelSize}.bin';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await File(modelPath).writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (e) {
      print('Failed to download Whisper model: $e');
    }
    return false;
  }

  Future<AiTask> transcribe({
    required String audioPath,
    String language = 'auto',
    Function(double)? onProgress,
  }) async {
    final task = AiTask(
      type: AiTaskType.transcribe,
      provider: _settings.taskProviderMap[AiTaskType.transcribe] ?? AiProvider.local,
      input: {'audioPath': audioPath, 'language': language},
    );

    if (task.provider == AiProvider.local) {
      return _transcribeLocal(task, audioPath, language, onProgress);
    } else if (task.provider == AiProvider.openai) {
      return _transcribeOpenAI(task, audioPath, language, onProgress);
    } else if (task.provider == AiProvider.assemblyai) {
      return _transcribeAssemblyAI(task, audioPath, language, onProgress);
    }

    return task.copyWith(status: AiTaskStatus.failed, error: 'Unknown provider');
  }

  Future<AiTask> _transcribeLocal(
    AiTask task,
    String audioPath,
    String language,
    Function(double)? onProgress,
  ) async {
    final modelPath = await _getWhisperModelPath();
    final hasModel = await _ensureWhisperModel();
    if (!hasModel) {
      return task.copyWith(status: AiTaskStatus.failed, error: 'Whisper model not found');
    }

    final outputDir = await _ffmpeg.tempDir;
    final outputPath = '$outputDir/transcript_${task.id}.json';

    final cmd = 'whisper-cli -m "$modelPath" -f "$audioPath" -oj -of "$outputDir/transcript_${task.id}" -l ${language == 'auto' ? 'auto' : language}';

    try {
      final result = await _ffmpeg.execute(cmd);
      if (!result.success) {
        return task.copyWith(status: AiTaskStatus.failed, error: result.output);
      }

      final jsonFile = File('$outputPath');
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final data = json.decode(content);
        final segments = (data['segments'] as List? ?? [])
            .map((s) => TranscriptionSegment.fromJson(s))
            .toList();

        return task.copyWith(
          status: AiTaskStatus.completed,
          progress: 1.0,
          output: {'segments': segments.map((s) => s.toJson()).toList()},
          completedAt: DateTime.now(),
        );
      }
    } catch (e) {
      return task.copyWith(status: AiTaskStatus.failed, error: e.toString());
    }

    return task.copyWith(status: AiTaskStatus.failed, error: 'Transcription failed');
  }

  Future<AiTask> _transcribeOpenAI(
    AiTask task,
    String audioPath,
    String language,
    Function(double)? onProgress,
  ) async {
    if (_settings.openaiApiKey == null || _settings.openaiApiKey!.isEmpty) {
      return task.copyWith(status: AiTaskStatus.failed, error: 'OpenAI API key not set');
    }

    try {
      final file = File(audioPath);
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', Uri.parse('https://api.openai.com/v1/audio/transcriptions'));
      request.headers['Authorization'] = 'Bearer ${_settings.openaiApiKey}';
      request.fields['model'] = 'whisper-1';
      if (language != 'auto') request.fields['language'] = language;
      request.fields['response_format'] = 'verbose_json';
      request.fields['timestamp_granularities[]'] = 'word';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'audio.wav'));

      onProgress?.call(0.5);
      final response = await request.send();
      onProgress?.call(0.8);

      if (response.statusCode == 200) {
        final data = json.decode(await response.stream.bytesToString());
        final segments = (data['segments'] as List? ?? [])
            .map((s) => TranscriptionSegment(
                  id: _uuid.v4(),
                  start: s['start'].toDouble(),
                  end: s['end'].toDouble(),
                  text: s['text'],
                  confidence: s['avg_logprob']?.toDouble() ?? 1.0,
                  words: (s['words'] as List? ?? [])
                      .map((w) => WordTimestamp(
                            word: w['word'],
                            start: w['start'].toDouble(),
                            end: w['end'].toDouble(),
                            confidence: w['probability']?.toDouble() ?? 1.0,
                          ))
                      .toList(),
                ))
            .toList();

        return task.copyWith(
          status: AiTaskStatus.completed,
          progress: 1.0,
          output: {'segments': segments.map((s) => s.toJson()).toList()},
          completedAt: DateTime.now(),
        );
      } else {
        final error = await response.stream.bytesToString();
        return task.copyWith(status: AiTaskStatus.failed, error: error);
      }
    } catch (e) {
      return task.copyWith(status: AiTaskStatus.failed, error: e.toString());
    }
  }

  Future<AiTask> _transcribeAssemblyAI(
    AiTask task,
    String audioPath,
    String language,
    Function(double)? onProgress,
  ) async {
    if (_settings.assemblyaiApiKey == null || _settings.assemblyaiApiKey!.isEmpty) {
      return task.copyWith(status: AiTaskStatus.failed, error: 'AssemblyAI API key not set');
    }

    try {
      final file = File(audioPath);
      final bytes = await file.readAsBytes();
      final uploadRequest = http.MultipartRequest('POST', Uri.parse('https://api.assemblyai.com/v2/upload'));
      uploadRequest.headers['Authorization'] = _settings.assemblyaiApiKey!;
      uploadRequest.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'audio.wav'));

      onProgress?.call(0.2);
      final uploadResponse = await uploadRequest.send();
      if (uploadResponse.statusCode != 200) {
        return task.copyWith(status: AiTaskStatus.failed, error: 'Upload failed');
      }
      final uploadData = json.decode(await uploadResponse.stream.bytesToString());
      final audioUrl = uploadData['upload_url'];

      final transcriptRequest = http.Request('POST', Uri.parse('https://api.assemblyai.com/v2/transcript'));
      transcriptRequest.headers['Authorization'] = _settings.assemblyaiApiKey!;
      transcriptRequest.headers['Content-Type'] = 'application/json';
      transcriptRequest.body = json.encode({
        'audio_url': audioUrl,
        'language_code': language == 'auto' ? null : language,
        'word_boost': [],
        'speaker_labels': true,
      });

      onProgress?.call(0.4);
      final transcriptResponse = await transcriptRequest.send();
      if (transcriptResponse.statusCode != 200) {
        return task.copyWith(status: AiTaskStatus.failed, error: 'Transcript request failed');
      }
      final transcriptData = json.decode(await transcriptResponse.stream.bytesToString());
      final transcriptId = transcriptData['id'];

      String status = 'queued';
      Map<String, dynamic> pollData = {};
      while (status != 'completed' && status != 'error') {
        await Future.delayed(const Duration(seconds: 2));
        final pollResponse = await http.get(
          Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
          headers: {'Authorization': _settings.assemblyaiApiKey!},
        );
        pollData = json.decode(pollResponse.body);
        status = pollData['status'];
        onProgress?.call(0.4 + 0.5 * (status == 'completed' ? 1.0 : 0.5));
      }

      if (status == 'error') {
        return task.copyWith(status: AiTaskStatus.failed, error: pollData['error']?.toString() ?? 'Unknown error');
      }

      final segments = (pollData['words'] as List? ?? [])
          .map((w) => TranscriptionSegment(
                id: _uuid.v4(),
                start: w['start'].toDouble() / 1000,
                end: w['end'].toDouble() / 1000,
                text: w['text'],
                confidence: w['confidence']?.toDouble() ?? 1.0,
                words: [
                  WordTimestamp(
                    word: w['text'],
                    start: w['start'].toDouble() / 1000,
                    end: w['end'].toDouble() / 1000,
                    confidence: w['confidence']?.toDouble() ?? 1.0,
                  ),
                ],
                speaker: w['speaker'],
              ))
          .toList();

      return task.copyWith(
        status: AiTaskStatus.completed,
        progress: 1.0,
        output: {'segments': segments.map((s) => s.toJson()).toList()},
        completedAt: DateTime.now(),
      );
    } catch (e) {
      return task.copyWith(status: AiTaskStatus.failed, error: e.toString());
    }
  }

  Future<AiTask> detectScenes({
    required String videoPath,
    double threshold = 0.3,
    Function(double)? onProgress,
  }) async {
    final task = AiTask(
      type: AiTaskType.sceneDetect,
      provider: _settings.taskProviderMap[AiTaskType.sceneDetect] ?? AiProvider.local,
      input: {'videoPath': videoPath, 'threshold': threshold},
    );

    final outputDir = await _ffmpeg.tempDir;
    final outputPath = '$outputDir/scenes_${task.id}.txt';

    final cmd = '-i "$videoPath" -vf "select=gt(scene,$threshold),showinfo" -f null - 2>"$outputPath"';
    final result = await _ffmpeg.execute(cmd);

    if (!result.success) {
      return task.copyWith(status: AiTaskStatus.failed, error: result.output);
    }

    final content = await File(outputPath).readAsString();
    final boundaries = _parseSceneBoundaries(content);

    return task.copyWith(
      status: AiTaskStatus.completed,
      progress: 1.0,
      output: {'boundaries': boundaries.map((b) => b.toJson()).toList()},
      completedAt: DateTime.now(),
    );
  }

  List<SceneBoundary> _parseSceneBoundaries(String ffmpegOutput) {
    final boundaries = <SceneBoundary>[];
    final regex = RegExp(r'pts_time:(\d+\.?\d*)');
    for (final match in regex.allMatches(ffmpegOutput)) {
      final time = double.parse(match.group(1)!);
      boundaries.add(SceneBoundary(time: time, type: SceneType.cut));
    }
    return boundaries;
  }

  Future<AiTask> detectSilences({
    required String audioPath,
    double threshold = -40.0,
    int minDurationMs = 500,
    Function(double)? onProgress,
  }) async {
    final task = AiTask(
      type: AiTaskType.silenceDetect,
      provider: _settings.taskProviderMap[AiTaskType.silenceDetect] ?? AiProvider.local,
      input: {'audioPath': audioPath, 'threshold': threshold, 'minDurationMs': minDurationMs},
    );

    final outputDir = await _ffmpeg.tempDir;
    final outputPath = '$outputDir/silence_${task.id}.txt';

    final cmd = '-i "$audioPath" -af "silencedetect=n=${threshold}dB:d=${minDurationMs / 1000}" -f null - 2>"$outputPath"';
    final result = await _ffmpeg.execute(cmd);

    if (!result.success) {
      return task.copyWith(status: AiTaskStatus.failed, error: result.output);
    }

    final content = await File(outputPath).readAsString();
    final silences = _parseSilences(content);

    return task.copyWith(
      status: AiTaskStatus.completed,
      progress: 1.0,
      output: {'silences': silences.map((s) => s.toJson()).toList()},
      completedAt: DateTime.now(),
    );
  }

  List<SilenceSegment> _parseSilences(String ffmpegOutput) {
    final silences = <SilenceSegment>[];
    final startRegex = RegExp(r'silence_start: (\d+\.?\d*)');
    final endRegex = RegExp(r'silence_end: (\d+\.?\d*)');
    final starts = startRegex.allMatches(ffmpegOutput).map((m) => double.parse(m.group(1)!)).toList();
    final ends = endRegex.allMatches(ffmpegOutput).map((m) => double.parse(m.group(1)!)).toList();

    for (int i = 0; i < starts.length && i < ends.length; i++) {
      silences.add(SilenceSegment(start: starts[i], end: ends[i]));
    }
    return silences;
  }

  Future<AiTask> detectBeats({
    required String audioPath,
    Function(double)? onProgress,
  }) async {
    final task = AiTask(
      type: AiTaskType.beatDetect,
      provider: _settings.taskProviderMap[AiTaskType.beatDetect] ?? AiProvider.local,
      input: {'audioPath': audioPath},
    );

    final outputDir = await _ffmpeg.tempDir;
    final outputPath = '$outputDir/beats_${task.id}.txt';

    final cmd = '-i "$audioPath" -af "abufilt,beat=1:rate=44100" -f null - 2>"$outputPath"';
    final result = await _ffmpeg.execute(cmd);

    if (!result.success) {
      return task.copyWith(status: AiTaskStatus.failed, error: result.output);
    }

    final content = await File(outputPath).readAsString();
    final beats = _parseBeats(content);

    return task.copyWith(
      status: AiTaskStatus.completed,
      progress: 1.0,
      output: {'beats': beats.map((b) => b.toJson()).toList()},
      completedAt: DateTime.now(),
    );
  }

  List<BeatMarker> _parseBeats(String ffmpegOutput) {
    final beats = <BeatMarker>[];
    final regex = RegExp(r'beat: (\d+\.?\d*)');
    for (final match in regex.allMatches(ffmpegOutput)) {
      final time = double.parse(match.group(1)!);
      beats.add(BeatMarker(time: time));
    }
    return beats;
  }

  Future<AiTask> autoReframe({
    required String videoPath,
    required double targetAspectRatio,
    Function(double)? onProgress,
  }) async {
    final task = AiTask(
      type: AiTaskType.autoReframe,
      provider: _settings.taskProviderMap[AiTaskType.autoReframe] ?? AiProvider.local,
      input: {'videoPath': videoPath, 'targetAspectRatio': targetAspectRatio},
    );

    final outputDir = await _ffmpeg.tempDir;
    final outputPath = '$outputDir/reframe_${task.id}.mp4';

    final cmd = '-i "$videoPath" -vf "crop=ih*$targetAspectRatio:ih:(iw-ih*$targetAspectRatio)/2:0" -c:a copy "$outputPath"';
    final result = await _ffmpeg.execute(cmd);

    if (!result.success) {
      return task.copyWith(status: AiTaskStatus.failed, error: result.output);
    }

    return task.copyWith(
      status: AiTaskStatus.completed,
      progress: 1.0,
      output: {'outputPath': outputPath},
      completedAt: DateTime.now(),
    );
  }

  Future<AiTask> generateCaptions({
    required List<TranscriptionSegment> segments,
    CaptionStyle? style,
    Function(double)? onProgress,
  }) async {
    final task = AiTask(
      type: AiTaskType.generateCaption,
      provider: _settings.taskProviderMap[AiTaskType.generateCaption] ?? AiProvider.local,
      input: {'segments': segments.map((s) => s.toJson()).toList(), 'style': style?.toJson()},
    );

    final captions = segments.map((s) => s.copyWith(
      text: _formatCaptionText(s.text),
    )).toList();

    return task.copyWith(
      status: AiTaskStatus.completed,
      progress: 1.0,
      output: {'captions': captions.map((c) => c.toJson()).toList()},
      completedAt: DateTime.now(),
    );
  }

  String _formatCaptionText(String text) {
    return text.trim();
  }

  Future<AiTask> runTask(AiTask task, {Function(double)? onProgress}) async {
    switch (task.type) {
      case AiTaskType.transcribe:
        return transcribe(
          audioPath: task.input['audioPath'],
          language: task.input['language'] ?? 'auto',
          onProgress: onProgress,
        );
      case AiTaskType.sceneDetect:
        return detectScenes(
          videoPath: task.input['videoPath'],
          threshold: task.input['threshold']?.toDouble() ?? 0.3,
          onProgress: onProgress,
        );
      case AiTaskType.silenceDetect:
        return detectSilences(
          audioPath: task.input['audioPath'],
          threshold: task.input['threshold']?.toDouble() ?? -40.0,
          minDurationMs: task.input['minDurationMs'] ?? 500,
          onProgress: onProgress,
        );
      case AiTaskType.beatDetect:
        return detectBeats(
          audioPath: task.input['audioPath'],
          onProgress: onProgress,
        );
      case AiTaskType.autoReframe:
        return autoReframe(
          videoPath: task.input['videoPath'],
          targetAspectRatio: task.input['targetAspectRatio']?.toDouble() ?? 9/16,
          onProgress: onProgress,
        );
      case AiTaskType.generateCaption:
        return generateCaptions(
          segments: (task.input['segments'] as List?)
                  ?.map((s) => TranscriptionSegment.fromJson(s))
                  .toList() ??
              [],
          onProgress: onProgress,
        );
      default:
        return task.copyWith(status: AiTaskStatus.failed, error: 'Task type not implemented');
    }
  }
}

class CaptionStyle {
  final int fontSize;
  final String fontColor;
  final String backgroundColor;
  final double opacity;
  final double position;
  final String fontFamily;
  final bool wordByWord;

  CaptionStyle({
    this.fontSize = 24,
    this.fontColor = 'white',
    this.backgroundColor = 'black',
    this.opacity = 0.7,
    this.position = 0.85,
    this.fontFamily = 'Arial',
    this.wordByWord = true,
  });

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'fontColor': fontColor,
        'backgroundColor': backgroundColor,
        'opacity': opacity,
        'position': position,
        'fontFamily': fontFamily,
        'wordByWord': wordByWord,
      };

  factory CaptionStyle.fromJson(Map<String, dynamic> json) => CaptionStyle(
        fontSize: json['fontSize'] ?? 24,
        fontColor: json['fontColor'] ?? 'white',
        backgroundColor: json['backgroundColor'] ?? 'black',
        opacity: json['opacity']?.toDouble() ?? 0.7,
        position: json['position']?.toDouble() ?? 0.85,
        fontFamily: json['fontFamily'] ?? 'Arial',
        wordByWord: json['wordByWord'] ?? true,
      );
}