// Main application provider with new architecture
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/timeline.dart';
import '../models/media.dart';
import '../models/ai_models.dart';
import '../services/media/media_processing_service.dart';
import '../services/storage/storage_service.dart';
import '../services/export/export_service.dart';
import '../services/ai/ai_editing_service.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  final MediaProcessingService _mediaService;
  final StorageService _storageService;
  late final ExportService _exportService;
  late final AiEditingService _aiService;

  Timeline _timeline = Timeline();
  List<AiTask> _aiTasks = [];
  bool _isPlaying = false;
  double _playheadPosition = 0.0;
  double _duration = 0.0;
  String? _currentProjectId;
  Project? _currentProject;
  bool _isLoading = false;
  String? _error;
  ExportSettings _exportSettings = ExportSettings();
  AiSettings _aiSettings = AiSettings();
  bool _showAiPanel = true;

  // Getters
  MediaProcessingService get mediaService => _mediaService;
  StorageService get storageService => _storageService;
  ExportService get exportService => _exportService;
  AiEditingService get aiService => _aiService;

  Timeline get timeline => _timeline;
  List<AiTask> get aiTasks => _aiTasks;
  bool get isPlaying => _isPlaying;
  double get playheadPosition => _playheadPosition;
  double get duration => _duration;
  String? get currentProjectId => _currentProjectId;
  Project? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ExportSettings get exportSettings => _exportSettings;
  AiSettings get aiSettings => _aiSettings;
  bool get showAiPanel => _showAiPanel;
  String? get currentProjectPath => _currentProject?.name;

  AppProvider({
    required MediaProcessingService mediaService,
    required StorageService storageService,
  })  : _mediaService = mediaService,
        _storageService = storageService,
        _exportService = ExportService(mediaService, storageService),
        _aiService = AiEditingService(mediaService, AiSettings());

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setPlayheadPosition(double position) {
    _playheadPosition = position.clamp(0.0, _duration);
    notifyListeners();
  }

  void setDuration(double duration) {
    _duration = duration;
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setShowAiPanel(bool show) {
    _showAiPanel = show;
    notifyListeners();
  }

  void addTrack(TrackType type) {
    final newIndex = _timeline.tracks.where((t) => t.type == type).length;
    final track = TimelineTrack(type: type, index: newIndex);
    _timeline = _timeline.copyWith(tracks: [..._timeline.tracks, track]);
    notifyListeners();
  }

  void removeTrack(String trackId) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.where((t) => t.id != trackId).toList(),
    );
    notifyListeners();
  }

  void toggleTrackMute(String trackId) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(isMuted: !t.isMuted);
        return t;
      }).toList(),
    );
    notifyListeners();
  }

  void toggleTrackLock(String trackId) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) return t.copyWith(isLocked: !t.isLocked);
        return t;
      }).toList(),
    );
    notifyListeners();
  }

  Future<void> addClip({
    required TrackType trackType,
    required ClipType clipType,
    required String sourcePath,
    required double startTime,
    required double duration,
    Map<String, dynamic>? properties,
    bool isAiGenerated = false,
    String? aiPrompt,
  }) async {
    final trackIndex = _timeline.tracks.indexWhere((t) => t.type == trackType && !t.isLocked);
    if (trackIndex == -1) {
      addTrack(trackType);
      return addClip(
        trackType: trackType,
        clipType: clipType,
        sourcePath: sourcePath,
        startTime: startTime,
        duration: duration,
        properties: properties,
        isAiGenerated: isAiGenerated,
        aiPrompt: aiPrompt,
      );
    }

    final clip = TimelineClip(
      trackType: trackType,
      clipType: clipType,
      sourcePath: sourcePath,
      startTime: startTime,
      duration: duration,
      properties: properties ?? {},
      isAiGenerated: isAiGenerated,
      aiPrompt: aiPrompt,
    );

    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.asMap().entries.map((entry) {
        if (entry.key == trackIndex) {
          return entry.value.copyWith(clips: [...entry.value.clips, clip]);
        }
        return entry.value;
      }).toList(),
    );

    _duration = _timeline.totalDuration;
    notifyListeners();
  }

  void updateClip(String trackId, String clipId, TimelineClip updatedClip) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(
            clips: t.clips.map((c) => c.id == clipId ? updatedClip : c).toList(),
          );
        }
        return t;
      }).toList(),
    );
    _duration = _timeline.totalDuration;
    notifyListeners();
  }

  void removeClip(String trackId, String clipId) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(clips: t.clips.where((c) => c.id != clipId).toList());
        }
        return t;
      }).toList(),
    );
    _duration = _timeline.totalDuration;
    notifyListeners();
  }

  void selectClip(String trackId, String clipId, {bool selected = true}) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(
            clips: t.clips.map((c) => c.id == clipId
                ? c.copyWith(isSelected: selected)
                : c.copyWith(isSelected: false)).toList(),
          );
        }
        return t;
      }).toList(),
    );
    notifyListeners();
  }

  void moveClip(String trackId, String clipId, double newStartTime) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(
            clips: t.clips.map((c) {
              if (c.id == clipId) return c.copyWith(startTime: math.max(newStartTime, 0));
              return c;
            }).toList(),
          );
        }
        return t;
      }).toList(),
    );
    _duration = _timeline.totalDuration;
    notifyListeners();
  }

  void trimClip(String trackId, String clipId, {double? trimStart, double? trimEnd}) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(
            clips: t.clips.map((c) {
              if (c.id == clipId) return c.copyWith(
                trimStart: trimStart ?? c.trimStart,
                trimEnd: trimEnd ?? c.trimEnd,
              );
              return c;
            }).toList(),
          );
        }
        return t;
      }).toList(),
    );
    notifyListeners();
  }

  void splitClip(String trackId, String clipId, double splitTime) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          final clipIndex = t.clips.indexWhere((c) => c.id == clipId);
          if (clipIndex == -1) return t;
          final clip = t.clips[clipIndex];
          if (splitTime <= clip.startTime || splitTime >= clip.endTime) return t;

          final leftClip = clip.copyWith(
            id: _uuid.v4(),
            duration: splitTime - clip.startTime,
            trimEnd: 0,
          );
          final rightClip = clip.copyWith(
            id: _uuid.v4(),
            startTime: splitTime,
            duration: clip.endTime - splitTime,
            trimStart: 0,
          );

          final newClips = [...t.clips];
          newClips.removeAt(clipIndex);
          newClips.insert(clipIndex, leftClip);
          newClips.insert(clipIndex + 1, rightClip);

          return t.copyWith(clips: newClips);
        }
        return t;
      }).toList(),
    );
    notifyListeners();
  }

  void addKeyframe(String trackId, String clipId, Keyframe keyframe) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(
            clips: t.clips.map((c) {
              if (c.id == clipId) {
                final existingIndex = c.keyframes.indexWhere((k) => k.property == keyframe.property && k.time == keyframe.time);
                if (existingIndex >= 0) {
                  final newKeyframes = [...c.keyframes];
                  newKeyframes[existingIndex] = keyframe;
                  return c.copyWith(keyframes: newKeyframes);
                }
                return c.copyWith(keyframes: [...c.keyframes, keyframe]..sort((a, b) => a.time.compareTo(b.time)));
              }
              return c;
            }).toList(),
          );
        }
        return t;
      }).toList(),
    );
    notifyListeners();
  }

  void removeKeyframe(String trackId, String clipId, String keyframeId) {
    _timeline = _timeline.copyWith(
      tracks: _timeline.tracks.map((t) {
        if (t.id == trackId) {
          return t.copyWith(
            clips: t.clips.map((c) {
              if (c.id == clipId) {
                return c.copyWith(keyframes: c.keyframes.where((k) => k.id != keyframeId).toList());
              }
              return c;
            }).toList(),
          );
        }
        return t;
      }).toList(),
    );
    notifyListeners();
  }

  void setZoomLevel(double zoom) {
    _timeline = _timeline.copyWith(zoomLevel: zoom.clamp(0.1, 100.0));
    notifyListeners();
  }

  void setScrollOffset(double offset) {
    _timeline = _timeline.copyWith(scrollOffset: math.max(offset, 0));
    notifyListeners();
  }

  void addAiTask(AiTask task) {
    _aiTasks = [..._aiTasks, task];
    notifyListeners();
  }

  void updateAiTask(AiTask task) {
    _aiTasks = _aiTasks.map((t) => t.id == task.id ? task : t).toList();
    notifyListeners();
  }

  void removeAiTask(String taskId) {
    _aiTasks = _aiTasks.where((t) => t.id != taskId).toList();
    notifyListeners();
  }

  void clearAiTasks() {
    _aiTasks = [];
    notifyListeners();
  }

  Future<void> runAiTask(AiTask task) async {
    final updatedTask = task.copyWith(status: AiTaskStatus.processing);
    updateAiTask(updatedTask);

    final result = await _aiService.runTask(updatedTask, onProgress: (progress) {
      updateAiTask(updatedTask.copyWith(progress: progress));
    });

    updateAiTask(result);
  }

  void updateExportSettings(ExportSettings settings) {
    _exportSettings = settings;
    notifyListeners();
  }

  void updateAiSettings(AiSettings settings) {
    _aiSettings = settings;
    _aiService = AiEditingService(_mediaService, settings);
    notifyListeners();
  }

  Future<ExportResult> exportProject({
    required Project project,
    required ExportSettings settings,
    required String outputPath,
    void Function(ExportProgress)? onProgress,
  }) async {
    setLoading(true);
    setError(null);

    try {
      final result = await _exportService.exportProject(
        project: project,
        settings: settings,
        outputPath: outputPath,
        onProgress: onProgress,
      );
      setLoading(false);
      return result;
    } catch (e) {
      setLoading(false);
      setError('Export error: $e');
      return ExportResult(
        exportId: _uuid.v4(),
        success: false,
        error: e.toString(),
        duration: Duration.zero,
      );
    }
  }

  Future<void> loadProject(String projectId) async {
    setLoading(true);
    try {
      final project = await _storageService.loadProject(projectId);
      if (project != null) {
        _currentProject = project;
        _currentProjectId = project.id;
        _timeline = project.timeline;
        _exportSettings = project.exportSettings;
        _duration = _timeline.totalDuration;
        setError(null);
      } else {
        setError('Project not found');
      }
    } catch (e) {
      setError('Failed to load project: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveCurrentProject() async {
    if (_currentProject == null) return;

    setLoading(true);
    try {
      final updatedProject = _currentProject!.copyWith(
        name: _currentProject!.name,
        timeline: _timeline,
        exportSettings: _exportSettings,
      );
      await _storageService.saveProject(updatedProject);
      _currentProject = updatedProject;
      setError(null);
    } catch (e) {
      setError('Failed to save project: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> newProject() async {
    _timeline = Timeline();
    _aiTasks = [];
    _playheadPosition = 0;
    _duration = 0;
    _currentProjectId = null;
    _currentProject = null;
    _error = null;
    notifyListeners();
  }

  Future<Project?> createProjectFromMedia(List<String> mediaPaths) async {
    final project = Project(
      name: 'New Project ${DateTime.now().toString().substring(0, 16)}',
      timeline: Timeline(),
    );

    _currentProject = project;
    _currentProjectId = project.id;
    _timeline = project.timeline;

    // Add media files to timeline
    for (final path in mediaPaths) {
      final ext = path.split('.').last.toLowerCase();
      TrackType trackType;
      ClipType clipType;

      if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        trackType = TrackType.video;
        clipType = ClipType.video;
      } else if (['mp3', 'wav', 'aac', 'flac', 'ogg'].contains(ext)) {
        trackType = TrackType.audio;
        clipType = ClipType.audio;
      } else if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        trackType = TrackType.overlay;
        clipType = ClipType.image;
      } else {
        trackType = TrackType.video;
        clipType = ClipType.video;
      }

      await addClip(
        trackType: trackType,
        clipType: clipType,
        sourcePath: path,
        startTime: 0,
        duration: 10, // Will be updated after probing
      );
    }

    _duration = _timeline.totalDuration;
    notifyListeners();

    return project;
  }
}

// ExportResult is defined in export_service.dart
// We need to import it or redefine here
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