import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/timeline.dart';
import '../widgets/glass_card.dart';
import '../widgets/track_header.dart';

class TimelineWidget extends StatefulWidget {
  final Timeline timeline;
  final double playheadPosition;
  final double duration;
  final double zoomLevel;
  final double scrollOffset;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onScrollChanged;
  final Function(String trackId, String clipId) onClipTap;
  final Function(String trackId, String clipId, double newStart) onClipDrag;
  final Function(String trackId, String clipId, double trimStart, double trimEnd) onClipTrim;
  final Function(String trackId, String clipId, double splitTime) onClipSplit;
  final Function(String trackId) onTrackMute;
  final Function(String trackId) onTrackLock;
  final Function(TrackType) onAddTrack;

  const TimelineWidget({
    super.key,
    required this.timeline,
    required this.playheadPosition,
    required this.duration,
    required this.zoomLevel,
    required this.scrollOffset,
    required this.onSeek,
    required this.onZoomChanged,
    required this.onScrollChanged,
    required this.onClipTap,
    required this.onClipDrag,
    required this.onClipTrim,
    required this.onClipSplit,
    required this.onTrackMute,
    required this.onTrackLock,
    required this.onAddTrack,
  });

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  late ScrollController _horizontalController;
  late ScrollController _verticalController;
  bool _isDraggingPlayhead = false;
  String? _draggedClipTrackId;
  String? _draggedClipId;
  double _dragStartX = 0;
  double _dragClipStartTime = 0;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _horizontalController.jumpTo(widget.scrollOffset);
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: Row(
        children: [
          _buildTrackHeaders(),
          Expanded(
            child: GestureDetector(
              onPanStart: (details) => _onPanStart(details),
              onPanUpdate: (details) => _onPanUpdate(details),
              onPanEnd: (details) => _onPanEnd(details),
              child: Listener(
                onPointerSignal: (event) => _onPointerSignal(event),
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  thickness: 8,
                  radius: const Radius.circular(4),
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(4),
                      child: SingleChildScrollView(
                        controller: _verticalController,
                        scrollDirection: Axis.vertical,
                        physics: const ClampingScrollPhysics(),
                        child: _buildTimelineContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackHeaders() {
    return SizedBox(
      width: 200,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: ListView(
          controller: _verticalController,
          children: [
            _buildRuler(),
            ...widget.timeline.tracks.map((track) => TrackHeader(
              track: track,
              onMute: () => widget.onTrackMute(track.id),
              onLock: () => widget.onTrackLock(track.id),
              onAddTrack: () => widget.onAddTrack(track.type),
            )),
            _buildAddTrackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRuler() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Timeline', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54)),
          Text(_formatTime(widget.duration), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildAddTrackButton() {
    return GlassCard(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      onTap: _showAddTrackDialog,
      child: Column(
        children: [
          Icon(Icons.add, color: Colors.white38, size: 24),
          const SizedBox(height: 4),
          Text('Add Track', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }

  void _showAddTrackDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Track', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: TrackType.values.map((type) {
                return GlassButton(
                  icon: _getTrackIcon(type),
                  label: type.name.toUpperCase(),
                  onPressed: () {
                    widget.onAddTrack(type);
                    Navigator.pop(context);
                  },
                  fullWidth: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTrackIcon(TrackType type) {
    switch (type) {
      case TrackType.video:
        return Icons.videocam;
      case TrackType.audio:
        return Icons.audiotrack;
      case TrackType.text:
        return Icons.text_fields;
      case TrackType.overlay:
        return Icons.layers;
    }
  }

  Widget _buildTimelineContent() {
    final contentWidth = math.max(widget.duration * 100 * widget.zoomLevel, 800.0);
    final playheadX = widget.playheadPosition * 100 * widget.zoomLevel;

    return SizedBox(
      width: contentWidth,
      child: Stack(
        children: [
          _buildTimeRuler(contentWidth),
          _buildGrid(contentWidth),
          ...widget.timeline.tracks.asMap().entries.map((entry) {
            final trackIndex = entry.key;
            final track = entry.value;
            return _buildTrack(track, trackIndex, contentWidth);
          }),
          _buildPlayhead(playheadX),
        ],
      ),
    );
  }

  Widget _buildTimeRuler(double width) {
    return Container(
      height: 40,
      color: const Color(0xFF1A1A2E),
      child: CustomPaint(
        size: Size(width, 40),
        painter: _TimeRulerPainter(
          duration: widget.duration,
          zoomLevel: widget.zoomLevel,
          scrollOffset: widget.scrollOffset,
        ),
      ),
    );
  }

  Widget _buildGrid(double width) {
    return Positioned.fill(
      top: 40,
      child: CustomPaint(
        size: Size(width, widget.timeline.tracks.length * 60),
        painter: _GridPainter(
          duration: widget.duration,
          zoomLevel: widget.zoomLevel,
          trackCount: widget.timeline.tracks.length,
        ),
      ),
    );
  }

  Widget _buildTrack(TimelineTrack track, int trackIndex, double width) {
    final trackY = (40 + trackIndex * 60).toDouble();

    return Positioned(
      top: trackY,
      left: 0,
      right: 0,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          color: trackIndex.isEven ? const Color(0xFF1A1A2E) : const Color(0xFF1E1E2E),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Stack(
          children: [
            ...track.clips.map((clip) => _buildClip(clip, track.id, trackIndex, width)),
            if (track.isMuted)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(child: Icon(Icons.volume_off, color: Colors.white38, size: 24)),
                ),
              ),
            if (track.isLocked)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Center(child: Icon(Icons.lock, color: Colors.white38, size: 24)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClip(TimelineClip clip, String trackId, int trackIndex, double width) {
    final clipX = clip.startTime * 100 * widget.zoomLevel;
    final clipWidth = clip.duration * 100 * widget.zoomLevel;
    final trackY = (trackIndex * 60).toDouble();

    return Positioned(
      left: clipX,
      top: 4,
      width: math.max(clipWidth, 40.0),
      height: 52,
      child: GestureDetector(
        onTap: () => widget.onClipTap(trackId, clip.id),
        onPanStart: (details) {
          if (!clip.isSelected) return;
          _draggedClipTrackId = trackId;
          _draggedClipId = clip.id;
          _dragStartX = details.globalPosition.dx;
          _dragClipStartTime = clip.startTime;
        },
        onPanUpdate: (details) {
          if (_draggedClipId == null) return;
          final deltaX = details.globalPosition.dx - _dragStartX;
          final deltaTime = deltaX / (100 * widget.zoomLevel);
          final newStart = math.max(_dragClipStartTime + deltaTime, 0.0);
          widget.onClipDrag(trackId, _draggedClipId!, newStart);
        },
        onPanEnd: (details) {
          _draggedClipTrackId = null;
          _draggedClipId = null;
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: clip.isSelected
                ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                : LinearGradient(
                    colors: _getClipColors(clip),
                  ),
            borderRadius: BorderRadius.circular(4),
            border: clip.isSelected
                ? Border.all(color: Colors.white, width: 2)
                : Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: clip.isSelected
                ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: Stack(
            children: [
              if (clip.clipType == ClipType.video || clip.clipType == ClipType.image)
                _buildVideoClipThumbnail(clip),
              if (clip.clipType == ClipType.audio)
                _buildAudioWaveform(clip),
              if (clip.clipType == ClipType.text)
                _buildTextClipPreview(clip),
              Positioned(
                left: 4,
                right: 4,
                top: 2,
                child: Text(
                  clip.properties['text'] ?? clip.sourcePath.split('/').last,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Positioned(
                bottom: 2,
                left: 4,
                child: Text(
                  '${_formatTime(clip.startTime)} - ${_formatTime(clip.endTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 8),
                ),
              ),
              if (clip.isAiGenerated)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                  ),
                ),
              _buildTrimHandles(clip),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getClipColors(TimelineClip clip) {
    switch (clip.clipType) {
      case ClipType.video:
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
      case ClipType.audio:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case ClipType.image:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case ClipType.text:
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case ClipType.generated:
        return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
    }
  }

  Widget _buildVideoClipThumbnail(TimelineClip clip) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getClipColors(clip).map((c) => c.withOpacity(0.3)).toList(),
        ),
      ),
    );
  }

  Widget _buildAudioWaveform(TimelineClip clip) {
    return CustomPaint(
      size: const Size(double.infinity, 52),
      painter: _WaveformPainter(color: _getClipColors(clip).first),
    );
  }

  Widget _buildTextClipPreview(TimelineClip clip) {
    return Center(
      child: Text(
        clip.properties['text'] ?? 'Text',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTrimHandles(TimelineClip clip) {
    return Row(
      children: [
        if (clip.trimStart > 0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
              ),
            ),
          ),
        if (clip.trimEnd > 0)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayhead(double playheadX) {
    return Positioned(
      top: 40,
      left: playheadX,
      bottom: 0,
      child: GestureDetector(
        onPanStart: (details) => _isDraggingPlayhead = true,
        onPanUpdate: (details) {
          if (!_isDraggingPlayhead) return;
          final newX = (playheadX + details.delta.dx).clamp(0, widget.duration * 100 * widget.zoomLevel);
          final newTime = newX / (100 * widget.zoomLevel);
          widget.onSeek(newTime);
        },
        onPanEnd: (details) => _isDraggingPlayhead = false,
        child: Container(
          width: 2,
          color: const Color(0xFF6366F1),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.5), blurRadius: 8)],
                  ),
                ),
              ),
              Positioned(
                top: -36,
                left: -30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatTime(widget.playheadPosition),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _horizontalController.jumpTo(_horizontalController.offset);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _horizontalController.jumpTo(_horizontalController.offset - details.delta.dx);
    widget.onScrollChanged(_horizontalController.offset);
  }

  void _onPanEnd(DragEndDetails details) {}

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy != 0) {
        _verticalController.jumpTo(_verticalController.offset + event.scrollDelta.dy);
      }
      if (event.scrollDelta.dx != 0) {
        _horizontalController.jumpTo(_horizontalController.offset + event.scrollDelta.dx);
        widget.onScrollChanged(_horizontalController.offset);
      }
      if (event.kind == PointerDeviceKind.mouse && event.buttons == 0) {
        if (event.scrollDelta.dy != 0 && (event as dynamic).control == true) {
          final newZoom = (widget.zoomLevel * (1 - event.scrollDelta.dy * 0.001)).clamp(0.1, 100.0);
          widget.onZoomChanged(newZoom);
        }
      }
    }
  }

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).floor().toString().padLeft(2, '0');
    final ms = ((seconds * 100) % 100).floor().toString().padLeft(2, '0');
    return '$mins:$secs.$ms';
  }
}

class _TimeRulerPainter extends CustomPainter {
  final double duration;
  final double zoomLevel;
  final double scrollOffset;

  _TimeRulerPainter({required this.duration, required this.zoomLevel, required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    final majorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const pxPerSec = 100.0;
    const majorInterval = 5.0;

    for (double sec = 0; sec <= duration; sec += 1.0) {
      final x = sec * pxPerSec * zoomLevel;
      if (x < -50 || x > size.width + 50) continue;

      if (sec % majorInterval == 0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
        _drawText(canvas, _formatTime(sec), x, size.height - 4, majorPaint.color);
      } else {
        canvas.drawLine(Offset(x, size.height - 10), Offset(x, size.height), paint);
      }
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 9)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height));
  }

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).floor().toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GridPainter extends CustomPainter {
  final double duration;
  final double zoomLevel;
  final int trackCount;

  _GridPainter({required this.duration, required this.zoomLevel, required this.trackCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const pxPerSec = 100.0;
    const majorInterval = 5.0;

    for (double sec = 0; sec <= duration; sec += 1.0) {
      final x = sec * pxPerSec * zoomLevel;
      if (x < -50 || x > size.width + 50) continue;

      if (sec % majorInterval == 0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint..color = Colors.white.withOpacity(0.05));
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    for (int i = 1; i < trackCount; i++) {
      final y = i * 60.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint..color = Colors.white.withOpacity(0.05));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WaveformPainter extends CustomPainter {
  final Color color;

  _WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;

    for (int x = 0; x < size.width; x += 2) {
      final amplitude = math.sin(x * 0.1) * (size.height * 0.3);
      final y = centerY + amplitude;
      if (x == 0) {
        path.moveTo(x.toDouble(), y);
      } else {
        path.lineTo(x.toDouble(), y);
      }
    }

    canvas.drawPath(path, paint);

    final path2 = Path();
    for (int x = 0; x < size.width; x += 2) {
      final amplitude = math.sin(x * 0.1 + 3.14) * (size.height * 0.3);
      final y = centerY + amplitude;
      if (x == 0) {
        path2.moveTo(x.toDouble(), y);
      } else {
        path2.lineTo(x.toDouble(), y);
      }
    }
    canvas.drawPath(path2, paint..color = color.withOpacity(0.4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}