import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'file_helper.dart';
import 'drive_sync.dart';
import 'main.dart';
import 'models.dart';
import 'profile_store.dart';

class AccountScreen extends StatelessWidget {
  final VoidCallback onExportData;
  final VoidCallback onImportData;
  final VoidCallback onClearData;
  final Future<void> Function() onSyncUpload;
  final Future<void> Function() onSyncDownload;
  final Uint8List? vehicleImageBytes;
  final void Function(Uint8List?) onVehicleImageChanged;
  final List<Vehicle> vehicles;
  final void Function(Vehicle) onAddVehicle;
  final void Function(int index, String newName, Uint8List? newImage) onEditVehicle;
  final void Function(int index) onDeleteVehicle;
  final void Function(Color) onAccentChanged;
  final void Function(Color) onAccentSaved;
  final List<Color> recentColors;
  final bool isDarkMode;
  final void Function(bool) onToggleDarkMode;
  final bool useMetric;
  final void Function(bool) onToggleUnit;

  const AccountScreen({
    super.key,
    required this.onExportData,
    required this.onImportData,
    required this.onClearData,
    required this.onSyncUpload,
    required this.onSyncDownload,
    this.vehicleImageBytes,
    required this.onVehicleImageChanged,
    required this.vehicles,
    required this.onAddVehicle,
    required this.onEditVehicle,
    required this.onDeleteVehicle,
    required this.onAccentChanged,
    required this.onAccentSaved,
    required this.recentColors,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.useMetric,
    required this.onToggleUnit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile section
            const _ProfileSection(),
            const SizedBox(height: 24),

            // Settings options
            _SettingsTile(
              icon: Icons.two_wheeler,
              title: 'Vehicle Settings',
              subtitle: '${vehicles.length} vehicle${vehicles.length > 1 ? 's' : ''} added',
              onTap: () => _showVehicleSettings(context),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: 'Units',
              subtitle: useMetric ? 'Metric' : 'Imperial',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: useMetric,
                    isDense: true,
                    dropdownColor: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.keyboard_arrow_down, color: accent, size: 18),
                    style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('km/l')),
                      DropdownMenuItem(value: false, child: Text('mpg')),
                    ],
                    onChanged: (v) {
                      if (v != null) onToggleUnit(v);
                    },
                  ),
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme Color',
              subtitle: 'Customize app theme',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...recentColors.take(2).map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ColorDot(
                      color: c,
                      isSelected: accent.value == c.value,
                      onTap: () => onAccentChanged(c),
                    ),
                  )),
                  GestureDetector(
                    onTap: () => _showColorPicker(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD1D1D6), width: 1.5),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SettingsTile(
                      icon: Icons.backup,
                      title: 'Export',
                      subtitle: 'Backup',
                      trailing: const SizedBox.shrink(),
                      onTap: () async {
                        if (await DriveSync.isSignedIn()) {
                          await onSyncUpload();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Backup uploaded to Google Drive')),
                            );
                          }
                        } else {
                          onExportData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Backup file downloading...')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SettingsTile(
                      icon: Icons.file_upload,
                      title: 'Import',
                      subtitle: 'Backup',
                      trailing: const SizedBox.shrink(),
                      onTap: () async {
                        if (await DriveSync.isSignedIn()) {
                          await onSyncDownload();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Backup restored from Drive')),
                            );
                          }
                        } else {
                          onImportData();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Mileaged v1.0.4',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.favorite_outline,
              title: 'Support the Developer',
              subtitle: 'Buy me a coffee',
              iconColor: Colors.pinkAccent,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const _DonateDialog(),
              ),
            ),
            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Clear All Data',
              subtitle: 'Reset everything',
              iconColor: Colors.redAccent,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: Text('Clear Data?',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    content: const Text(
                      'This will delete all vehicles and their data.',
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          onClearData();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All data cleared')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showVehicleSettings(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = cs.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Vehicle Settings', style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // List existing vehicles
              ...vehicles.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Icon(Icons.two_wheeler, color: accent),
                    title: Text(v.name, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      v.imageBytes != null ? 'Image set ✓' : 'No image',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showEditVehicleDialog(context, idx, v);
                          },
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.edit, size: 18, color: accent),
                          ),
                        ),
                        if (vehicles.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showDeleteVehicleDialog(context, idx, v);
                            },
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              // Add new vehicle button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddVehicleDialog(context);
                  },
                  icon: Icon(Icons.add, color: AccentColorScope.onAccent(context)),
                  label: Text('Add New Vehicle', style: TextStyle(color: AccentColorScope.onAccent(context))),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, int index, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => _EditVehicleDialog(
        vehicle: vehicle,
        onSave: (name, imageBytes) {
          onEditVehicle(index, name, imageBytes);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name updated')),
          );
        },
      ),
    );
  }

  void _showDeleteVehicleDialog(BuildContext context, int index, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Delete Vehicle?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'Delete "${vehicle.name}" and all its data? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onDeleteVehicle(index);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${vehicle.name} deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddVehicleDialog(
        onAdd: (vehicle) {
          onAddVehicle(vehicle);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${vehicle.name} added')),
          );
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        currentColor: Theme.of(context).colorScheme.primary,
        onColorSelected: (color) {
          onAccentChanged(color);
          Navigator.pop(ctx);
        },
        onColorSaved: (color) {
          onAccentSaved(color);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Color saved')),
          );
        },
      ),
    );
  }
}

