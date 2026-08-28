// Export service for managing video exports
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/media.dart';
import '../models/timeline.dart';
import '../services/media/media_processing_service.dart';
import '../core/errors/media_errors.dart';

const _uuid = Uuid();

class ExportService {
  final MediaProcessingService _mediaService;
  final StorageService _storageService;

  ExportService(this._mediaService, this._storageService);

  Future<ExportResult> exportProject({
    required Project project,
    required ExportSettings settings,
    required String outputPath,
    void Function(ExportProgress)? onProgress,
  }) async {
    final exportId = _uuid.v4();
    final startTime = DateTime.now();

    try {
      // Build export request from project
      final request = _buildExportRequest(project, settings, outputPath);

      // Execute export
      await _mediaService.export(
        request: request,
        onProgress: (progress) {
          onProgress?.call(ExportProgress(
            exportId: exportId,
            progress: progress.progress,
            stage: progress.stage,
            elapsedTime: DateTime.now().difference(startTime),
            estimatedRemaining: progress.estimatedRemaining,
          ));
        },
      );

      final duration = DateTime.now().difference(startTime);
      return ExportResult(
        exportId: exportId,
        success: true,
        outputPath: outputPath,
        duration: duration,
      );
    } catch (e) {
      return ExportResult(
        exportId: exportId,
        success: false,
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  ExportRequest _buildExportRequest(Project project, ExportSettings settings, String outputPath) {
    final videoTracks = <ExportTrack>[];
    final audioTracks = <ExportTrack>[];

    for (final track in project.timeline.tracks) {
      for (final clip in track.clips) {
        final exportTrack = ExportTrack(
          sourcePath: clip.sourcePath,
          startTime: Duration(milliseconds: (clip.startTime * 1000).round()),
          duration: Duration(milliseconds: (clip.duration * 1000).round()),
          trimStart: clip.trimStart > 0 ? Duration(milliseconds: (clip.trimStart * 1000).round()) : null,
          trimEnd: clip.trimEnd > 0 ? Duration(milliseconds: (clip.trimEnd * 1000).round()) : null,
          properties: clip.properties,
          filters: clip.keyframes.map((k) => ExportFilter(
            name: k.property,
            parameters: k.value is Map ? Map<String, dynamic>.from(k.value) : {'value': k.value},
            startTime: Duration(milliseconds: (k.time * 1000).round()),
            endTime: Duration(milliseconds: (k.time * 1000).round()),
          )).toList(),
        );

        if (track.type == TrackType.video) {
          videoTracks.add(exportTrack);
        } else if (track.type == TrackType.audio) {
          audioTracks.add(exportTrack);
        }
      }
    }

    return ExportRequest(
      videoTracks: videoTracks,
      audioTracks: audioTracks,
      settings: settings,
      outputPath: outputPath,
    );
  }

  Future<ExportResult> exportClip({
    required String inputPath,
    required Duration start,
    required Duration duration,
    required ExportSettings settings,
    required String outputPath,
    void Function(ExportProgress)? onProgress,
  }) async {
    final exportId = _uuid.v4();
    final startTime = DateTime.now();

    try {
      await _mediaService.convert(
        inputPath: inputPath,
        outputPath: outputPath,
        format: settings.format,
        videoCodec: settings.videoCodec,
        audioCodec: settings.audioCodec,
        videoBitrate: settings.videoBitrate,
        audioBitrate: settings.audioBitrate,
        width: settings.width,
        height: settings.height,
        frameRate: settings.frameRate,
        preset: settings.preset,
        onProgress: (progress) {
          onProgress?.call(ExportProgress(
            exportId: exportId,
            progress: progress.progress,
            stage: progress.stage,
            elapsedTime: DateTime.now().difference(startTime),
            estimatedRemaining: progress.estimatedRemaining,
          ));
        },
      );

      final duration = DateTime.now().difference(startTime);
      return ExportResult(
        exportId: exportId,
        success: true,
        outputPath: outputPath,
        duration: duration,
      );
    } catch (e) {
      return ExportResult(
        exportId: exportId,
        success: false,
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  ExportRequest _buildExportRequest(Project project, ExportSettings settings, String outputPath) {
    final videoTracks = <ExportTrack>[];
    final audioTracks = <ExportTrack>[];

    for (final track in project.timeline.tracks) {
      for (final clip in track.clips) {
        final exportTrack = ExportTrack(
          sourcePath: clip.sourcePath,
          startTime: Duration(milliseconds: (clip.startTime * 1000).round()),
          duration: Duration(milliseconds: (clip.duration * 1000).round()),
          trimStart: clip.trimStart > 0 ? Duration(milliseconds: (clip.trimStart * 1000).round()) : null,
          trimEnd: clip.trimEnd > 0 ? Duration(milliseconds: (clip.trimEnd * 1000).round()) : null,
          properties: clip.properties,
          filters: clip.keyframes.map((k) => ExportFilter(
            name: k.property,
            parameters: k.value is Map ? Map<String, dynamic>.from(k.value) : {'value': k.value},
            startTime: Duration(milliseconds: (k.time * 1000).round()),
            endTime: Duration(milliseconds: (k.time * 1000).round()),
          )).toList(),
        );

        if (track.type == TrackType.video) {
          videoTracks.add(exportTrack);
        } else if (track.type == TrackType.audio) {
          audioTracks.add(exportTrack);
        }
      }
    }

    return ExportRequest(
      videoTracks: videoTracks,
      audioTracks: audioTracks,
      settings: settings,
      outputPath: outputPath,
    );
  }
}