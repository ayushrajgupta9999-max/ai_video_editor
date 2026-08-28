import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TrackType { video, audio, text, overlay }

enum ClipType { video, audio, image, text, generated }

class TimelineClip {
  final String id;
  final TrackType trackType;
  final ClipType clipType;
  final String sourcePath;
  final double startTime;
  final double duration;
  final double trimStart;
  final double trimEnd;
  final double volume;
  final double opacity;
  final Map<String, dynamic> properties;
  final List<Keyframe> keyframes;
  final bool isAiGenerated;
  final String? aiPrompt;
  final bool isSelected;

  TimelineClip({
    String? id,
    required this.trackType,
    required this.clipType,
    required this.sourcePath,
    required this.startTime,
    required this.duration,
    this.trimStart = 0.0,
    this.trimEnd = 0.0,
    this.volume = 1.0,
    this.opacity = 1.0,
    Map<String, dynamic>? properties,
    List<Keyframe>? keyframes,
    this.isAiGenerated = false,
    this.aiPrompt,
    this.isSelected = false,
  })  : id = id ?? _uuid.v4(),
        properties = properties ?? {},
        keyframes = keyframes ?? [];

  TimelineClip copyWith({
    String? id,
    TrackType? trackType,
    ClipType? clipType,
    String? sourcePath,
    double? startTime,
    double? duration,
    double? trimStart,
    double? trimEnd,
    double? volume,
    double? opacity,
    Map<String, dynamic>? properties,
    List<Keyframe>? keyframes,
    bool? isAiGenerated,
    String? aiPrompt,
    bool? isSelected,
  }) {
    return TimelineClip(
      id: id ?? this.id,
      trackType: trackType ?? this.trackType,
      clipType: clipType ?? this.clipType,
      sourcePath: sourcePath ?? this.sourcePath,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      volume: volume ?? this.volume,
      opacity: opacity ?? this.opacity,
      properties: properties ?? this.properties,
      keyframes: keyframes ?? this.keyframes,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  double get endTime => startTime + duration;
  double get effectiveDuration => duration - trimStart - trimEnd;

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackType': trackType.index,
        'clipType': clipType.index,
        'sourcePath': sourcePath,
        'startTime': startTime,
        'duration': duration,
        'trimStart': trimStart,
        'trimEnd': trimEnd,
        'volume': volume,
        'opacity': opacity,
        'properties': properties,
        'keyframes': keyframes.map((k) => k.toJson()).toList(),
        'isAiGenerated': isAiGenerated,
        'aiPrompt': aiPrompt,
        'isSelected': isSelected,
      };

  factory TimelineClip.fromJson(Map<String, dynamic> json) => TimelineClip(
        id: json['id'],
        trackType: TrackType.values[json['trackType']],
        clipType: ClipType.values[json['clipType']],
        sourcePath: json['sourcePath'],
        startTime: json['startTime'].toDouble(),
        duration: json['duration'].toDouble(),
        trimStart: json['trimStart']?.toDouble() ?? 0.0,
        trimEnd: json['trimEnd']?.toDouble() ?? 0.0,
        volume: json['volume']?.toDouble() ?? 1.0,
        opacity: json['opacity']?.toDouble() ?? 1.0,
        properties: Map<String, dynamic>.from(json['properties'] ?? {}),
        keyframes: (json['keyframes'] as List? ?? [])
            .map((k) => Keyframe.fromJson(k))
            .toList(),
        isAiGenerated: json['isAiGenerated'] ?? false,
        aiPrompt: json['aiPrompt'],
        isSelected: json['isSelected'] ?? false,
      );
}

class Keyframe {
  final String id;
  final double time;
  final String property;
  final dynamic value;
  final EasingType easing;

  Keyframe({
    String? id,
    required this.time,
    required this.property,
    required this.value,
    this.easing = EasingType.linear,
  }) : id = id ?? _uuid.v4();

