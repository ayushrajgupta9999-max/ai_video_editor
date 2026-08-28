import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/timeline.dart';
import '../models/media.dart';
import '../services/storage/storage_service.dart';
import '../widgets/glass_card.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String? _exportError;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (BuildContext context, AppProvider provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildPreviewSection(provider),
                const SizedBox(height: 24),
                _buildFormatSection(provider),
                const SizedBox(height: 24),
                _buildQualitySection(provider),
                const SizedBox(height: 24),
                _buildAdvancedSection(provider),
                const SizedBox(height: 24),
                _buildOutputSection(provider),
                const SizedBox(height: 32),
                _buildExportButton(provider),
                if (_isExporting) ...<Widget>[
                  const SizedBox(height: 24),
                  _buildExportProgress(),
                ],
                if (_exportError != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
                if (_outputPath != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _buildSuccessMessage(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewSection(AppProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project Preview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Duration', _formatTime(provider.duration)),
              ),
              Expanded(
                child: _buildInfoItem('Video Tracks', provider.timeline.tracks.where((t) => t.type == TrackType.video).length.toString()),
              ),
              Expanded(
                child: _buildInfoItem('Audio Tracks', provider.timeline.tracks.where((t) => t.type == TrackType.audio).length.toString()),
              ),
              Expanded(
                child: _buildInfoItem('Total Clips', provider.timeline.tracks.expand((t) => t.clips).length.toString()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, color: Colors.white38, size: 48),
                  const SizedBox(height: 8),
                  Text('Timeline Preview', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
      ],
    );
  }

  Widget _buildFormatSection(AppProvider provider) {
    final settings = provider.exportSettings;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Format', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FormatOption(format: ContainerFormat.mp4, name: 'MP4 (H.264)', desc: 'Most compatible', icon: Icons.play_circle),
              _FormatOption(format: ContainerFormat.mov, name: 'MOV (ProRes)', desc: 'High quality editing', icon: Icons.movie),
              _FormatOption(format: ContainerFormat.mkv, name: 'MKV (H.265)', desc: 'Better compression', icon: Icons.video_file),
              _FormatOption(format: ContainerFormat.webm, name: 'WebM (VP9)', desc: 'Web optimized', icon: Icons.web),
            ].map((f) => _buildFormatOption(f.format, f.name, f.desc, f.icon, settings.format == f.format, () {
              provider.updateExportSettings(settings.copyWith(format: f.format));
            })).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(ContainerFormat format, String name, String desc, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : const Color(0xFF2D2D3A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySection(AppProvider provider) {
    final settings = provider.exportSettings;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quality', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQualityPreset('Low', '720p / 2 Mbps', settings.videoBitrate <= 3000, () {
                  provider.updateExportSettings(settings.copyWith(videoBitrate: 2000, frameRate: 30, preset: 'fast'));
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQualityPreset('Medium', '1080p / 8 Mbps', settings.videoBitrate > 3000 && settings.videoBitrate <= 10000, () {
                  provider.updateExportSettings(settings.copyWith(videoBitrate: 8000, frameRate: 30, preset: 'medium'));
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQualityPreset('High', '4K / 25 Mbps', settings.videoBitrate > 10000, () {
                  provider.updateExportSettings(settings.copyWith(videoBitrate: 25000, frameRate: 30, preset: 'slow'));
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          GlassSlider(
            label: 'Custom Video Bitrate (kbps)',
            value: settings.videoBitrate.toDouble(),
            min: 500,
            max: 50000,
            divisions: 99,
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(videoBitrate: value.round())),
          ),
          GlassSlider(
            label: 'Custom Audio Bitrate (kbps)',
            value: settings.audioBitrate.toDouble(),
            min: 64,
            max: 320,
            divisions: 13,
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(audioBitrate: value.round())),
          ),
          GlassSlider(
            label: 'Frame Rate',
            value: settings.frameRate.toDouble(),
            min: 15,
            max: 60,
            divisions: 15,
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(frameRate: value.round())),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityPreset(String name, String desc, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : const Color(0xFF2D2D3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection(AppProvider provider) {
    final settings = provider.exportSettings;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildDropdownSetting(
            label: 'Video Codec',
            value: settings.videoCodec.name,
            items: VideoCodec.values.map((e) => e.name).toList(),
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(videoCodec: VideoCodec.values.firstWhere((e) => e.name == value))),
          ),
          const SizedBox(height: 16),
          _buildDropdownSetting(
            label: 'Audio Codec',
            value: settings.audioCodec.name,
            items: AudioCodec.values.map((e) => e.name).toList(),
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(audioCodec: AudioCodec.values.firstWhere((e) => e.name == value))),
          ),
          const SizedBox(height: 16),
          GlassSlider(
            label: 'Audio Bitrate (kbps)',
            value: settings.audioBitrate.toDouble(),
            min: 64,
            max: 320,
            divisions: 13,
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(audioBitrate: value.round())),
          ),
          const SizedBox(height: 16),
          GlassSlider(
            label: 'Audio Volume',
            value: settings.audioVolume,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(audioVolume: value)),
          ),
          const SizedBox(height: 16),
          _buildDropdownSetting(
            label: 'Encoding Preset',
            value: settings.preset,
            items: ['ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow'],
            onChanged: (value) => provider.updateExportSettings(settings.copyWith(preset: value!)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF2D2D3A),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2D2D3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildOutputSection(AppProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Output Location', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GlassButton(
            icon: Icons.folder_open,
            label: 'Choose Output Folder',
            onPressed: _chooseOutputFolder,
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          if (_outputPath != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D3A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _outputPath!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseOutputFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && mounted) {
      setState(() => _outputPath = result);
    }
  }

  Widget _buildExportButton(AppProvider provider) {
    return GlassButton(
      icon: _isExporting ? Icons.hourglass_empty : Icons.file_download,
      label: _isExporting ? 'Exporting...' : 'Export Video',
      onPressed: _isExporting ? null : () => _exportVideo(provider),
      fullWidth: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Future<void> _exportVideo(AppProvider provider) async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportError = null;
    });

    try {
      final tempDir = await provider.mediaService.getTempDir();
      final outputPath = _outputPath ?? 
          '$tempDir/export_${DateTime.now().millisecondsSinceEpoch}.${provider.exportSettings.format.name}';
      
      final project = provider.currentProject ?? Project(
        name: 'Untitled Project',
        timeline: provider.timeline,
        exportSettings: provider.exportSettings,
      );

      final result = await provider.exportService.exportProject(
        project: project,
        settings: provider.exportSettings,
        outputPath: outputPath,
        onProgress: (ExportProgress progress) {
          if (mounted) {
            setState(() => _exportProgress = progress.progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
          if (result.success) {
            _outputPath = outputPath;
            _showSnackBar('Export completed: $outputPath');
          } else {
            _exportError = result.error ?? 'Export failed';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportError = 'Export error: $e';
        });
      }
    }
  }

  Widget _buildExportProgress() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _exportProgress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Text('${(_exportProgress * 100).toInt()}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rendering video... Please wait',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.red,
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_exportError!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.green,
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Video exported successfully!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green)),
          ),
          GlassButton(
            icon: Icons.open_in_new,
            label: 'Open Folder',
            onPressed: () {
              // TODO: Open folder
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E1E2E),
        behavior: SnackBarBehavior.floating,
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

class _FormatOption {
  final ContainerFormat format;
  final String name;
  final String desc;
  final IconData icon;

  const _FormatOption({
    required this.format,
    required this.name,
    required this.desc,
    required this.icon,
  });
}