class _ProfileSection extends StatefulWidget {
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSignIn();
  }

  Future<void> _checkSignIn() async {
    final signedIn = await DriveSync.isSignedIn();
    if (mounted) {
      setState(() => _isSignedIn = signedIn);
    }
  }

  Future<Uint8List?> _downloadPhoto(String url) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http.get(Uri.parse(url));
        debugPrint('Profile photo download attempt ${attempt + 1}: status=${response.statusCode}, bytes=${response.bodyBytes.length}');
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
        if (response.statusCode == 429) {
          // Rate limited — wait before retrying
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        break; // Non-retryable status
      } catch (e) {
        debugPrint('Profile photo download attempt ${attempt + 1} failed: $e');
        break;
      }
    }
    return null;
  }

  Future<void> _handleSignIn() async {
    final account = await DriveSync.signIn();
    if (account != null) {
      String? photoUrl = account.photoUrl;
      Uint8List? photoBytes;
      if (photoUrl != null) {
        if (photoUrl.startsWith('//')) {
          photoUrl = 'https:$photoUrl';
        }
        photoBytes = await _downloadPhoto(photoUrl);
      } else {
        debugPrint('Google account photoUrl is null');
      }
      await ProfileStore.save(
        name: account.displayName ?? 'User',
        email: account.email,
        photoUrl: photoUrl,
        imageBytes: photoBytes,
      );
    }
    if (mounted) {
      setState(() => _isSignedIn = account != null);
    }
  }

  Future<void> _handleSignOut() async {
    await DriveSync.signOut();
    if (mounted) {
      setState(() => _isSignedIn = false);
    }
  }

  void _editProfile() {
    final controller = TextEditingController(text: ProfileStore.name);
    final cs = Theme.of(context).colorScheme;
    final accent = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) {
        Uint8List? tempImage = ProfileStore.imageBytes;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: cs.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit Profile', style: TextStyle(color: cs.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      pickImageFile(
                        (bytes) => setDialogState(() => tempImage = bytes),
                        (err) {},
                      );
                    },
                    child: tempImage != null
                        ? CircleAvatar(radius: 36, backgroundImage: MemoryImage(tempImage!))
                        : Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.2)),
                            child: Icon(Icons.camera_alt, color: accent, size: 28),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: cs.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: accent),
                      ),
                    ),
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
                    final newName = controller.text.trim().isEmpty ? 'User' : controller.text.trim();
                    await ProfileStore.save(
                      name: newName,
                      imageBytes: tempImage,
                    );
                    if (mounted) setState(() {});
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(double radius, Color accent, Color onAccent) {
    final size = radius * 2;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
      child: Icon(Icons.person, color: onAccent, size: radius),
    );
    if (ProfileStore.imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          ProfileStore.imageBytes!,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    } else if (ProfileStore.photoUrl != null) {
      return ClipOval(
        child: Image.network(
          ProfileStore.photoUrl!,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    final onAccent = AccentColorScope.onAccent(context);

    return Column(
      children: [
        // Profile avatar
        Stack(
          children: [
            _buildAvatar(36, accent, onAccent),
            if (!_isSignedIn)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _editProfile,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.surface,
                      border: Border.all(color: cs.outline, width: 1),
                    ),
                    child: Icon(Icons.edit, size: 14, color: cs.onSurface),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          ProfileStore.name,
          style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (_isSignedIn && ProfileStore.email != null) ...[
          const SizedBox(height: 4),
          Text(
            ProfileStore.email!,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        if (!_isSignedIn)
          FilledButton.icon(
            onPressed: _handleSignIn,
            icon: Icon(Icons.login, color: onAccent, size: 22),
            label: Text('Sign in with Google', style: TextStyle(color: onAccent, fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
          )
        else
          TextButton(
            onPressed: _handleSignOut,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
            child: const Text('Sign out', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
          ),
      ],
    );
  }
}

const Set<String> _kProductIds = {'donate_small', 'donate_medium', 'donate_large'};

class _DonateDialog extends StatefulWidget {
  const _DonateDialog();

  @override
  State<_DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<_DonateDialog> {
  final InAppPurchase _iap = InAppPurchase.instance;
  late final Stream<List<PurchaseDetails>> _purchaseStream;
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _available = false;
  String? _pendingId;

  @override
  void initState() {
    super.initState();
    _purchaseStream = _iap.purchaseStream;
    _purchaseStream.listen(_onPurchaseUpdated);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      setState(() => _loading = false);
      return;
    }
    final response = await _iap.queryProductDetails(_kProductIds);
    setState(() {
      _products = response.productDetails
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      _loading = false;
    });
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        _iap.completePurchase(p);
        if (mounted) {
          setState(() => _pendingId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your support! ❤️')),
          );
          Navigator.of(context).pop();
        }
      } else if (p.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() => _pendingId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Purchase failed: ${p.error?.message ?? "Unknown error"}')),
          );
        }
      } else if (p.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _pendingId = null);
      }
      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p);
      }
    }
  }

  void _buy(ProductDetails product) {
    setState(() => _pendingId = product.id);
    final param = PurchaseParam(productDetails: product);
    _iap.buyConsumable(purchaseParam: param);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.pinkAccent, size: 24),
          const SizedBox(width: 8),
          Text('Support Mileaged', style: TextStyle(color: cs.onSurface)),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : !_available
              ? Text(
                  'In-app purchases are not available on this device.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                )
              : _products.isEmpty
                  ? Text(
                      'No donation options available right now. Please try again later.',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'If you enjoy using Mileaged, consider supporting the developer with a small donation.',
                          style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ..._products.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary.withOpacity(0.15),
                                    foregroundColor: cs.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _pendingId == null ? () => _buy(product) : null,
                                  child: _pendingId == product.id
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                                        )
                                      : Text(
                                          '${product.title} — ${product.price}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            )),
                      ],
                    ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        enableFeedback: false,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? cs.onSurface).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: iconWidget ?? Icon(icon, color: iconColor ?? cs.onSurface, size: 20)),
        ),
        title: Text(title, style: TextStyle(color: cs.onSurface)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
        trailing: trailing == const SizedBox.shrink()
            ? null
            : trailing ?? Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.3)),
        onTap: onTap,
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: const Color(0xFF1C1C1E), width: 2.5)
              : Border.all(color: Colors.black.withOpacity(0.1), width: 1),
        ),
        child: isSelected
            ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 14)
            : null,
      ),
    );
  }
}

