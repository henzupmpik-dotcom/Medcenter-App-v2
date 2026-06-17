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
  ConsumerState<<MedCenterApp> createState() => _MedCenterAppState();
}

class _MedCenterAppState extends ConsumerState<<MedCenterApp> {
  bool _ready = false;
  String? _initError;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await DatabaseHelper.instance.init();
      await ClinicConfig.instance.load();
      await _startServices();
    } catch (e, stackTrace) {
      debugPrint('Init error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _initError = '$e\n\n$stackTrace');
      return;
    }
    if (mounted) setState(() {
      _ready = true;
      _retryCount = 0;
    });
  }

  Future<void> _startServices() async {
    if (!ClinicConfig.instance.isConfigured) return;
    try {
      await ApiServer.instance.start();
    } catch (e, stackTrace) {
      debugPrint('ApiServer start error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showServiceWarning('API Server', e.toString());
    }
    try {
      await SyncEngine.instance.start();
    } catch (e, stackTrace) {
      debugPrint('SyncEngine start error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showServiceWarning('Sync Engine', e.toString());
    }
  }

  void _showServiceWarning(String serviceName, String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$serviceName failed to start: $error'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _startServices,
              textColor: Colors.white,
            ),
          ),
        );
      }
    });
  }

  Future<void> _retryInit() async {
    if (_isRetrying || _retryCount >= _maxRetries) return;
    setState(() {
      _isRetrying = true;
      _initError = null;
      _ready = false;
      _retryCount++;
    });
    await _init();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      final bool canRetry = _retryCount < _maxRetries && !_isRetrying;
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
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (canRetry)
                    ElevatedButton(
                      onPressed: _retryInit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.darkBlue,
                      ),
                      child: Text('Retry (${_maxRetries - _retryCount} left)'),
                    )
                  else if (_isRetrying)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  else
                    Text(
                      'Max retries reached. Please restart the app.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.local_hospital, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MedCenter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
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
