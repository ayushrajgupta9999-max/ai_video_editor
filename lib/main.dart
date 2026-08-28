// Main application entry point
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/platform/platform.dart';
import 'providers/app_provider.dart';
import 'services/ffmpeg/ffmpeg_factory.dart';
import 'services/storage/storage_service.dart';
import 'services/media/media_processing_service.dart';
import 'screens/home_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/export_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  await storage.initialize();

  // Initialize FFmpeg service
  late MediaProcessingService mediaService;
  if (PlatformUtils.isWeb) {
    mediaService = MockMediaProcessingService() as MediaProcessingService;
  } else {
    try {
      mediaService = await FFmpegServiceFactory.create();
    } catch (e) {
      debugPrint('Failed to initialize FFmpeg: $e. Using mock service.');
      mediaService = MockMediaProcessingService() as MediaProcessingService;
    }
  }

  // Create providers
  final appProvider = AppProvider(
    mediaService: mediaService,
    storageService: storage,
  );

  runApp(AiVideoEditorApp(appProvider: appProvider, mediaService: mediaService));
}

class AiVideoEditorApp extends StatelessWidget {
  final AppProvider appProvider;
  final MediaProcessingService mediaService;

  const AiVideoEditorApp({
    super.key,
    required this.appProvider,
    required this.mediaService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        Provider.value(value: mediaService),
      ],
      child: MaterialApp(
        title: 'AI Video Editor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
            primary: const Color(0xFF6366F1),
            secondary: const Color(0xFF8B5CF6),
            surface: const Color(0xFF1E1E2E),
            onSurface: Colors.white,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E2E),
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E2E),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2D2D3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/editor': (context) => const EditorScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/export': (context) => const ExportScreen(),
        },
      ),
    );
  }
}