class _EditVehicleDialog extends StatefulWidget {
  final Vehicle vehicle;
  final void Function(String name, Uint8List? imageBytes) onSave;

  const _EditVehicleDialog({required this.vehicle, required this.onSave});

  @override
  State<_EditVehicleDialog> createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends State<_EditVehicleDialog> {
  late final TextEditingController _nameCtrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vehicle.name);
    _imageBytes = widget.vehicle.imageBytes;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Vehicle',
                style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Vehicle Name',
                hintText: 'e.g. Activa 125',
                prefixIcon: const Icon(Icons.two_wheeler),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                pickImageFile(
                  (bytes) => setState(() => _imageBytes = bytes),
                  (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $error')),
                    );
                  },
                );
              },
              child: _imageBytes != null
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: const Color(0xFF8E8E93), size: 32),
                          const SizedBox(height: 8),
                          const Text('Tap to add image',
                              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                        ],
                      ),
                    ),
            ),
            if (_imageBytes != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _imageBytes = null),
                  child: const Text('Remove image',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: accent),
                    ),
                    child: Text('Cancel', style: TextStyle(color: accent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a vehicle name')),
                        );
                        return;
                      }
                      widget.onSave(name, _imageBytes);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleDialog extends StatefulWidget {
  final void Function(Vehicle) onAdd;

  const _AddVehicleDialog({required this.onAdd});

  @override
  State<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<_AddVehicleDialog> {
  final _nameCtrl = TextEditingController();
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add New Vehicle',
                style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Vehicle Name',
                hintText: 'e.g. Activa 125',
                prefixIcon: const Icon(Icons.two_wheeler),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                pickImageFile(
                  (bytes) => setState(() => _imageBytes = bytes),
                  (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $error')),
                    );
                  },
                );
              },
              child: _imageBytes != null
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: const Color(0xFF8E8E93), size: 32),
                          const SizedBox(height: 8),
                          const Text('Tap to add image',
                              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                        ],
                      ),
                    ),
            ),
            if (_imageBytes != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _imageBytes = null),
                  child: const Text('Remove image',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: accent),
                    ),
                    child: Text('Cancel', style: TextStyle(color: accent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a vehicle name')),
                        );
                        return;
                      }
                      widget.onAdd(Vehicle(name: name, imageBytes: _imageBytes));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color currentColor;
  final void Function(Color) onColorSelected;
  final void Function(Color) onColorSaved;

  const _ColorPickerDialog({required this.currentColor, required this.onColorSelected, required this.onColorSaved});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.currentColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _selectedColor => HSVColor.fromAHSV(1, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pick a Color',
                style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Saturation-Value picker area
            SizedBox(
              width: 260,
              height: 200,
              child: GestureDetector(
                onPanUpdate: (d) => _updateSV(d.localPosition, const Size(260, 200)),
                onTapDown: (d) => _updateSV(d.localPosition, const Size(260, 200)),
                child: CustomPaint(
                  size: const Size(260, 200),
                  painter: _SVPainter(hue: _hue),
                  child: Stack(
                    children: [
                      Positioned(
                        left: (_saturation * 260).clamp(0, 260) - 10,
                        top: ((1 - _value) * 200).clamp(0, 200) - 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hue slider
            SizedBox(
              width: 260,
              height: 24,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() {
                  _hue = (d.localPosition.dx / 260 * 360).clamp(0, 360);
                }),
                onTapDown: (d) => setState(() {
                  _hue = (d.localPosition.dx / 260 * 360).clamp(0, 360);
                }),
                child: CustomPaint(
                  size: const Size(260, 24),
                  painter: _HuePainter(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: (_hue / 360 * 260).clamp(0, 260) - 8,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Preview + color info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () => widget.onColorSaved(_selectedColor),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateSV(Offset pos, Size size) {
    setState(() {
      _saturation = (pos.dx / size.width).clamp(0, 1);
      _value = 1 - (pos.dy / size.height).clamp(0, 1);
    });
  }
}

class _SVPainter extends CustomPainter {
  final double hue;
  _SVPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // White to hue gradient (left to right)
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(rect, Paint()..shader = LinearGradient(
      colors: [Colors.white, hueColor],
    ).createShader(rect));
    // Transparent to black gradient (top to bottom)
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    ).createShader(rect));
    // Rounded clip border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..style = PaintingStyle.stroke..color = Colors.black.withOpacity(0.1)..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SVPainter old) => hue != old.hue;
}

class _HuePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = List.generate(7, (i) => HSVColor.fromAHSV(1, i * 60, 1, 1).toColor());
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
