import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AiProvider { local, openai, assemblyai, custom }

enum AiTaskType {
  transcribe,
  sceneDetect,
  silenceDetect,
  beatDetect,
  autoReframe,
  generateCaption,
  summarize,
  translate,
  textToSpeech,
  imageGeneration,
  styleTransfer,
  colorGrade,
  removeBackground,
  objectTracking,
  faceDetection,
}

enum AiTaskStatus { pending, processing, completed, failed, cancelled }

class AiTask {
  final String id;
  final AiTaskType type;
  final AiProvider provider;
  final Map<String, dynamic> input;
  final Map<String, dynamic>? output;
  final AiTaskStatus status;
  final double progress;
  final String? error;
  final DateTime createdAt;
  final DateTime? completedAt;

  AiTask({
    String? id,
    required this.type,
    required this.provider,
    required this.input,
    this.output,
    this.status = AiTaskStatus.pending,
    this.progress = 0.0,
    this.error,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  AiTask copyWith({
    String? id,
    AiTaskType? type,
    AiProvider? provider,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    AiTaskStatus? status,
    double? progress,
    String? error,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return AiTask(
      id: id ?? this.id,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      input: input ?? this.input,
      output: output ?? this.output,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'provider': provider.index,
        'input': input,
        'output': output,
        'status': status.index,
        'progress': progress,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory AiTask.fromJson(Map<String, dynamic> json) => AiTask(
        id: json['id'],
        type: AiTaskType.values[json['type']],
        provider: AiProvider.values[json['provider']],
        input: Map<String, dynamic>.from(json['input'] ?? {}),
        output: json['output'] != null
            ? Map<String, dynamic>.from(json['output'])
            : null,
        status: AiTaskStatus.values[json['status']],
        progress: json['progress']?.toDouble() ?? 0.0,
        error: json['error'],
        createdAt: DateTime.parse(json['createdAt']),
        completedAt:
            json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      );
}

class TranscriptionSegment {
  final String id;
  final double start;
  final double end;
  final String text;
  final double confidence;
  final List<WordTimestamp> words;
  final String? speaker;

  TranscriptionSegment({
    String? id,
    required this.start,
    required this.end,
    required this.text,
    this.confidence = 1.0,
    List<WordTimestamp>? words,
    this.speaker,
  })  : id = id ?? _uuid.v4(),
        words = words ?? [];

  TranscriptionSegment copyWith({
    String? id,
    double? start,
    double? end,
    String? text,
    double? confidence,
    List<WordTimestamp>? words,
    String? speaker,
  }) {
    return TranscriptionSegment(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      words: words ?? this.words,
      speaker: speaker ?? this.speaker,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start,
        'end': end,
        'text': text,
        'confidence': confidence,
        'words': words.map((w) => w.toJson()).toList(),
        'speaker': speaker,
      };

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) =>
      TranscriptionSegment(
        id: json['id'],
        start: json['start'].toDouble(),
        end: json['end'].toDouble(),
        text: json['text'],
        confidence: json['confidence']?.toDouble() ?? 1.0,
        words: (json['words'] as List? ?? [])
            .map((w) => WordTimestamp.fromJson(w))
            .toList(),
        speaker: json['speaker'],
      );
}

class WordTimestamp {
  final String word;
  final double start;
  final double end;
  final double confidence;

  WordTimestamp({
    required this.word,
    required this.start,
    required this.end,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'start': start,
        'end': end,
        'confidence': confidence,
      };

  factory WordTimestamp.fromJson(Map<String, dynamic> json) => WordTimestamp(
        word: json['word'],
        start: json['start'].toDouble(),
        end: json['end'].toDouble(),
        confidence: json['confidence']?.toDouble() ?? 1.0,
      );
}

class SceneBoundary {
  final String id;
  final double time;
  final double confidence;
  final SceneType type;
  final Map<String, dynamic> metadata;

  SceneBoundary({
    String? id,
    required this.time,
    this.confidence = 1.0,
    this.type = SceneType.cut,
    Map<String, dynamic>? metadata,
  })  : id = id ?? _uuid.v4(),
        metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'confidence': confidence,
        'type': type.index,
        'metadata': metadata,
      };

  factory SceneBoundary.fromJson(Map<String, dynamic> json) => SceneBoundary(
        id: json['id'],
        time: json['time'].toDouble(),
        confidence: json['confidence']?.toDouble() ?? 1.0,
        type: SceneType.values[json['type'] ?? 0],
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
}

enum SceneType { cut, fade, dissolve, wipe, slide, zoom }

class SilenceSegment {
  final String id;
  final double start;
  final double end;
  final double volume;
  final bool isRemovable;

  SilenceSegment({
    String? id,
    required this.start,
    required this.end,
    this.volume = 0.0,
    this.isRemovable = true,
  }) : id = id ?? _uuid.v4();

  double get duration => end - start;

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start,
        'end': end,
        'volume': volume,
        'isRemovable': isRemovable,
      };

  factory SilenceSegment.fromJson(Map<String, dynamic> json) => SilenceSegment(
        id: json['id'],
        start: json['start'].toDouble(),
        end: json['end'].toDouble(),
        volume: json['volume']?.toDouble() ?? 0.0,
        isRemovable: json['isRemovable'] ?? true,
      );
}

class BeatMarker {
  final String id;
  final double time;
  final double confidence;
  final int bpm;
  final bool isDownbeat;

  BeatMarker({
    String? id,
    required this.time,
    this.confidence = 1.0,
    this.bpm = 120,
    this.isDownbeat = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'confidence': confidence,
        'bpm': bpm,
        'isDownbeat': isDownbeat,
      };

  factory BeatMarker.fromJson(Map<String, dynamic> json) => BeatMarker(
        id: json['id'],
        time: json['time'].toDouble(),
        confidence: json['confidence']?.toDouble() ?? 1.0,
        bpm: json['bpm'] ?? 120,
        isDownbeat: json['isDownbeat'] ?? false,
      );
}

class AiSettings {
  final AiProvider defaultProvider;
  final String? openaiApiKey;
  final String? assemblyaiApiKey;
  final String customEndpoint;
  final bool enableLocalWhisper;
  final String whisperModelSize;
  final double sceneDetectionThreshold;
  final double silenceThreshold;
  final int minSilenceDurationMs;
  final bool autoSaveResults;
  final Map<AiTaskType, AiProvider> taskProviderMap;

  AiSettings({
    this.defaultProvider = AiProvider.local,
    this.openaiApiKey,
    this.assemblyaiApiKey,
    this.customEndpoint = '',
    this.enableLocalWhisper = true,
    this.whisperModelSize = 'base',
    this.sceneDetectionThreshold = 0.3,
    this.silenceThreshold = -40.0,
    this.minSilenceDurationMs = 500,
    this.autoSaveResults = true,
    Map<AiTaskType, AiProvider>? taskProviderMap,
  }) : taskProviderMap = taskProviderMap ?? _defaultTaskProviderMap();

  static Map<AiTaskType, AiProvider> _defaultTaskProviderMap() => {
        AiTaskType.transcribe: AiProvider.local,
        AiTaskType.sceneDetect: AiProvider.local,
        AiTaskType.silenceDetect: AiProvider.local,
        AiTaskType.beatDetect: AiProvider.local,
        AiTaskType.autoReframe: AiProvider.local,
        AiTaskType.generateCaption: AiProvider.local,
        AiTaskType.summarize: AiProvider.openai,
        AiTaskType.translate: AiProvider.openai,
        AiTaskType.textToSpeech: AiProvider.openai,
        AiTaskType.imageGeneration: AiProvider.openai,
        AiTaskType.styleTransfer: AiProvider.local,
        AiTaskType.colorGrade: AiProvider.local,
        AiTaskType.removeBackground: AiProvider.local,
        AiTaskType.objectTracking: AiProvider.local,
        AiTaskType.faceDetection: AiProvider.local,
      };

  AiSettings copyWith({
    AiProvider? defaultProvider,
    String? openaiApiKey,
    String? assemblyaiApiKey,
    String? customEndpoint,
    bool? enableLocalWhisper,
    String? whisperModelSize,
    double? sceneDetectionThreshold,
    double? silenceThreshold,
    int? minSilenceDurationMs,
    bool? autoSaveResults,
    Map<AiTaskType, AiProvider>? taskProviderMap,
  }) {
    return AiSettings(
      defaultProvider: defaultProvider ?? this.defaultProvider,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      assemblyaiApiKey: assemblyaiApiKey ?? this.assemblyaiApiKey,
      customEndpoint: customEndpoint ?? this.customEndpoint,
      enableLocalWhisper: enableLocalWhisper ?? this.enableLocalWhisper,
      whisperModelSize: whisperModelSize ?? this.whisperModelSize,
      sceneDetectionThreshold: sceneDetectionThreshold ?? this.sceneDetectionThreshold,
      silenceThreshold: silenceThreshold ?? this.silenceThreshold,
      minSilenceDurationMs: minSilenceDurationMs ?? this.minSilenceDurationMs,
      autoSaveResults: autoSaveResults ?? this.autoSaveResults,
      taskProviderMap: taskProviderMap ?? this.taskProviderMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultProvider': defaultProvider.index,
        'openaiApiKey': openaiApiKey,
        'assemblyaiApiKey': assemblyaiApiKey,
        'customEndpoint': customEndpoint,
        'enableLocalWhisper': enableLocalWhisper,
        'whisperModelSize': whisperModelSize,
        'sceneDetectionThreshold': sceneDetectionThreshold,
        'silenceThreshold': silenceThreshold,
        'minSilenceDurationMs': minSilenceDurationMs,
        'autoSaveResults': autoSaveResults,
        'taskProviderMap': taskProviderMap.map((k, v) => MapEntry(k.index, v.index)),
      };

  factory AiSettings.fromJson(Map<String, dynamic> json) => AiSettings(
        defaultProvider: AiProvider.values[json['defaultProvider'] ?? 0],
        openaiApiKey: json['openaiApiKey'],
        assemblyaiApiKey: json['assemblyaiApiKey'],
        customEndpoint: json['customEndpoint'] ?? '',
        enableLocalWhisper: json['enableLocalWhisper'] ?? true,
        whisperModelSize: json['whisperModelSize'] ?? 'base',
        sceneDetectionThreshold: json['sceneDetectionThreshold']?.toDouble() ?? 0.3,
        silenceThreshold: json['silenceThreshold']?.toDouble() ?? -40.0,
        minSilenceDurationMs: json['minSilenceDurationMs'] ?? 500,
        autoSaveResults: json['autoSaveResults'] ?? true,
        taskProviderMap: (json['taskProviderMap'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(AiTaskType.values[int.parse(k)], AiProvider.values[v as int])) ??
            _defaultTaskProviderMap(),
      );
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

  CaptionStyle copyWith({
    int? fontSize,
    String? fontColor,
    String? backgroundColor,
    double? opacity,
    double? position,
    String? fontFamily,
    bool? wordByWord,
  }) {
    return CaptionStyle(
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      opacity: opacity ?? this.opacity,
      position: position ?? this.position,
      fontFamily: fontFamily ?? this.fontFamily,
      wordByWord: wordByWord ?? this.wordByWord,
    );
  }

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