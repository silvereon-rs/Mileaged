import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'models.dart';
import 'file_helper.dart';
import 'drive_sync.dart';
import 'home_dashboard_screen.dart';
import 'mileage_calculator_screen.dart';
import 'vehicle_screen.dart';
import 'account_screen.dart';

class AppShell extends StatefulWidget {
  final void Function(Color) onAccentChanged;
  final void Function(Color) onAccentSaved;
  final List<Color> recentColors;
  final bool isDarkMode;
  final void Function(bool) onToggleDarkMode;
  final bool useMetric;
  final void Function(bool) onToggleUnit;

  const AppShell({super.key, required this.onAccentChanged, required this.onAccentSaved, required this.recentColors, required this.isDarkMode, required this.onToggleDarkMode, required this.useMetric, required this.onToggleUnit});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Vehicle list — all data lives inside each Vehicle
  List<Vehicle> _vehicles = [];
  int _activeVehicleIndex = 0;

  Vehicle get _activeVehicle => _vehicles[_activeVehicleIndex];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadVehiclesData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFuelAdded(double fuel, double? cost, double estRange, DateTime date, [double? startOdometer]) {
    setState(() {
      final v = _activeVehicle;
      final isTankFilling = v.refuelingHistory.isEmpty;
      if (startOdometer != null && v.mileageHistory.isEmpty && v.firstStartOdometer == null) {
        v.firstStartOdometer = startOdometer;
      }
      if (!isTankFilling) {
        v.accumulatedFuel += fuel;
      }
      v.accumulatedRange += estRange;
      v.refuelingHistory.add(RefuelingRecord(
        odometer: v.estimatedOdometer - estRange,
        fuelFilled: fuel,
        cost: cost,
        meanMileage: v.meanMileage ?? 0,
        range: estRange,
        finalOdometer: v.estimatedOdometer,
        date: date,
        isTankFilling: isTankFilling,
      ));
    });
    _saveVehiclesData();
  }

  void _onMileageAdded(MileageRecord record) {
    setState(() {
      _activeVehicle.mileageHistory.add(record);
      _activeVehicle.accumulatedFuel = 0;
      _activeVehicle.accumulatedRange = 0;
    });
    _saveVehiclesData();
  }

  void _onRefuelEdited(int index, RefuelingRecord updated) {
    setState(() {
      _activeVehicle.refuelingHistory[index] = updated;
    });
    _saveVehiclesData();
  }

  void _onVehicleChanged(String name) {
    setState(() {
      final idx = _vehicles.indexWhere((v) => v.name == name);
      if (idx >= 0) _activeVehicleIndex = idx;
    });
  }

  void _onVehicleImageChanged(Uint8List? bytes) {
    setState(() {
      _activeVehicle.imageBytes = bytes;
    });
    _saveVehiclesData();
  }

  void _addVehicle(Vehicle vehicle) {
    setState(() {
      _vehicles.add(vehicle);
      _activeVehicleIndex = _vehicles.length - 1;
    });
    _saveVehiclesData();
  }

  void _editVehicle(int index, String newName, Uint8List? newImage) {
    if (index < 0 || index >= _vehicles.length) return;
    setState(() {
      _vehicles[index].name = newName;
      _vehicles[index].imageBytes = newImage;
    });
    _saveVehiclesData();
  }

  void _deleteVehicle(int index) {
    if (index < 0 || index >= _vehicles.length || _vehicles.length <= 1) return;
    setState(() {
      _vehicles.removeAt(index);
      if (_activeVehicleIndex >= _vehicles.length) {
        _activeVehicleIndex = _vehicles.length - 1;
      }
    });
    _saveVehiclesData();
  }

  void _onVehicleIndexChanged(int index) {
    if (index < 0 || index >= _vehicles.length) return;
    setState(() {
      _activeVehicleIndex = index;
    });
    _saveVehiclesData();
  }

