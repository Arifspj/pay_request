import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../models/payment_request.dart';
import '../models/favorite.dart';
import '../models/categories.dart';
import '../services/share_service.dart';
import 'scan_qr_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final String? upiId;
  final String? merchantName;
  final PaymentRequest? existingRequest;
  final bool autoShare;

  const CreateRequestScreen({
    super.key,
    this.upiId,
    this.merchantName,
    this.existingRequest,
    this.autoShare = false,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _db = DatabaseHelper();
  final _picker = ImagePicker();

  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _invoicePath;
  List<Favorite> _favorites = [];
  List<Map<String, dynamic>> _merchantFavorites = [];
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  String? _selectedContactName;
  String? _selectedContactNumber;
  String _selectedCategory = '';
  bool _loadingContacts = false;
  final _contactSearchController = TextEditingController();

  late String _upiId;
  late String _merchantName;

  @override
  void initState() {
    super.initState();
    _upiId = widget.upiId ?? widget.existingRequest?.upiId ?? '';
    _merchantName =
        widget.merchantName ?? widget.existingRequest?.merchantName ?? '';

    if (widget.existingRequest != null) {
      _amountController.text =
          widget.existingRequest!.amount.toStringAsFixed(0);
      _invoicePath = widget.existingRequest!.invoicePath;
      _selectedContactName = widget.existingRequest!.contactName;
      _selectedContactNumber = widget.existingRequest!.contactNumber;
      _selectedCategory = widget.existingRequest!.category ?? '';
      _remarksController.text = widget.existingRequest!.remarks ?? '';
    }

    _loadFavorites();
    _loadContacts();
    _loadLastCategory();
    _contactSearchController.addListener(_filterContacts);

    if (widget.autoShare && widget.existingRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shareRequest();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    _contactSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favs = await _db.getFavorites();
    final merchantFavs = await _db.getMerchantFavorites();
    if (mounted) {
      setState(() {
        _favorites = favs;
        _merchantFavorites = merchantFavs;
      });
    }
  }

  Future<void> _loadLastCategory() async {
    final lastCat = await _db.getSetting('last_category');
    if (mounted && lastCat != null && _selectedCategory.isEmpty) {
      setState(() {
        _selectedCategory = lastCat;
      });
    }
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return;

    setState(() => _loadingContacts = true);
    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      if (mounted) {
        setState(() {
          _contacts = contacts
              .where((c) =>
                  c.phones.isNotEmpty &&
                  c.displayName != null &&
                  c.displayName!.isNotEmpty)
              .toList();
          _filteredContacts = List.from(_contacts);
          _loadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  void _filterContacts() {
    final query = _contactSearchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts.where((c) {
          final name = c.displayName?.toLowerCase() ?? '';
          final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  void _selectContact(String? name) {
    if (name == null) return;
    final contact = _contacts.firstWhere(
      (c) => c.displayName == name,
      orElse: () => Contact(phones: [], emails: [], addresses: [],
          organizations: [], websites: [], socialMedias: [], events: [],
          relations: [], notes: []),
    );
    setState(() {
      _selectedContactName = name;
      _selectedContactNumber =
          contact.phones.isNotEmpty ? contact.phones.first.number : '';
    });
  }

  void _scanQRAgain() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanQRScreen()),
    );
  }

  Future<void> _pickInvoice(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (xfile != null) {
      setState(() => _invoicePath = xfile.path);
    }
  }

  Future<void> _shareRequest() async {
    if (_upiId.isEmpty) {
      _showSnackBar('UPI ID is required');
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = amountText.isNotEmpty ? double.tryParse(amountText) : null;
    if (amountText.isNotEmpty && (amount == null || amount <= 0)) {
      _showSnackBar('Please enter a valid amount');
      return;
    }

    final request = PaymentRequest(
      merchantName: _merchantName,
      upiId: _upiId,
      amount: amount ?? 0,
      invoicePath: _invoicePath,
      contactName: _selectedContactName,
      contactNumber: _selectedContactNumber,
      status: 'Shared',
      category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      remarks: _remarksController.text.trim().isNotEmpty
          ? _remarksController.text.trim()
          : null,
    );

    await _db.insertRequest(request);
    await _db.setSetting('last_category', _selectedCategory);
    if (_merchantName.isNotEmpty && _upiId.isNotEmpty) {
      await _db.upsertMerchantFavorite(_merchantName, _upiId, _selectedCategory);
    }

    try {
      await ShareService.shareOnWhatsApp(request);
      if (!mounted) return;
      final scanAgain = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Shared Successfully'),
          content: const Text('What would you like to do next?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay Here'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      );
      if (mounted) {
        if (scanAgain == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ScanQRScreen()),
          );
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to share: $e');
    }
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Request'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Merchant Info
          _buildMerchantCard(theme),
          if (_merchantFavorites.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMerchantFavorites(theme),
          ],
          const SizedBox(height: 24),
          // Amount
          _buildAmountSection(theme),
          const SizedBox(height: 24),
          // Category
          _buildCategorySection(theme),
          const SizedBox(height: 24),
          // Remarks
          _buildRemarksSection(theme),
          const SizedBox(height: 24),
          // Invoice
          _buildInvoiceSection(theme),
          const SizedBox(height: 24),
          // Favorites
          _buildFavoritesSection(theme),
          const SizedBox(height: 16),
          // Contacts
          _buildContactsSection(theme),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _shareRequest,
            icon: const Icon(Icons.ios_share),
            label: const Text('Share'),
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MERCHANT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _merchantName.isEmpty ? 'Enter merchant name' : _merchantName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _merchantName.isEmpty
                        ? theme.colorScheme.outline
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _upiId.isEmpty ? 'Scan QR to auto-fill' : _upiId,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(ThemeData theme) {
    final presets = [50, 100, 200, 500, 1000, 2000];

    return Column(
      children: [
        Text(
          'ENTER AMOUNT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              onPressed: () => _scanQRAgain(),
              tooltip: 'Scan QR again',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: presets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final preset = presets[index];
              return ChoiceChip(
                label: Text('₹$preset'),
                selected: _amountController.text == preset.toString(),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _amountController.text = preset.toString();
                    });
                  }
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: _amountController.text == preset.toString()
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _amountController.text == preset.toString()
                        ? Colors.transparent
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                showCheckmark: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    final selectedCat = expenseCategories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => expenseCategories.last,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCategorySheet(theme),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedCategory.isEmpty
                      ? Icons.category_outlined
                      : selectedCat.icon,
                  color: _selectedCategory.isEmpty
                      ? theme.colorScheme.outline
                      : selectedCat.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCategory.isEmpty ? 'Select category' : _selectedCategory,
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedCategory.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCategorySheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: expenseCategories.length,
                  itemBuilder: (context, index) {
                    final cat = expenseCategories[index];
                    final isSelected = _selectedCategory == cat.name;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = cat.name);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withOpacity(0.1)
                              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? cat.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat.icon,
                              color: isSelected ? cat.color : theme.colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? cat.color : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemarksSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REMARKS (optional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _remarksController,
          maxLines: 2,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Add a note...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInvoiceButton(
                context,
                icon: Icons.photo_camera,
                label: 'Camera',
                onTap: () => _pickInvoice(ImageSource.camera),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInvoiceButton(
                context,
                icon: Icons.image,
                label: 'Gallery',
                onTap: () => _pickInvoice(ImageSource.gallery),
                theme: theme,
              ),
            ),
          ],
        ),
        if (_invoicePath != null) ...[
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_invoicePath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () => setState(() => _invoicePath = null),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantFavorites(ThemeData theme) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _merchantFavorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final fav = _merchantFavorites[i];
          final name = fav['name'] as String;
          final upi = fav['upi_id'] as String;
          return ActionChip(
            avatar: const Icon(Icons.store, size: 16),
            label: Text(name, style: const TextStyle(fontSize: 13)),
            onPressed: () => setState(() {
              _merchantName = name;
              _upiId = upi;
            }),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Contacts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._favorites.map((fav) => _buildFavoriteAvatar(fav, theme)),
              _buildAddFavoriteAvatar(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteAvatar(Favorite fav, ThemeData theme) {
    final isSelected = _selectedContactName == fav.name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContactName = fav.name;
          _selectedContactNumber = fav.mobile;
        });
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    child: Text(
                      fav.name.isNotEmpty ? fav.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _shareRequest,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.send,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              fav.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFavoriteAvatar(ThemeData theme) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            child: const Icon(Icons.add, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add New',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsSection(ThemeData theme) {
    final contactWidgets = _filteredContacts.take(20).map((contact) {
      final name = contact.displayName ?? 'Unknown';
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number
          : '';
      final initials = name
          .split(' ')
          .map((n) => n.isNotEmpty ? n[0] : '')
          .take(2)
          .join();
      final isSelected = _selectedContactName == name;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _selectedContactName = name;
                _selectedContactNumber = phone;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                        Text(phone,
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    IconButton(
                      icon: Icon(Icons.send, color: theme.colorScheme.primary),
                      onPressed: _shareRequest,
                    )
                  else
                    Radio<String>(
                      value: name,
                      groupValue: _selectedContactName,
                      onChanged: (val) => _selectContact(val),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHONE CONTACTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextField(
          controller: _contactSearchController,
          decoration: InputDecoration(
            hintText: 'Search contacts by name or number...',
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingContacts)
          const Center(child: CircularProgressIndicator())
        else if (_contacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No contacts found. Grant contact permission.',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          )
        else
          Column(children: contactWidgets),
      ],
    );
  }
}

