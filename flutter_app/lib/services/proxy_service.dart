// ProxyService with local server storage + Go backend for proxy only
import 'package:flutter/services.dart';

class ProxyService {
  static const MethodChannel _channel = MethodChannel('drn.app/proxy');

  // --- Local server storage (no Go backend needed) ---
  final List<Map<String, String>> _servers = [];
  int _nextId = 1;

  List<Map<String, String>> getServers() {
    return List.from(_servers);
  }

  void addServer(String name, String address, String port) {
    _servers.add({
      'id': 'srv_${_nextId++}',
      'name': name,
      'address': address,
      'port': port,
    });
  }

  void removeServer(String id) {
    _servers.removeWhere((s) => s['id'] == id);
  }

  // --- Go backend for proxy only ---
  Future<bool> isRunning() async {
    try {
      final json = await _channel.invokeMethod<String>('getStatus');
      if (json == null) return false;
      // Parse JSON with dart:convert
      return json.contains('"running":true');
    } catch (_) {
      return false;
    }
  }

  Future<String> getStatus() async {
    try {
      final result = await _channel.invokeMethod<String>('getStatus');
      return result ?? '{"running":false}';
    } catch (_) {
      return '{"running":false,"error":"bridge not available"}';
    }
  }

  Future<void> startProxy(String address, String port) async {
    try {
      await _channel.invokeMethod('startProxy', {
        'address': address,
        'port': port,
      });
    } catch (e) {
      throw Exception('Proxy start failed: $e');
    }
  }

  Future<void> stopProxy() async {
    try {
      await _channel.invokeMethod('stopProxy');
    } catch (e) {
      throw Exception('Proxy stop failed: $e');
    }
  }
}