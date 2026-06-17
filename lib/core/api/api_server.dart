import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/core/sync/sync_queue.dart';
import 'package:medcenter/core/sync/conflict_resolver.dart';

class ApiServer {
  ApiServer._();
  static final ApiServer instance = ApiServer._();

  HttpServer? _server;

  Future<void> start() async {
    if (_server != null) return;

    final router = Router();

    // Health check
    router.get('/health', (Request req) async {
      _checkClinicKey(req);
      return Response.ok(jsonEncode({'status': 'ok', 'device': ClinicConfig.instance.deviceId}),
          headers: {'Content-Type': 'application/json'});
    });

    // Push changes from peer to us
    router.post('/sync/push', (Request req) async {
      if (!_checkClinicKey(req)) {
        return Response.forbidden('Invalid clinic key');
      }
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final changes = (body['changes'] as List<dynamic>?) ?? [];
      for (final change in changes) {
        await ConflictResolver.instance.applyChange(change as Map<String, dynamic>);
      }
      return Response.ok(jsonEncode({'accepted': changes.length}),
          headers: {'Content-Type': 'application/json'});
    });

    // Pull our pending changes for a peer
    router.get('/sync/pull', (Request req) async {
      if (!_checkClinicKey(req)) {
        return Response.forbidden('Invalid clinic key');
      }
      final changes = await SyncQueueManager.instance.getPendingChanges();
      return Response.ok(jsonEncode({'changes': changes}),
          headers: {'Content-Type': 'application/json'});
    });

    // Peers endpoint — who we know about
    router.get('/peers', (Request req) async {
      if (!_checkClinicKey(req)) return Response.forbidden('Invalid clinic key');
      return Response.ok(jsonEncode({'device_id': ClinicConfig.instance.deviceId}),
          headers: {'Content-Type': 'application/json'});
    });

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    final port = ClinicConfig.instance.apiPort;
    _server = await io.serve(handler, InternetAddress.anyIPv4, port);
  }

  bool _checkClinicKey(Request req) {
    final config = ClinicConfig.instance;
    final expectedHash = KeyGenerator.hash(config.clinicKey);
    final provided = req.headers['x-clinic-key'];
    return provided == expectedHash;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}
