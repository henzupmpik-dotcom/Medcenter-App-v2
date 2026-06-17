import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/sync/sync_engine.dart';
import 'package:medcenter/core/api/api_server.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/shared/app_router.dart';
import 'package:medcenter/shared/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MedCenterApp()));
}

class MedCenterApp extends ConsumerStatefulWidget {
  const MedCenterApp({super.key});

  @override
  ConsumerState<MedCenterApp> createState() => _MedCenterAppState();
}

class _MedCenterAppState extends ConsumerState<MedCenterApp> {
  bool _ready = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Init database
      await DatabaseHelper.instance.init();
      // Load clinic config
      await ClinicConfig.instance.load();
      // Start background services (only if clinic is configured)
      await _startServices();
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
      return;
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _startServices() async {
    if (!ClinicConfig.instance.isConfigured) return;
    try {
      await ApiServer.instance.start();
    } catch (e) {
      // Port may already be in use on re-launch — not fatal
      debugPrint('ApiServer start error: $e');
    }
    try {
      await SyncEngine.instance.start();
    } catch (e) {
      debugPrint('SyncEngine start error: $e');
    }
  }

  @override
  void dispose() {
    ApiServer.instance.stop();
    SyncEngine.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      // Show error so the user isn't left on a blank blue screen
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.darkBlue,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to start MedCenter',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() { _initError = null; _ready = false; });
                      _init();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.darkBlue),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      // Visible splash instead of blank blue
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.darkBlue,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.local_hospital, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MedCenter',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'MedCenter',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
