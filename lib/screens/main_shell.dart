import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../app.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'scan_qr_screen.dart';
import 'create_request_screen.dart';
import '../database/database_helper.dart';
import '../models/payment_request.dart';

class PaymentRequestApp extends StatelessWidget {
  const PaymentRequestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Pay Request',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainShell(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _db = DatabaseHelper();
  double _totalAmount = 0.0;
  Map<String, double> _categoryBreakdown = {};

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _db.getGlobalStats();
    final breakdown = await _db.getCategoryBreakdown();
    if (mounted) {
      setState(() {
        _totalAmount = stats['total_amount'] as double;
        _categoryBreakdown = breakdown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: _buildGlobalDrawer(context, theme),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          selectedItemColor: _currentIndex == 0
              ? const Color(0xFF16A34A)
              : theme.colorScheme.secondary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              activeIcon: Icon(Icons.star),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalDrawer(BuildContext context, ThemeData theme) {
    final sortedCategories = _categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.payments,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pay Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your UPI requests',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 12),
                _drawerTile(Icons.home, 'Home', () {
                  setState(() => _currentIndex = 0);
                  Navigator.pop(context);
                }, theme, selected: _currentIndex == 0),
                _drawerTile(Icons.qr_code_scanner, 'Scan QR', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanQRScreen()),
                  ).then((_) => _loadStats());
                }, theme),
                _drawerTile(Icons.add_circle_outline, 'Create Request', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                  ).then((_) => _loadStats());
                }, theme),
                _drawerTile(Icons.star_border, 'Favorites', () {
                  setState(() => _currentIndex = 1);
                  Navigator.pop(context);
                }, theme, selected: _currentIndex == 1),
                _drawerTile(Icons.settings_outlined, 'Settings', () {
                  setState(() => _currentIndex = 2);
                  Navigator.pop(context);
                }, theme, selected: _currentIndex == 2),
                const Divider(indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'EXPENSE STATS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Volume',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('₹${_totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (sortedCategories.isEmpty)
                        const Text('No data available', style: TextStyle(fontSize: 12, color: Colors.grey))
                      else
                        ...sortedCategories.take(4).map((catEntry) {
                          final percent = _totalAmount > 0 ? catEntry.value / _totalAmount : 0.0;
                          final catItem = expenseCategories.firstWhere(
                            (c) => c.name == catEntry.key,
                            orElse: () => expenseCategories.last,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(catItem.icon, size: 12, color: catItem.color),
                                        const SizedBox(width: 4),
                                        Text(catEntry.key, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Text('₹${catEntry.value.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    color: catItem.color,
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Text(
                  'Pay Request v1.0.0',
                  style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, ThemeData theme, {bool selected = false}) {
    return ListTile(
      leading: Icon(icon, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
