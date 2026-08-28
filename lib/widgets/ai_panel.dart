import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ai_models.dart';
import '../models/timeline.dart';
import '../widgets/glass_card.dart';

class AiPanel extends StatefulWidget {
  final Function(AiTask) onTaskComplete;

  const AiPanel({super.key, required this.onTaskComplete});

  @override
  State<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<AiPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AiTaskType? _selectedTask;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _buildHeader(context, provider),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAutomationTab(context, provider),
                  _buildTasksTab(context, provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text('AI Automation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          PopupMenuButton<AiProvider>(
            icon: const Icon(Icons.cloud_outlined, color: Colors.white54),
            onSelected: (provider) => _switchProvider(context, provider),
            itemBuilder: (context) => AiProvider.values.map((p) {
              return PopupMenuItem(value: p, child: Text(_getProviderName(p)));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassTabBar(
        tabs: ['Automate', 'Tasks'],
        icons: [Icons.auto_fix_high, Icons.list_alt],
        selectedIndex: _tabController.index,
        onTap: (index) => _tabController.animateTo(index),
      ),
    );
  }

  Widget _buildAutomationTab(BuildContext context, AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(context, provider),
          const SizedBox(height: 24),
          _buildSmartWorkflows(context, provider),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppProvider provider) {
    final actions = [
      {'title': 'Auto-Transcribe', 'subtitle': 'Generate captions from speech', 'icon': Icons.closed_caption, 'task': AiTaskType.transcribe},
      {'title': 'Scene Detection', 'subtitle': 'Auto-cut at scene changes', 'icon': Icons.crop_landscape, 'task': AiTaskType.sceneDetect},
      {'title': 'Remove Silences', 'subtitle': 'Cut out quiet parts', 'icon': Icons.volume_off, 'task': AiTaskType.silenceDetect},
      {'title': 'Beat Sync', 'subtitle': 'Cut to music beats', 'icon': Icons.music_note, 'task': AiTaskType.beatDetect},
      {'title': 'Auto-Reframe', 'subtitle': 'Crop for vertical/horizontal', 'icon': Icons.aspect_ratio, 'task': AiTaskType.autoReframe},
      {'title': 'Generate Captions', 'subtitle': 'Style captions from transcript', 'icon': Icons.text_fields, 'task': AiTaskType.generateCaption},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(context, action);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, Map<String, dynamic> action) {
    final isSelected = _selectedTask == action['task'];
    return GlassCard(
      onTap: () => _runAction(context, action['task']),
      borderColor: isSelected ? const Color(0xFF6366F1) : null,
      borderWidth: isSelected ? 2 : 1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF2D2D3A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action['icon'], color: Colors.white, size: 20),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle, color: const Color(0xFF6366F1), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(action['title'], style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(action['subtitle'], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildSmartWorkflows(BuildContext context, AppProvider provider) {
    final workflows = [
      {'title': 'Social Media Cut', 'subtitle': 'Auto-edit for TikTok/Reels/Shorts', 'icon': Icons.smartphone, 'tasks': [AiTaskType.sceneDetect, AiTaskType.transcribe, AiTaskType.autoReframe]},
      {'title': 'Podcast Cleanup', 'subtitle': 'Remove silences, add captions', 'icon': Icons.podcasts, 'tasks': [AiTaskType.silenceDetect, AiTaskType.transcribe, AiTaskType.generateCaption]},
      {'title': 'Music Video Sync', 'subtitle': 'Cut to beat, add effects', 'icon': Icons.music_video, 'tasks': [AiTaskType.beatDetect, AiTaskType.sceneDetect]},
      {'title': 'Interview Polish', 'subtitle': 'Transcribe, remove filler, caption', 'icon': Icons.interpreter_mode, 'tasks': [AiTaskType.transcribe, AiTaskType.silenceDetect, AiTaskType.generateCaption]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Workflows', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...workflows.map((workflow) => GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          onTap: () => _runWorkflow(context, workflow['tasks'] as List<AiTaskType>),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(workflow['icon'] as IconData, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workflow['title'] as String, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(workflow['subtitle'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTasksTab(BuildContext context, AppProvider provider) {
    final tasks = provider.aiTasks;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text('No AI tasks yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white54)),
            const SizedBox(height: 8),
            Text('Run automations from the Automate tab', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(context, task, provider);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, AiTask task, AppProvider provider) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(task.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getTaskName(task.type), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(_getProviderName(task.provider), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
              if (task.status == AiTaskStatus.processing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: task.progress,
                    strokeWidth: 2,
                    color: const Color(0xFF6366F1),
                  ),
                )
              else if (task.status == AiTaskStatus.completed)
                Icon(Icons.check_circle, color: Colors.green, size: 20)
              else if (task.status == AiTaskStatus.failed)
                Icon(Icons.error, color: Colors.red, size: 20),
            ],
          ),
          if (task.status == AiTaskStatus.processing) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: task.progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
            ),
            const SizedBox(height: 4),
            Text('${(task.progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
          ],
          if (task.error != null) ...[
            const SizedBox(height: 8),
            Text(task.error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red)),
          ],
          if (task.status == AiTaskStatus.completed && task.output != null) ...[
            const SizedBox(height: 12),
            GlassButton(
              icon: Icons.check,
              label: 'Apply Results',
              onPressed: () => widget.onTaskComplete(task),
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(AiTaskStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case AiTaskStatus.pending:
        color = Colors.white38;
        icon = Icons.schedule;
        break;
      case AiTaskStatus.processing:
        color = const Color(0xFF6366F1);
        icon = Icons.sync;
        break;
      case AiTaskStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AiTaskStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case AiTaskStatus.cancelled:
        color = Colors.orange;
        icon = Icons.cancel;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getTaskName(AiTaskType type) {
    switch (type) {
      case AiTaskType.transcribe:
        return 'Transcribe Audio';
      case AiTaskType.sceneDetect:
        return 'Detect Scenes';
      case AiTaskType.silenceDetect:
        return 'Detect Silences';
      case AiTaskType.beatDetect:
        return 'Detect Beats';
      case AiTaskType.autoReframe:
        return 'Auto Reframe';
      case AiTaskType.generateCaption:
        return 'Generate Captions';
      default:
        return type.name;
    }
  }

  String _getProviderName(AiProvider provider) {
    switch (provider) {
      case AiProvider.local:
        return 'Local (Private)';
      case AiProvider.openai:
        return 'OpenAI';
      case AiProvider.assemblyai:
        return 'AssemblyAI';
      case AiProvider.custom:
        return 'Custom API';
    }
  }

  void _switchProvider(BuildContext context, AiProvider provider) {
    final currentSettings = context.read<AppProvider>().aiSettings;
    context.read<AppProvider>().updateAiSettings(currentSettings.copyWith(defaultProvider: provider));
  }

  Future<void> _runAction(BuildContext context, AiTaskType taskType) async {
    final provider = context.read<AppProvider>();
    final videoClips = provider.timeline.tracks
        .where((t) => t.type == TrackType.video && !t.isMuted)
        .expand((t) => t.clips)
        .toList();

    if (videoClips.isEmpty) {
      _showSnackBar(context, 'No video clips in timeline');
      return;
    }

    final videoPath = videoClips.first.sourcePath;
    if (videoPath.isEmpty) {
      _showSnackBar(context, 'Video file not found');
      return;
    }

    setState(() => _isProcessing = true);

    String? audioPath;
    if ([AiTaskType.transcribe, AiTaskType.silenceDetect, AiTaskType.beatDetect].contains(taskType)) {
      try {
        audioPath = await provider.ffmpeg.extractAudio(inputPath: videoPath);
      } catch (e) {
        _showSnackBar(context, 'Failed to extract audio: $e');
        setState(() => _isProcessing = false);
        return;
      }
    }

    final task = AiTask(
      type: taskType,
      provider: provider.aiSettings.taskProviderMap[taskType] ?? AiProvider.local,
      input: {
        'videoPath': videoPath,
        'audioPath': audioPath ?? videoPath,
      },
    );

    provider.addAiTask(task);
    await provider.runAiTask(task);

    setState(() => _isProcessing = false);
  }

  Future<void> _runWorkflow(BuildContext context, List<AiTaskType> tasks) async {
    for (final taskType in tasks) {
      await _runAction(context, taskType);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E1E2E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}