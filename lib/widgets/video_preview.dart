import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/glass_card.dart';

class VideoPreview extends StatefulWidget {
  final VideoPlayerController? controller;
  final double playheadPosition;
  final double duration;
  final ValueChanged<double> onSeek;

  const VideoPreview({
    super.key,
    this.controller,
    required this.playheadPosition,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  bool _showControls = true;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _hideControlsTimer();
  }

  void _hideControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      onPanUpdate: (details) {
        if (widget.duration > 0) {
          final delta = details.delta.dx / MediaQuery.of(context).size.width;
          final newPosition = (widget.playheadPosition + delta * widget.duration).clamp(0.0, widget.duration);
          widget.onSeek(newPosition);
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoPlayer(),
            if (_showControls) _buildControls(),
            _buildTimeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text('No video loaded', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white54)),
            const SizedBox(height: 8),
            Text('Import media or generate with AI', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38)),
          ],
        ),
      );
    }

    return VideoPlayer(widget.controller!);
  }

  Widget _buildControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GlassButton(
                      icon: widget.controller?.value.isPlaying == true ? Icons.pause : Icons.play_arrow,
                      onPressed: () {
                        if (widget.controller?.value.isPlaying == true) {
                          widget.controller?.pause();
                        } else {
                          widget.controller?.play();
                        }
                        setState(() {});
                      },
                      padding: const EdgeInsets.all(16),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF6366F1),
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: const Color(0xFF6366F1),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: widget.playheadPosition.clamp(0.0, widget.duration),
                              min: 0,
                              max: widget.duration > 0 ? widget.duration : 1.0,
                              onChanged: widget.onSeek,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(widget.playheadPosition), style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Text(_formatTime(widget.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GlassButton(
                      icon: Icons.volume_up,
                      onPressed: () => setState(() => _volume = _volume > 0 ? 0 : 1.0),
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  '${_formatTime(widget.playheadPosition)} / ${_formatTime(widget.duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeIndicator() {
    if (widget.duration <= 0) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 3,
      child: CustomPaint(
        painter: _ProgressPainter(
          progress: widget.playheadPosition / widget.duration,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '0:00';
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).floor().toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), bgPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width * progress, size.height / 2), fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}