// Storage service for managing projects and media
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/media.dart';
import '../models/timeline.dart';
import '../core/errors/media_errors.dart';

const _uuid = Uuid();

class StorageService {
  final SharedPreferences _prefs;
  String? _projectsDir;
  String? _tempDir;

  StorageService(this._prefs);

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _projectsDir = '${appDir.path}/projects';
    _tempDir = '${appDir.path}/temp';

    await Directory(_projectsDir!).create(recursive: true);
    await Directory(_tempDir!).create(recursive: true);
  }

  String get projectsDir => _projectsDir!;
  String get tempDir => _tempDir!;

  // Project management
  Future<String> saveProject(Project project) async {
    final projectDir = '$projectsDir/${project.id}';
    await Directory(projectDir).create(recursive: true);

    final projectFile = File('$projectDir/project.json');
    final json = project.toJson();
    await projectFile.writeAsString(const JsonEncoder.withIndent('  ').convert(json));

    // Update recent projects list
    await _updateRecentProjects(project.id);

    return project.id;
  }

  Future<Project?> loadProject(String projectId) async {
    final projectFile = File('$projectsDir/$projectId/project.json');
    if (!await projectFile.exists()) return null;

    final json = jsonDecode(await projectFile.readAsString());
    return Project.fromJson(json);
  }

  Future<List<ProjectSummary>> getRecentProjects({int limit = 10}) async {
    final json = _prefs.getStringList('recent_projects') ?? [];
    final summaries = <ProjectSummary>[];

    for (final id in json) {
      final project = await loadProject(id);
      if (project != null) {
        summaries.add(ProjectSummary(
          id: project.id,
          name: project.name,
          createdAt: project.createdAt,
          updatedAt: project.updatedAt,
          thumbnailPath: project.thumbnailPath,
          duration: project.timeline.totalDuration,
        ));
      }
    }

    return summaries.take(limit).toList();
  }

  Future<void> deleteProject(String projectId) async {
    final projectDir = Directory('$projectsDir/$projectId');
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }

    final recent = _prefs.getStringList('recent_projects') ?? [];
    recent.remove(projectId);
    await _prefs.setStringList('recent_projects', recent);
  }

  Future<void> _updateRecentProjects(String projectId) async {
    var recent = _prefs.getStringList('recent_projects') ?? [];
    recent.remove(projectId);
    recent.insert(0, projectId);
    if (recent.length > 20) recent = recent.take(20).toList();
    await _prefs.setStringList('recent_projects', recent);
  }

  // Media management
  Future<String> copyMediaToProject(String projectId, String sourcePath) async {
    final projectDir = '$projectsDir/$projectId/media';
    await Directory(projectDir).create(recursive: true);

    final fileName = '${_uuid.v4()}${_getExtension(sourcePath)}';
    final destPath = '$projectDir/$fileName';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);

    return destPath;
  }

  String _getExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    return dotIndex >= 0 ? path.substring(dotIndex) : '';
  }

  // Temporary files
  Future<String> createTempFile({String extension = '.tmp'}) async {
    return '$tempDir/${_uuid.v4()}$extension';
  }

  Future<void> cleanupTempFiles({Duration maxAge = const Duration(hours: 24)}) async {
    if (!await Directory(_tempDir!).exists()) return;

    final cutoff = DateTime.now().subtract(maxAge);
    final files = Directory(_tempDir!).listSync(recursive: true);

    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoff)) {
          await file.delete();
        }
      }
    }
  }

  // Settings
  Future<void> saveSetting(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getSetting(String key) {
    return _prefs.getString(key);
  }

  Future<void> saveSettingBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getSettingBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> saveSettingInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getSettingInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> saveSettingDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  double? getSettingDouble(String key) {
    return _prefs.getDouble(key);
  }
}

class Project {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  final Timeline timeline;
  final ExportSettings exportSettings;
  final Map<String, dynamic> metadata;
  String? thumbnailPath;

  Project({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Timeline? timeline,
    ExportSettings? exportSettings,
    this.metadata = const {},
    this.thumbnailPath,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        timeline = timeline ?? Timeline(),
        exportSettings = exportSettings ?? ExportSettings();

  Project copyWith({
    String? name,
    Timeline? timeline,
    ExportSettings? exportSettings,
    Map<String, dynamic>? metadata,
    String? thumbnailPath,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      timeline: timeline ?? this.timeline,
      exportSettings: exportSettings ?? this.exportSettings,
      metadata: metadata ?? this.metadata,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'timeline': timeline.toJson(),
        'exportSettings': exportSettings.toJson(),
        'metadata': metadata,
        'thumbnailPath': thumbnailPath,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        timeline: Timeline.fromJson(json['timeline']),
        exportSettings: ExportSettings.fromJson(json['exportSettings']),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        thumbnailPath: json['thumbnailPath'],
      );
}

class ProjectSummary {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final Duration duration;

  ProjectSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    required this.duration,
  });
}