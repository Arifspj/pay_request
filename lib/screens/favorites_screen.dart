import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../models/favorite.dart';
import 'create_request_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _db = DatabaseHelper();
  List<Favorite> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await _db.getFavorites();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _addFavorite() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      _showSnackBar('Contact permission required');
      return;
    }

    try {
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone},
      );
      if (contact != null &&
          contact.displayName != null &&
          contact.displayName!.isNotEmpty &&
          contact.phones.isNotEmpty) {
        final fav = Favorite(
          name: contact.displayName!,
          mobile: contact.phones.first.number,
        );
        await _db.insertFavorite(fav);
        _loadFavorites();
        _showSnackBar('${fav.name} added to favorites');
      }
    } catch (e) {
      _showSnackBar('Could not add contact');
    }
  }

  Future<void> _removeFavorite(Favorite fav) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: Text('Remove ${fav.name} from favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && fav.id != null) {
      await _db.deleteFavorite(fav.id!);
      _loadFavorites();
    }
  }

  void _openWithFavorite(Favorite fav) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRequestScreen(
          merchantName: fav.name,
          upiId: '',
        ),
      ),
    );
  }

  Future<void> _toggleStar(Favorite fav) async {
    final updated = Favorite(
      id: fav.id,
      name: fav.name,
      mobile: fav.mobile,
      photo: fav.photo,
      isStarred: !fav.isStarred,
    );
    await _db.updateFavorite(updated);
    _loadFavorites();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starredCount = _favorites.where((f) => f.isStarred).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Column(
        children: [
          _buildFavoritesStats(theme, starredCount),
          Expanded(
            child: _favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorite contacts yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _addFavorite,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Contact'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ..._favorites
                          .map((fav) => _buildFavoriteCard(fav, theme)),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: _addFavorite,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Contact'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesStats(ThemeData theme, int starredCount) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol(theme, 'Total', _favorites.length.toString(), Icons.people),
          Container(
            height: 40,
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          _statCol(theme, 'Active', _favorites.length.toString(), Icons.bolt),
          Container(
            height: 40,
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          _statCol(theme, 'Starred', starredCount.toString(), Icons.star),
        ],
      ),
    );
  }

  Widget _statCol(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(Favorite fav, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openWithFavorite(fav),
          onLongPress: () => _removeFavorite(fav),
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
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  child: Text(
                    fav.name.isNotEmpty
                        ? fav.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fav.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        fav.mobile,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    fav.isStarred ? Icons.star : Icons.star_border,
                    color: fav.isStarred ? Colors.amber : theme.colorScheme.outline,
                  ),
                  onPressed: () => _toggleStar(fav),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
