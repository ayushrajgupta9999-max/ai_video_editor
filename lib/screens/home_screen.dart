import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/timeline.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<RecentProject> _recentProjects = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildActionButtons(),
                const SizedBox(height: 40),
                _buildRecentProjects(),
                const Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.video_library, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Video Editor',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  'AI-powered editing with human control',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildPrimaryAction(
          icon: Icons.add_circle_outline,
          title: 'New Project',
          subtitle: 'Start from scratch or import media',
          onTap: _createNewProject,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryAction(
                icon: Icons.folder_open,
                title: 'Open Project',
                onTap: _openProject,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSecondaryAction(
                icon: Icons.settings,
                title: 'Settings',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 20),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRecentProjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Projects', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_recentProjects.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, color: Colors.white38, size: 48),
                  const SizedBox(height: 16),
                  Text('No recent projects', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white60)),
                  const SizedBox(height: 8),
                  Text('Create a new project to get started', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentProjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = _recentProjects[index];
              return GlassCard(
                onTap: () => _openRecentProject(project),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D3A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.video_file, color: Colors.white38),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(project.lastModified, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white38),
                      onSelected: (value) {
                        if (value == 'delete') _deleteProject(project);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'AI + Human = Better Videos',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
      ),
    );
  }

  Future<void> _createNewProject() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', 'mp3', 'wav', 'aac', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final provider = context.read<AppProvider>();
      provider.newProject();
      
      for (final file in result.files) {
        if (file.path != null) {
          final ext = file.path!.split('.').last.toLowerCase();
          TrackType trackType;
          if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
            trackType = TrackType.video;
          } else if (['mp3', 'wav', 'aac'].contains(ext)) {
            trackType = TrackType.audio;
          } else {
            trackType = TrackType.overlay;
          }
          
          await provider.addClip(
            trackType: trackType,
            clipType: ClipType.values.firstWhere((e) => e.name == ext, orElse: () => ClipType.video),
            sourcePath: file.path!,
            startTime: 0,
            duration: 10,
          );
        }
      }
      
      if (mounted) {
        Navigator.pushNamed(context, '/editor');
      }
    } else {
      final provider = context.read<AppProvider>();
      provider.newProject();
      if (mounted) {
        Navigator.pushNamed(context, '/editor');
      }
    }
  }

  Future<void> _openProject() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      final provider = context.read<AppProvider>();
      await provider.loadProject(result.files.first.path!);
      if (mounted) {
        Navigator.pushNamed(context, '/editor');
      }
    }
  }

  void _openRecentProject(RecentProject project) {
    // TODO: Load project
  }

  void _deleteProject(RecentProject project) {
    // TODO: Delete project
  }
}

class RecentProject {
  final String name;
  final String path;
  final String lastModified;
  final String thumbnail;

  RecentProject({
    required this.name,
    required this.path,
    required this.lastModified,
    required this.thumbnail,
  });
}