  Map<String, dynamic> _vehicleToJson(Vehicle v) {
    return {
      'name': v.name,
      'imageBase64': v.imageBytes != null ? base64Encode(v.imageBytes!) : null,
      'accumulatedFuel': v.accumulatedFuel,
      'accumulatedRange': v.accumulatedRange,
      'firstStartOdometer': v.firstStartOdometer,
      'mileageHistory': v.mileageHistory.map((r) => r.toJson()).toList(),
      'refuelingHistory': v.refuelingHistory.map((r) => r.toJson()).toList(),
    };
  }

  Vehicle _vehicleFromJson(Map<String, dynamic> data) {
    final v = Vehicle(
      name: data['name'] as String? ?? 'Vehicle',
      imageBytes: data['imageBase64'] != null ? base64Decode(data['imageBase64'] as String) : null,
    );
    v.accumulatedFuel = (data['accumulatedFuel'] as num?)?.toDouble() ?? 0;
    v.accumulatedRange = (data['accumulatedRange'] as num?)?.toDouble() ?? 0;
    v.firstStartOdometer = (data['firstStartOdometer'] as num?)?.toDouble();
    if (data['mileageHistory'] != null) {
      for (final item in data['mileageHistory'] as List) {
        v.mileageHistory.add(MileageRecord.fromJson(item as Map<String, dynamic>));
      }
    }
    if (data['refuelingHistory'] != null) {
      for (final item in data['refuelingHistory'] as List) {
        v.refuelingHistory.add(RefuelingRecord.fromJson(item as Map<String, dynamic>));
      }
    }
    return v;
  }

