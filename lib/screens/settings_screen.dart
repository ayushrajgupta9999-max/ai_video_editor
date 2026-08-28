import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ai_models.dart';
import '../models/media.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI'),
            Tab(icon: Icon(Icons.video_settings), text: 'Export'),
            Tab(icon: Icon(Icons.palette), text: 'Appearance'),
          ],
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAiSettings(),
          _buildExportSettings(),
          _buildAppearanceSettings(),
        ],
      ),
    );
  }

  Widget _buildAiSettings() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final settings = provider.aiSettings;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('AI Provider', 'Choose where AI processing runs'),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProviderOption('Local (Private)', AiProvider.local, settings.defaultProvider, 
                      'Runs on device using Whisper.cpp. Slower but completely private.'),
                    const SizedBox(height: 12),
                    _buildProviderOption('OpenAI', AiProvider.openai, settings.defaultProvider,
                      'Fast, accurate transcription. Requires API key.'),
                    const SizedBox(height: 12),
                    _buildProviderOption('AssemblyAI', AiProvider.assemblyai, settings.defaultProvider,
                      'Professional speech-to-text. Requires API key.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (settings.defaultProvider == AiProvider.openai) ...[
                _buildSectionHeader('OpenAI API Key', ''),
                const SizedBox(height: 12),
                GlassTextField(
                  label: 'API Key',
                  hint: 'sk-...',
                  obscureText: true,
                  controller: TextEditingController(text: settings.openaiApiKey),
                  onChanged: (value) => provider.updateAiSettings(settings.copyWith(openaiApiKey: value)),
                ),
                const SizedBox(height: 24),
              ],
              
              if (settings.defaultProvider == AiProvider.assemblyai) ...[
                _buildSectionHeader('AssemblyAI API Key', ''),
                const SizedBox(height: 12),
                GlassTextField(
                  label: 'API Key',
                  hint: 'your-api-key',
                  obscureText: true,
                  controller: TextEditingController(text: settings.assemblyaiApiKey),
                  onChanged: (value) => provider.updateAiSettings(settings.copyWith(assemblyaiApiKey: value)),
                ),
                const SizedBox(height: 24),
              ],
              
              if (settings.defaultProvider == AiProvider.local) ...[
                _buildSectionHeader('Local Model Settings', 'Configure Whisper.cpp model'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: settings.whisperModelSize,
                        dropdownColor: const Color(0xFF2D2D3A),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Model Size',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: ['tiny', 'base', 'small', 'medium', 'large'].map((size) {
                          return DropdownMenuItem(value: size, child: Text(size.toUpperCase()));
                        }).toList(),
                        onChanged: (value) => provider.updateAiSettings(settings.copyWith(whisperModelSize: value!)),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Enable Local Whisper', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Download and use Whisper.cpp locally', style: TextStyle(color: Colors.white54)),
                        value: settings.enableLocalWhisper,
                        activeColor: const Color(0xFF6366F1),
                        onChanged: (value) => provider.updateAiSettings(settings.copyWith(enableLocalWhisper: value)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              _buildSectionHeader('Per-Task Provider', 'Choose provider for each AI task'),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: AiTaskType.values.map((task) {
                    final currentProvider = settings.taskProviderMap[task] ?? settings.defaultProvider;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(_getTaskName(task), style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<AiProvider>(
                              value: currentProvider,
                              dropdownColor: const Color(0xFF2D2D3A),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: AiProvider.values.map((p) {
                                return DropdownMenuItem(value: p, child: Text(_getProviderName(p)));
                              }).toList(),
                              onChanged: (value) {
                                final newMap = Map<AiTaskType, AiProvider>.from(settings.taskProviderMap);
                                newMap[task] = value!;
                                provider.updateAiSettings(settings.copyWith(taskProviderMap: newMap));
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Detection Thresholds', 'Fine-tune AI sensitivity'),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GlassSlider(
                      label: 'Scene Detection Threshold',
                      value: settings.sceneDetectionThreshold,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: (value) => provider.updateAiSettings(settings.copyWith(sceneDetectionThreshold: value)),
                    ),
                    GlassSlider(
                      label: 'Silence Threshold (dB)',
                      value: settings.silenceThreshold,
                      min: -60.0,
                      max: -20.0,
                      divisions: 40,
                      onChanged: (value) => provider.updateAiSettings(settings.copyWith(silenceThreshold: value)),
                    ),
                    GlassSlider(
                      label: 'Minimum Silence Duration (ms)',
                      value: settings.minSilenceDurationMs.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      onChanged: (value) => provider.updateAiSettings(settings.copyWith(minSilenceDurationMs: value.round())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportSettings() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final settings = provider.exportSettings;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Video Settings', 'Configure output video parameters'),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDropdownSetting(
                      label: 'Format',
                      value: settings.format.name,
                      items: ContainerFormat.values.map((e) => e.name).toList(),
                      onChanged: (value) => provider.updateExportSettings(settings.copyWith(format: ContainerFormat.values.firstWhere((e) => e.name == value))),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownSetting(
                      label: 'Video Codec',
                      value: settings.videoCodec.name,
                      items: VideoCodec.values.map((e) => e.name).toList(),
                      onChanged: (value) => provider.updateExportSettings(settings.copyWith(videoCodec: VideoCodec.values.firstWhere((e) => e.name == value))),
                    ),
                    const SizedBox(height: 16),
                    GlassSlider(
                      label: 'Video Bitrate (kbps)',
                      value: settings.videoBitrate.toDouble(),
                      min: 1000,
                      max: 50000,
                      divisions: 49,
                      onChanged: (value) => provider.updateExportSettings(settings.copyWith(videoBitrate: value.round())),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownSetting(
                      label: 'Preset',
                      value: settings.preset,
                      items: ['ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow'],
                      onChanged: (value) => provider.updateExportSettings(settings.copyWith(preset: value!)),
                    ),
                    const SizedBox(height: 16),
                    GlassSlider(
                      label: 'Frame Rate',
                      value: settings.frameRate.toDouble(),
                      min: 15,
                      max: 60,
                      divisions: 9,
                      onChanged: (value) => provider.updateExportSettings(settings.copyWith(frameRate: value.round())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Audio Settings', 'Configure output audio parameters'),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Theme', 'Customize the app appearance'),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildThemeOption('Dark', Brightness.dark),
                const SizedBox(height: 12),
                _buildThemeOption('Light', Brightness.light),
                const SizedBox(height: 12),
                _buildThemeOption('System', null),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Accent Color', 'Choose your accent color'),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
                const Color(0xFFEC4899),
                const Color(0xFF06B6D4),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
                const Color(0xFFEF4444),
                const Color(0xFF6366F1),
              ].map((color) => _buildColorOption(color)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
        ],
      ],
    );
  }

  Widget _buildProviderOption(String title, AiProvider provider, AiProvider current, String description) {
    final isSelected = current == provider;
    return GestureDetector(
      onTap: () {
        final appProvider = context.read<AppProvider>();
        appProvider.updateAiSettings(appProvider.aiSettings.copyWith(defaultProvider: provider));
      },
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
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white38,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildThemeOption(String name, Brightness? brightness) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(brightness == Brightness.dark ? Icons.dark_mode : brightness == Brightness.light ? Icons.light_mode : Icons.brightness_auto, color: Colors.white70),
          const SizedBox(width: 16),
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          // TODO: Add selection indicator
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: Set accent color
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
      ),
    );
  }

  String _getTaskName(AiTaskType task) {
    switch (task) {
      case AiTaskType.transcribe: return 'Transcribe Audio';
      case AiTaskType.sceneDetect: return 'Scene Detection';
      case AiTaskType.silenceDetect: return 'Silence Detection';
      case AiTaskType.beatDetect: return 'Beat Detection';
      case AiTaskType.autoReframe: return 'Auto Reframe';
      case AiTaskType.generateCaption: return 'Generate Captions';
      case AiTaskType.summarize: return 'Summarize';
      case AiTaskType.translate: return 'Translate';
      case AiTaskType.textToSpeech: return 'Text to Speech';
      case AiTaskType.imageGeneration: return 'Image Generation';
      case AiTaskType.styleTransfer: return 'Style Transfer';
      case AiTaskType.colorGrade: return 'Color Grade';
      case AiTaskType.removeBackground: return 'Remove Background';
      case AiTaskType.objectTracking: return 'Object Tracking';
      case AiTaskType.faceDetection: return 'Face Detection';
    }
  }

  String _getProviderName(AiProvider provider) {
    switch (provider) {
      case AiProvider.local: return 'Local (Private)';
      case AiProvider.openai: return 'OpenAI';
      case AiProvider.assemblyai: return 'AssemblyAI';
      case AiProvider.custom: return 'Custom API';
    }
  }
}