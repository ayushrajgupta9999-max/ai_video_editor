import 'package:flutter/material.dart';
import '../models/timeline.dart';
import '../widgets/glass_card.dart';

class TrackHeader extends StatelessWidget {
  final TimelineTrack track;
  final VoidCallback onMute;
  final VoidCallback onLock;
  final VoidCallback onAddTrack;

  const TrackHeader({
    super.key,
    required this.track,
    required this.onMute,
    required this.onLock,
    required this.onAddTrack,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getTrackColor(track.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getTrackIcon(track.type), color: _getTrackColor(track.type), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${track.type.name.toUpperCase()} ${track.index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${track.clips.length} clips',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(track.isMuted ? Icons.volume_off : Icons.volume_up, color: track.isMuted ? Colors.white38 : Colors.white, size: 20),
            onPressed: onMute,
            tooltip: track.isMuted ? 'Unmute' : 'Mute',
          ),
          IconButton(
            icon: Icon(track.isLocked ? Icons.lock : Icons.lock_open, color: track.isLocked ? Colors.white38 : Colors.white, size: 20),
            onPressed: onLock,
            tooltip: track.isLocked ? 'Unlock' : 'Lock',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  // TODO: Delete track
                  break;
                case 'duplicate':
                  // TODO: Duplicate track
                  break;
                case 'clear':
                  // TODO: Clear track
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete Track')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Track')),
              const PopupMenuItem(value: 'clear', child: Text('Clear Track')),
            ],
          ),
        ],
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

  Color _getTrackColor(TrackType type) {
    switch (type) {
      case TrackType.video:
        return const Color(0xFF3B82F6);
      case TrackType.audio:
        return const Color(0xFF10B981);
      case TrackType.text:
        return const Color(0xFF8B5CF6);
      case TrackType.overlay:
        return const Color(0xFFF59E0B);
    }
  }
}