import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper();
  String _defaultShareApp = 'WhatsApp';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final shareApp = await _db.getSetting('default_share_app');
    if (mounted) {
      setState(() {
        _defaultShareApp = shareApp ?? 'WhatsApp';
      });
    }
  }

  Future<void> _setDefaultShareApp(String app) async {
    await _db.setSetting('default_share_app', app);
    setState(() => _defaultShareApp = app);
  }

  Future<void> _exportHistory() async {
    final requests = await _db.getRequests(limit: 1000);
    final buffer = StringBuffer();
    buffer.writeln('Payment Request History');
    buffer.writeln('Exported: ${DateTime.now()}');
    buffer.writeln('');

    for (final req in requests) {
      buffer.writeln('Merchant: ${req.merchantName}');
      buffer.writeln('Amount: ₹${req.amount.toStringAsFixed(0)}');
      buffer.writeln('UPI: ${req.upiId}');
      buffer.writeln('Contact: ${req.contactName ?? "N/A"}');
      buffer.writeln('Status: ${req.status}');
      buffer.writeln('Date: ${req.createdAt}');
      buffer.writeln('---');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/payment_history_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(buffer.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Dark Mode
          _buildSettingCard(
            theme: theme,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (val) {
                themeProvider.toggleTheme(val);
              },
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Default Share App
          _buildSettingCard(
            theme: theme,
            icon: Icons.share,
            title: 'Default Share App',
            subtitle: _defaultShareApp,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showShareAppPicker(),
          ),
          const SizedBox(height: 8),
          // Export History
          _buildSettingCard(
            theme: theme,
            icon: Icons.download,
            title: 'Export History',
            subtitle: 'Export all requests as text file',
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportHistory,
          ),
          const SizedBox(height: 8),
          // About
          _buildSettingCard(
            theme: theme,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAbout(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareAppPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Default Share App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp'),
              trailing: _defaultShareApp == 'WhatsApp'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _setDefaultShareApp('WhatsApp');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.telegram),
              title: const Text('Telegram'),
              trailing: _defaultShareApp == 'Telegram'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _setDefaultShareApp('Telegram');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail),
              title: const Text('Email'),
              trailing: _defaultShareApp == 'Email'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _setDefaultShareApp('Email');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('System Share Sheet'),
              trailing: _defaultShareApp == 'System'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _setDefaultShareApp('System');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Request App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A simple app to create and share UPI payment requests via WhatsApp.'),
            SizedBox(height: 8),
            Text('Made with Flutter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