  Keyframe copyWith({
    String? id,
    double? time,
    String? property,
    dynamic value,
    EasingType? easing,
  }) {
    return Keyframe(
      id: id ?? this.id,
      time: time ?? this.time,
      property: property ?? this.property,
      value: value ?? this.value,
      easing: easing ?? this.easing,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'property': property,
        'value': value,
        'easing': easing.index,
      };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
        id: json['id'],
        time: json['time'].toDouble(),
        property: json['property'],
        value: json['value'],
        easing: EasingType.values[json['easing'] ?? 0],
      );
}

enum EasingType { linear, easeIn, easeOut, easeInOut, bounce, elastic }

class TimelineTrack {
  final String id;
  final TrackType type;
  final int index;
  final List<TimelineClip> clips;
  final bool isMuted;
  final bool isLocked;
  final double height;

  TimelineTrack({
    String? id,
    required this.type,
    required this.index,
    List<TimelineClip>? clips,
    this.isMuted = false,
    this.isLocked = false,
    this.height = 60.0,
  })  : id = id ?? _uuid.v4(),
        clips = clips ?? [];

  TimelineTrack copyWith({
    String? id,
    TrackType? type,
    int? index,
    List<TimelineClip>? clips,
    bool? isMuted,
    bool? isLocked,
    double? height,
  }) {
    return TimelineTrack(
      id: id ?? this.id,
      type: type ?? this.type,
      index: index ?? this.index,
      clips: clips ?? this.clips,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'index': index,
        'clips': clips.map((c) => c.toJson()).toList(),
        'isMuted': isMuted,
        'isLocked': isLocked,
        'height': height,
      };

  factory TimelineTrack.fromJson(Map<String, dynamic> json) => TimelineTrack(
        id: json['id'],
        type: TrackType.values[json['type']],
        index: json['index'],
        clips: (json['clips'] as List? ?? []).map((c) => TimelineClip.fromJson(c)).toList(),
        isMuted: json['isMuted'] ?? false,
        isLocked: json['isLocked'] ?? false,
        height: json['height']?.toDouble() ?? 60.0,
      );
}

class Timeline {
  final List<TimelineTrack> tracks;
  final double duration;
  final double zoomLevel;
  final double scrollOffset;

  Timeline({
    List<TimelineTrack>? tracks,
    this.duration = 0.0,
    this.zoomLevel = 1.0,
    this.scrollOffset = 0.0,
  }) : tracks = tracks ?? _defaultTracks();

  static List<TimelineTrack> _defaultTracks() => [
        TimelineTrack(type: TrackType.video, index: 0),
        TimelineTrack(type: TrackType.video, index: 1),
        TimelineTrack(type: TrackType.audio, index: 2),
        TimelineTrack(type: TrackType.audio, index: 3),
        TimelineTrack(type: TrackType.text, index: 4),
        TimelineTrack(type: TrackType.overlay, index: 5),
      ];

  Timeline copyWith({
    List<TimelineTrack>? tracks,
    double? duration,
    double? zoomLevel,
    double? scrollOffset,
  }) {
    return Timeline(
      tracks: tracks ?? this.tracks,
      duration: duration ?? this.duration,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }

  double get totalDuration => tracks
      .expand((t) => t.clips)
      .fold(0.0, (max, clip) => clip.endTime > max ? clip.endTime : max);

  Map<String, dynamic> toJson() => {
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'duration': duration,
        'zoomLevel': zoomLevel,
        'scrollOffset': scrollOffset,
      };

  factory Timeline.fromJson(Map<String, dynamic> json) => Timeline(
        tracks: (json['tracks'] as List? ?? [])
            .map((t) => TimelineTrack.fromJson(t))
            .toList(),
        duration: json['duration']?.toDouble() ?? 0.0,
        zoomLevel: json['zoomLevel']?.toDouble() ?? 1.0,
        scrollOffset: json['scrollOffset']?.toDouble() ?? 0.0,
      );
}