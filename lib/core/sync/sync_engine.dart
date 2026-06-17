import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'peer_discovery.dart';
import 'conflict_resolver.dart';
import 'sync_queue.dart';

class SyncEngine {
  SyncEngine._();
  static final SyncEngine instance = SyncEngine._();

  Timer? _timer;
  bool _running = false;
  final _dio = Dio();

  Future<void> start() async {
    if (_running) return;
    _running = true;
    PeerDiscovery.instance.start();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _syncCycle());
    _syncCycle(); // immediate first sync
  }

  void stop() {
    _timer?.cancel();
    PeerDiscovery.instance.stop();
    _running = false;
  }

  Future<void> _syncCycle() async {
    final peers = PeerDiscovery.instance.activePeers;
    if (peers.isEmpty) return;

    for (final peer in peers) {
      try {
        await _syncWithPeer(peer);
      } catch (_) {
        // Peer unreachable — skip silently, try next cycle
      }
    }
  }

  Future<void> _syncWithPeer(PeerInfo peer) async {
    final config = ClinicConfig.instance;
    final pendingChanges = await SyncQueueManager.instance.getPendingChanges();

    // Push our changes to peer
    if (pendingChanges.isNotEmpty) {
      final response = await _dio.post(
        'http://${peer.ipAddress}:${peer.port}/sync/push',
        data: jsonEncode({
          'device_id': config.deviceId,
          'changes': pendingChanges,
        }),
        options: Options(
          headers: {
            'X-Clinic-Key': KeyGenerator.hash(config.clinicKey),
            'X-Device-Id': config.deviceId,
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // Mark as synced
        for (final change in pendingChanges) {
          await SyncQueueManager.instance.markSynced(change['id'] as String);
        }
      }
    }

    // Pull peer's changes
    final pullResponse = await _dio.get(
      'http://${peer.ipAddress}:${peer.port}/sync/pull',
      options: Options(
        headers: {
          'X-Clinic-Key': KeyGenerator.hash(config.clinicKey),
          'X-Device-Id': config.deviceId,
        },
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (pullResponse.statusCode == 200) {
      final data = pullResponse.data as Map<String, dynamic>;
      final changes = (data['changes'] as List<dynamic>?) ?? [];
      for (final change in changes) {
        await ConflictResolver.instance
            .applyChange(change as Map<String, dynamic>);
      }
    }
  }
}
