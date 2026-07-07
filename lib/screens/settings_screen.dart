import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../services/theme_provider.dart';

const _appVersion = '1.0.0';
const _playStoreUrl = 'https://play.google.com/store/apps/details?id=pay.request';
const _privacyUrl = 'https://pay-request.app/privacy';
const _termsUrl = 'https://pay-request.app/terms';

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

  Future<void> _exportCsv() async {
    final requests = await _db.getRequests(limit: 1000);
    final buffer = StringBuffer();
    buffer.writeln('Merchant,UPI ID,Amount,Category,Remarks,Contact Name,Contact Number,Status,Created At');
    for (final req in requests) {
      final cat = req.category ?? '';
      final rem = (req.remarks ?? '').replaceAll(',', ';');
      final name = (req.contactName ?? '').replaceAll(',', ';');
      final mobile = req.contactNumber ?? '';
      buffer.writeln(
        '${req.merchantName},${req.upiId},${req.amount},$cat,$rem,$name,$mobile,${req.status},${req.createdAt.toIso8601String()}',
      );
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/payment_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to ${file.path}')),
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
          _sectionHeader(theme, 'Preferences'),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (val) => themeProvider.toggleTheme(val),
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.share,
            title: 'Default Share App',
            subtitle: _defaultShareApp,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showShareAppPicker(),
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Data'),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.download,
            title: 'Export as TXT',
            subtitle: 'Export all requests as text file',
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportHistory,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.table_chart,
            title: 'Export as CSV',
            subtitle: 'Export all requests as CSV file',
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportCsv,
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Support'),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.star,
            title: 'Rate the App',
            subtitle: 'Love it? Leave a review on Play Store',
            trailing: const Icon(Icons.chevron_right),
            onTap: _rateApp,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.share,
            title: 'Share the App',
            subtitle: 'Tell your friends about Pay Request',
            trailing: const Icon(Icons.chevron_right),
            onTap: _shareApp,
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'Legal'),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            trailing: const Icon(Icons.chevron_right),
            onTap: _openPrivacyPolicy,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.description,
            title: 'Terms & Conditions',
            trailing: const Icon(Icons.chevron_right),
            onTap: _openTerms,
          ),
          const SizedBox(height: 24),
          _sectionHeader(theme, 'About'),
          const SizedBox(height: 8),
          _buildSettingCard(
            theme: theme,
            icon: Icons.info_outline,
            title: 'About Pay Request',
            subtitle: 'Version $_appVersion',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAbout(),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Pay Request v$_appVersion',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Made with ❤ in India',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          color: theme.colorScheme.primary,
        ),
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
              trailing ?? const Icon(Icons.chevron_right),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            _pickerTile(ctx, Icons.chat, 'WhatsApp'),
            _pickerTile(ctx, Icons.telegram, 'Telegram'),
            _pickerTile(ctx, Icons.mail, 'Email'),
            _pickerTile(ctx, Icons.share, 'System Share Sheet', 'System'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile(BuildContext ctx, IconData icon, String label, [String? value]) {
    final v = value ?? label;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: _defaultShareApp == v
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        _setDefaultShareApp(v);
        Navigator.pop(ctx);
      },
    );
  }

  Future<void> _rateApp() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Check out Pay Request — the easiest way to send UPI payment requests!\n$_playStoreUrl',
      subject: 'Pay Request App',
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTerms() async {
    final uri = Uri.parse(_termsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Pay Request',
      applicationVersion: _appVersion,
      applicationLegalese: '© ${DateTime.now().year} Pay Request',
      children: [
        const SizedBox(height: 16),
        const Text(
          'A simple app to create and share UPI payment requests via WhatsApp. '
          'Scan any UPI QR code, create payment requests with optional invoice attachments, '
          'and share them instantly.',
        ),
        const SizedBox(height: 16),
        Text(
          'Made with Flutter',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
