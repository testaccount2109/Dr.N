import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/proxy_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProxyService _proxy = ProxyService();
  List<Map<String, String>> _servers = [];
  bool _isRunning = false;
  String _statusText = '';
  bool _loading = true;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '19132');

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    setState(() => _loading = true);
    try {
      final json = await _proxy.getServers();
      final List<dynamic> list = jsonDecode(json);
      setState(() {
        _servers = list.map((e) => Map<String, String>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final json = await _proxy.getStatus();
      final status = jsonDecode(json);
      setState(() {
        _isRunning = status['running'] == true;
        if (_isRunning) {
          _statusText = '▶ Active → ${status['target_server']}';
        } else {
          _statusText = '⏹ Idle';
        }
      });
    } catch (_) {
      setState(() {
        _isRunning = false;
        _statusText = '⏹ Idle';
      });
    }
  }

  void _showAddDialog() {
    _nameController.clear();
    _addressController.clear();
    _portController.text = '19132';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Add Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Server Name',
                hintText: 'My SMP',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'play.example.com',
                prefixIcon: Icon(Icons.language),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '19132',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final addr = _addressController.text.trim();
              final port = _portController.text.trim();
              if (name.isEmpty || addr.isEmpty) return;
              await _proxy.addServer(name, addr, port);
              Navigator.pop(ctx);
              _loadServers();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleProxy(Map<String, String> server) async {
    if (_isRunning) {
      await _proxy.stopProxy();
    } else {
      await _proxy.startProxy(server['address']!, server['port']!);
    }
    _refreshStatus();
  }

  Future<void> _deleteServer(String id) async {
    await _proxy.removeServer(id);
    if (_isRunning) await _proxy.stopProxy();
    _loadServers();
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dr.N', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isRunning
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: _isRunning ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadServers();
              _refreshStatus();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _servers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dns_outlined,
                          size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'No servers yet',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add a Minecraft server',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: _servers.length,
                  itemBuilder: (ctx, i) {
                    final s = _servers[i];
                    final isActive =
                        _isRunning && s['id'] == 'active_server';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.green.withOpacity(0.2)
                              : const Color(0xFF16213E),
                          child: Icon(
                            Icons.games,
                            color: isActive ? Colors.green : Colors.cyan,
                          ),
                        ),
                        title: Text(
                          s['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${s['address']}:${s['port']}',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isRunning
                                    ? Icons.stop_circle
                                    : Icons.play_circle,
                                color: _isRunning
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              onPressed: () => _toggleProxy(s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteServer(s['id']!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Server'),
      ),
    );
  }
}