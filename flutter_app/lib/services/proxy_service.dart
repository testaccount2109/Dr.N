import 'package:flutter/services.dart';

/// ProxyService communicates with the native Go proxy via MethodChannel.
class ProxyService {
  static const MethodChannel _channel = MethodChannel('drn.app/proxy');

  Future<String> getServers() async {
    final result = await _channel.invokeMethod<String>('getServers');
    return result ?? '[]';
  }

  Future<String> getStatus() async {
    final result = await _channel.invokeMethod<String>('getStatus');
    return result ?? '{"running":false}';
  }

  Future<void> addServer(String name, String address, String port) async {
    await _channel.invokeMethod('addServer', {
      'name': name,
      'address': address,
      'port': port,
    });
  }

  Future<void> removeServer(String id) async {
    await _channel.invokeMethod('removeServer', {'id': id});
  }

  Future<void> startProxy(String address, String port) async {
    await _channel.invokeMethod('startProxy', {
      'address': address,
      'port': port,
    });
  }

  Future<void> stopProxy() async {
    await _channel.invokeMethod('stopProxy');
  }
}