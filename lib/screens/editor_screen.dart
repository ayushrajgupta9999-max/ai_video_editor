import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/timeline.dart';
import '../models/ai_models.dart';
import '../widgets/glass_card.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/video_preview.dart';
import '../widgets/ai_panel.dart';
import '../widgets/track_header.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;
  bool _showAiPanel = true;
  double _previewHeight = 0.45;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final provider = context.read<AppProvider>();
    final videoClips = provider.timeline.tracks
        .where((t) => t.type == TrackType.video && !t.isMuted)
        .expand((t) => t.clips)
        .toList();

    if (videoClips.isNotEmpty && videoClips.first.sourcePath.isNotEmpty) {
      _videoController = VideoPlayerController.file(File(videoClips.first.sourcePath));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            color: const Color(0xFF0F0F1A),
            child: Column(
              children: [
                _buildTopBar(provider),
                Expanded(
                  child: Row(
                    children: [
                      _buildLeftPanel(provider),
                      _buildCenterPanel(provider),
                      if (_showAiPanel) _buildRightPanel(provider),
                    ],
                  ),
                ),
                _buildTimeline(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(AppProvider provider) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Home',
          ),
          const SizedBox(width: 8),
          Text(
            provider.currentProjectPath?.split('/').last ?? 'Untitled Project',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          _buildTopBarActions(provider),
        ],
      ),
    );
  }

  Widget _buildTopBarActions(AppProvider provider) {
    return Row(
      children: [
        IconButton(
          icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
          onPressed: () {
            provider.togglePlay();
            if (provider.isPlaying) {
              _videoController?.play();
            } else {
              _videoController?.pause();
            }
          },
          tooltip: provider.isPlaying ? 'Pause' : 'Play',
        ),
        IconButton(
          icon: const Icon(Icons.stop, color: Colors.white),
          onPressed: () {
            provider.setPlaying(false);
            provider.setPlayheadPosition(0);
            _videoController?.seekTo(Duration.zero);
          },
          tooltip: 'Stop',
        ),
        const SizedBox(width: 8),
        GlassButton(
          icon: Icons.auto_awesome,
          label: 'AI Tools',
          onPressed: () => setState(() => _showAiPanel = !_showAiPanel),
          isSelected: _showAiPanel,
        ),
        const SizedBox(width: 8),
        GlassButton(
          icon: Icons.file_download,
          label: 'Export',
          onPressed: () => Navigator.pushNamed(context, '/export'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLeftPanel(AppProvider provider) {
    return SizedBox(
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMediaTab(provider),
                  _buildEffectsTab(provider),
                  _buildTextTab(provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: GlassTabBar(
        tabs: ['Media', 'Effects', 'Text'],
        icons: [Icons.video_library, Icons.filter_frames, Icons.text_fields],
        selectedIndex: _tabController.index,
        onTap: (index) => _tabController.animateTo(index),
      ),
    );
  }

  Widget _buildMediaTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassButton(
            icon: Icons.add,
            label: 'Import Media',
            onPressed: _importMedia,
            fullWidth: true,
          ),
          const SizedBox(height: 16),
          Text('Project Media', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          _buildMediaList(provider),
        ],
      ),
    );
  }

  Widget _buildMediaList(AppProvider provider) {
    final allClips = provider.timeline.tracks.expand((t) => t.clips).toList();
    final uniquePaths = allClips.map((c) => c.sourcePath).toSet().toList();

    if (uniquePaths.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.video_library_outlined, color: Colors.white38, size: 48),
              const SizedBox(height: 16),
              Text('No media imported', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: uniquePaths.map((path) {
        final name = path.split('/').last;
        final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => name.endsWith(ext));
        final isAudio = ['mp3', 'wav', 'aac'].any((ext) => name.endsWith(ext));
        final isImage = ['jpg', 'jpeg', 'png', 'gif'].any((ext) => name.endsWith(ext));

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D3A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVideo ? Icons.videocam : isAudio ? Icons.audiotrack : Icons.image,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      isVideo ? 'Video' : isAudio ? 'Audio' : 'Image',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 24),
                onPressed: () => _addToTimeline(path, isVideo ? TrackType.video : isAudio ? TrackType.audio : TrackType.overlay),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEffectsTab(AppProvider provider) {
    final effects = [
      {'name': 'Color Grade', 'icon': Icons.color_lens, 'category': 'Color'},
      {'name': 'Brightness/Contrast', 'icon': Icons.brightness_6, 'category': 'Color'},
      {'name': 'Saturation', 'icon': Icons.colorize, 'category': 'Color'},
      {'name': 'Vignette', 'icon': Icons.circle_outlined, 'category': 'Style'},
      {'name': 'Film Grain', 'icon': Icons.grain, 'category': 'Style'},
      {'name': 'Glitch', 'icon': Icons.broken_image, 'category': 'Style'},
      {'name': 'Blur', 'icon': Icons.blur_on, 'category': 'Transform'},
      {'name': 'Sharpen', 'icon': Icons.tune, 'category': 'Transform'},
      {'name': 'Stabilize', 'icon': Icons.video_stable, 'category': 'Transform'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Video Effects', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: effects.map((effect) {
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _applyEffect(effect['name'] as String),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(effect['icon'] as IconData, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(effect['name'] as String, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Transitions', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Cut', 'Fade', 'Dissolve', 'Slide', 'Wipe', 'Zoom'].map((transition) {
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _applyTransition(transition),
                child: Text(transition, style: Theme.of(context).textTheme.bodyMedium),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassButton(
            icon: Icons.text_fields,
            label: 'Add Text Layer',
            onPressed: _addTextLayer,
            fullWidth: true,
          ),
          const SizedBox(height: 16),
          Text('Text Templates', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Title', 'Lower Third', 'Caption', 'Credits', 'Subtitle', 'Kinetic'].map((template) {
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _addTextTemplate(template),
                child: Text(template, style: Theme.of(context).textTheme.bodyMedium),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPanel(AppProvider provider) {
    return Expanded(
      child: Container(
        color: const Color(0xFF0F0F1A),
        child: Column(
          children: [
            Expanded(
              flex: (_previewHeight * 100).round(),
              child: VideoPreview(
                controller: _videoController,
                playheadPosition: provider.playheadPosition,
                duration: provider.duration,
                onSeek: (position) {
                  provider.setPlayheadPosition(position);
                  _videoController?.seekTo(Duration(milliseconds: (position * 1000).round()));
                },
              ),
            ),
            Container(
              height: 4,
              color: Colors.white.withOpacity(0.1),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _previewHeight = (_previewHeight - details.delta.dy / MediaQuery.of(context).size.height).clamp(0.25, 0.75);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel(AppProvider provider) {
    return SizedBox(
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: AiPanel(
          onTaskComplete: (task) => _handleAiTaskComplete(provider, task),
        ),
      ),
    );
  }

  Widget _buildTimeline(AppProvider provider) {
    return SizedBox(
      height: 200,
      child: TimelineWidget(
        timeline: provider.timeline,
        playheadPosition: provider.playheadPosition,
        duration: provider.duration,
        zoomLevel: provider.timeline.zoomLevel,
        scrollOffset: provider.timeline.scrollOffset,
        onSeek: (position) {
          provider.setPlayheadPosition(position);
          _videoController?.seekTo(Duration(milliseconds: (position * 1000).round()));
        },
        onZoomChanged: (zoom) => provider.setZoomLevel(zoom),
        onScrollChanged: (offset) => provider.setScrollOffset(offset),
        onClipTap: (trackId, clipId) => provider.selectClip(trackId, clipId),
        onClipDrag: (trackId, clipId, newStart) => provider.moveClip(trackId, clipId, newStart),
        onClipTrim: (trackId, clipId, trimStart, trimEnd) => provider.trimClip(trackId, clipId, trimStart: trimStart, trimEnd: trimEnd),
        onClipSplit: (trackId, clipId, splitTime) => provider.splitClip(trackId, clipId, splitTime),
        onTrackMute: (trackId) => provider.toggleTrackMute(trackId),
        onTrackLock: (trackId) => provider.toggleTrackLock(trackId),
        onAddTrack: (type) => provider.addTrack(type),
      ),
    );
  }

  Future<void> _importMedia() async {
    // TODO: Implement media import
  }

  void _addToTimeline(String path, TrackType trackType) {
    // TODO: Add to timeline
  }

  void _applyEffect(String effectName) {
    // TODO: Apply effect to selected clip
  }

  void _applyTransition(String transitionName) {
    // TODO: Apply transition
  }

  void _addTextLayer() {
    // TODO: Add text layer
  }

  void _addTextTemplate(String template) {
    // TODO: Add text template
  }

  void _handleAiTaskComplete(AppProvider provider, AiTask task) {
    // TODO: Handle AI task completion
  }
}