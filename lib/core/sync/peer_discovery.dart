import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:medcenter/core/config/clinic_config.dart';

class PeerInfo {
  final String deviceId;
  final String ipAddress;
  final int port;
  DateTime lastSeen;

  PeerInfo({
    required this.deviceId,
    required this.ipAddress,
    required this.port,
    required this.lastSeen,
  });
}

class PeerDiscovery {
  PeerDiscovery._();
  static final PeerDiscovery instance = PeerDiscovery._();

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  final Map<String, PeerInfo> _peers = {};

  List<PeerInfo> get activePeers {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 90));
    return _peers.values.where((p) => p.lastSeen.isAfter(cutoff)).toList();
  }

  Future<void> start() async {
    final config = ClinicConfig.instance;
    if (!config.isConfigured) return;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        9999,
        reuseAddress: true,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram == null) return;
          _handleBroadcast(datagram);
        }
      });

      // Broadcast presence every 5 seconds
      _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _broadcast();
      });

      // Cleanup stale peers every 30 seconds
      _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _cleanupStale();
      });

      _broadcast();
    } catch (_) {
      // UDP not available — continue without peer discovery
    }
  }

  void _broadcast() {
    final config = ClinicConfig.instance;
    final message = 'MEDCENTER|${config.clinicKey}|${config.deviceId}|${config.apiPort}';
    final bytes = utf8.encode(message);
    try {
      _socket?.send(bytes, InternetAddress('255.255.255.255'), 9999);
    } catch (_) {}
  }

  void _handleBroadcast(Datagram datagram) {
    final config = ClinicConfig.instance;
    try {
      final message = utf8.decode(datagram.data);
      final parts = message.split('|');
      if (parts.length != 4) return;
      if (parts[0] != 'MEDCENTER') return;
      if (parts[1] != config.clinicKey) return; // Different clinic

      final deviceId = parts[2];
      if (deviceId == config.deviceId) return; // Own broadcast

      final port = int.tryParse(parts[3]) ?? 8080;
      final ip = datagram.address.address;

      _peers[deviceId] = PeerInfo(
        deviceId: deviceId,
        ipAddress: ip,
        port: port,
        lastSeen: DateTime.now(),
      );
    } catch (_) {}
  }

  void _cleanupStale() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 90));
    _peers.removeWhere((_, p) => p.lastSeen.isBefore(cutoff));
  }

  void stop() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