  Future<void> _loadVehiclesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('vehicles_data');
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final version = data['version'] as int? ?? 1;
        setState(() {
          if (version >= 2 && data['vehicles'] != null) {
            _vehicles.clear();
            for (final item in data['vehicles'] as List) {
              _vehicles.add(_vehicleFromJson(item as Map<String, dynamic>));
            }
            _activeVehicleIndex = (data['activeVehicleIndex'] as int?) ?? 0;
            if (_activeVehicleIndex >= _vehicles.length) _activeVehicleIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load vehicles data: $e');
    }
  }

  Future<void> _saveVehiclesData() async {
    try {
      final data = {
        'version': 2,
        'activeVehicleIndex': _activeVehicleIndex,
        'vehicles': _vehicles.map((v) => _vehicleToJson(v)).toList(),
      };
      final jsonStr = jsonEncode(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vehicles_data', jsonStr);
    } catch (e) {
      debugPrint('Failed to save vehicles data: $e');
    }
  }

  void _exportData() {
    final data = {
      'version': 2,
      'exportDate': DateTime.now().toIso8601String(),
      'activeVehicleIndex': _activeVehicleIndex,
      'vehicles': _vehicles.map((v) => _vehicleToJson(v)).toList(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final filename = 'mileaged_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    exportJsonFile(jsonStr, filename);
  }

  void _importData() {
    importJsonFile(
      (jsonStr) {
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final version = data['version'] as int? ?? 1;
          setState(() {
            if (version >= 2 && data['vehicles'] != null) {
              // v2 format: all vehicles
              _vehicles.clear();
              for (final item in data['vehicles'] as List) {
                _vehicles.add(_vehicleFromJson(item as Map<String, dynamic>));
              }
              _activeVehicleIndex = (data['activeVehicleIndex'] as int?) ?? 0;
              if (_activeVehicleIndex >= _vehicles.length) _activeVehicleIndex = 0;
            } else if (_vehicles.isNotEmpty) {
              // v1 legacy format: single vehicle into active
              final v = _activeVehicle;
              v.name = data['currentVehicle'] as String? ?? v.name;
              v.accumulatedFuel = (data['accumulatedFuel'] as num?)?.toDouble() ?? 0;
              v.accumulatedRange = (data['accumulatedRange'] as num?)?.toDouble() ?? 0;
              v.firstStartOdometer = (data['firstStartOdometer'] as num?)?.toDouble();
              v.mileageHistory.clear();
              if (data['mileageHistory'] != null) {
                for (final item in data['mileageHistory'] as List) {
                  v.mileageHistory.add(MileageRecord.fromJson(item as Map<String, dynamic>));
                }
              }
              v.refuelingHistory.clear();
              if (data['refuelingHistory'] != null) {
                for (final item in data['refuelingHistory'] as List) {
                  v.refuelingHistory.add(RefuelingRecord.fromJson(item as Map<String, dynamic>));
                }
              }
            }
          });
          _saveVehiclesData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Imported ${_vehicles.length} vehicle(s) successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Import failed: ${e.toString()}')),
            );
          }
        }
      },
      (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $error')),
          );
        }
      },
    );
  }

  String _buildBackupJson() {
    final data = {
      'version': 2,
      'exportDate': DateTime.now().toIso8601String(),
      'activeVehicleIndex': _activeVehicleIndex,
      'vehicles': _vehicles.map((v) => _vehicleToJson(v)).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  void _restoreFromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final version = data['version'] as int? ?? 1;
    setState(() {
      if (version >= 2 && data['vehicles'] != null) {
        _vehicles.clear();
        for (final item in data['vehicles'] as List) {
          _vehicles.add(_vehicleFromJson(item as Map<String, dynamic>));
        }
        _activeVehicleIndex = (data['activeVehicleIndex'] as int?) ?? 0;
        if (_activeVehicleIndex >= _vehicles.length) _activeVehicleIndex = 0;
      } else if (_vehicles.isNotEmpty) {
        // v1 legacy format
        final v = _activeVehicle;
        v.name = data['currentVehicle'] as String? ?? v.name;
        v.accumulatedFuel = (data['accumulatedFuel'] as num?)?.toDouble() ?? 0;
        v.accumulatedRange = (data['accumulatedRange'] as num?)?.toDouble() ?? 0;
        v.firstStartOdometer = (data['firstStartOdometer'] as num?)?.toDouble();
        v.mileageHistory.clear();
        if (data['mileageHistory'] != null) {
          for (final item in data['mileageHistory'] as List) {
            v.mileageHistory.add(MileageRecord.fromJson(item as Map<String, dynamic>));
          }
        }
        v.refuelingHistory.clear();
        if (data['refuelingHistory'] != null) {
          for (final item in data['refuelingHistory'] as List) {
            v.refuelingHistory.add(RefuelingRecord.fromJson(item as Map<String, dynamic>));
          }
        }
      }
    });
    _saveVehiclesData();
  }

  Future<void> _syncUpload() async {
    final jsonStr = _buildBackupJson();
    final success = await DriveSync.uploadBackup(jsonStr);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Backup synced to Google Drive' : 'Sync failed — check sign-in')),
      );
    }
  }

  Future<void> _syncDownload() async {
    final jsonStr = await DriveSync.downloadBackup();
    if (jsonStr == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backup found on Drive')),
        );
      }
      return;
    }
    try {
      _restoreFromJson(jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored ${_vehicles.length} vehicle(s) from Drive')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  void _clearAllData() {
    _pageController.dispose();
    _pageController = PageController();
    setState(() {
      _vehicles.clear();
      _activeVehicleIndex = 0;
      _currentIndex = 0;
    });
    _saveVehiclesData();
  }

  void _showAddFirstVehicleDialog(BuildContext context) {
    final controller = TextEditingController();
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Vehicle', style: TextStyle(color: cs.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: 'Vehicle Name',
            hintText: 'e.g. Activa 125',
            prefixIcon: const Icon(Icons.two_wheeler),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              _addVehicle(Vehicle(name: name));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: accent),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    final onAccent = AccentColorScope.onAccent(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.two_wheeler, size: 80, color: accent.withOpacity(0.6)),
              const SizedBox(height: 24),
              Text(
                'Welcome to Mileaged',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your first vehicle to start tracking mileage',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _showAddFirstVehicleDialog(context),
                icon: Icon(Icons.add, color: onAccent),
                label: Text('Add Vehicle', style: TextStyle(color: onAccent, fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_vehicles.isEmpty) {
      return _buildEmptyState(context);
    }
    final v = _activeVehicle;
    final screens = [
      HomeDashboardScreen(
        mileageHistory: v.mileageHistory,
        refuelingHistory: v.refuelingHistory,
        meanMileage: v.meanMileage,
        vehicleName: v.name,
        onRefuelEdited: _onRefuelEdited,
      ),
      MileageCalculatorScreen(
        onMileageAdded: _onMileageAdded,
        onFuelAdded: _onFuelAdded,
        mileageHistory: v.mileageHistory,
        refuelingHistory: v.refuelingHistory,
        meanMileage: v.meanMileage,
        accumulatedFuel: v.accumulatedFuel,
        lastEndOdometer: v.mileageHistory.isNotEmpty
            ? v.mileageHistory.last.endOdometer
            : v.firstStartOdometer,
        estimatedOdometer: v.estimatedOdometer,
      ),
      VehicleScreen(
        currentVehicle: v.name,
        onVehicleChanged: _onVehicleChanged,
        vehicleImageBytes: v.imageBytes,
        mileageHistory: v.mileageHistory,
        refuelingHistory: v.refuelingHistory,
        meanMileage: v.meanMileage,
        vehicles: _vehicles,
        onVehicleIndexChanged: _onVehicleIndexChanged,
      ),
      AccountScreen(
        onExportData: _exportData,
        onImportData: _importData,
        onClearData: _clearAllData,
        onSyncUpload: _syncUpload,
        onSyncDownload: _syncDownload,
        vehicleImageBytes: v.imageBytes,
        onVehicleImageChanged: _onVehicleImageChanged,
        vehicles: _vehicles,
        onAddVehicle: _addVehicle,
        onEditVehicle: _editVehicle,
        onDeleteVehicle: _deleteVehicle,
        onAccentChanged: widget.onAccentChanged,
        onAccentSaved: widget.onAccentSaved,
        recentColors: widget.recentColors,
        isDarkMode: widget.isDarkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
        useMetric: widget.useMetric,
        onToggleUnit: widget.onToggleUnit,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7);
    final navBorder = isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3);

    return Scaffold(
      extendBody: true,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: screens.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - value.abs() * 0.15).clamp(0.85, 1.0);
              }
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: screens[index],
          );
        },
      ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: navBorder, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(child: _buildNavItem(0, Icons.home_rounded)),
                    Flexible(child: _buildCenterNavItem()),
                    Flexible(child: _buildNavItem(2, Icons.directions_bike_rounded)),
                    Flexible(child: _buildNavItem(3, Icons.person_rounded)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isActive = _currentIndex == index;
    final accent = Theme.of(context).colorScheme.primary;
    final onAccentColor = AccentColorScope.onAccent(context);
    return GestureDetector(
        onTap: () {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 46,
          child: Container(
            decoration: isActive
                ? BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14),
                  )
                : null,
            child: Center(
              child: Icon(
                icon,
                size: 24,
                color: isActive ? onAccentColor : const Color(0xFFC7C7CC),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildCenterNavItem() {
    final isActive = _currentIndex == 1;
    final accent = Theme.of(context).colorScheme.primary;
    final onAccentColor = AccentColorScope.onAccent(context);
    return GestureDetector(
        onTap: () {
          _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 46,
          child: Container(
            decoration: isActive
                ? BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14),
                  )
                : null,
            child: Center(
              child: Icon(
                Icons.local_gas_station_rounded,
                color: isActive ? onAccentColor : const Color(0xFFC7C7CC),
                size: 24,
              ),
            ),
          ),
        ),
    );
  }
}
