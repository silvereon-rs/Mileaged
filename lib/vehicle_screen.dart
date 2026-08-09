import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';
import 'models.dart';

class VehicleScreen extends StatelessWidget {
  final String currentVehicle;
  final void Function(String) onVehicleChanged;
  final Uint8List? vehicleImageBytes;
  final List<MileageRecord> mileageHistory;
  final List<RefuelingRecord> refuelingHistory;
  final double? meanMileage;
  final List<Vehicle> vehicles;
  final void Function(int) onVehicleIndexChanged;

  const VehicleScreen({
    super.key,
    required this.currentVehicle,
    required this.onVehicleChanged,
    this.vehicleImageBytes,
    required this.mileageHistory,
    required this.refuelingHistory,
    this.meanMileage,
    required this.vehicles,
    required this.onVehicleIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalKms = mileageHistory.isNotEmpty
        ? mileageHistory.last.endOdometer - mileageHistory.first.startOdometer
        : 0.0;
    final totalRefuelings = refuelingHistory.length;
    final displayMileage = meanMileage != null ? UnitScope.mileage(context, meanMileage!).toStringAsFixed(1) : '--';
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = AccentColorScope.onAccent(context);
    final currentIndex = vehicles.indexWhere((v) => v.name == currentVehicle);
    final hasVehicles = vehicles.isNotEmpty;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = cs.surface;
    final textColor = cs.onSurface;
    final secondaryText = cs.onSurface.withOpacity(0.5);

    // Refueling stats
    final totalFuelFilled = refuelingHistory.fold<double>(0, (s, r) => s + r.fuelFilled);
    final totalCost = refuelingHistory.fold<double>(0, (s, r) => s + (r.cost ?? 0));
    final lastRefuel = refuelingHistory.isNotEmpty ? refuelingHistory.last : null;

    // Best mileage
    final bestMileage = mileageHistory.isNotEmpty
        ? UnitScope.mileage(context, mileageHistory.map((r) => r.mileage).reduce(max)).toStringAsFixed(1)
        : '--';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top section: name + settings-like icon area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVehicleName(currentVehicle, textColor),
                        const SizedBox(height: 4),
                        Text(
                          '${UnitScope.distance(context, totalKms).toStringAsFixed(0)} ${UnitScope.distanceUnit(context)} driven  •  $totalRefuelings refuels',
                          style: TextStyle(color: secondaryText, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Vehicle dropdown
                  if (hasVehicles && vehicles.length > 1)
                    PopupMenuButton<int>(
                      onSelected: (idx) => onVehicleIndexChanged(idx),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      offset: const Offset(0, 48),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.keyboard_arrow_down, color: onAccent, size: 22),
                      ),
                      itemBuilder: (_) => vehicles.asMap().entries.map((entry) {
                        final isSelected = entry.key == currentIndex;
                        return PopupMenuItem<int>(
                          value: entry.key,
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(Icons.check, color: accent, size: 18)
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 10),
                              Text(
                                entry.value.name,
                                style: TextStyle(
                                  color: isSelected ? accent : textColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            // Vehicle image — zoomed, 3/4 visible
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow behind image in dark mode
                  if (isDark && vehicleImageBytes != null)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 300,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.25),
                                blurRadius: 150,
                                spreadRadius: 30,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Image — zoomed & clipped
                  vehicleImageBytes != null
                      ? ClipRect(
                          child: OverflowBox(
                            maxWidth: MediaQuery.of(context).size.width * 0.9,
                            maxHeight: double.infinity,
                            child: Image.memory(
                              vehicleImageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.two_wheeler, color: cs.onSurface.withOpacity(0.15), size: 100),
                            const SizedBox(height: 12),
                            Text('No image added', style: TextStyle(color: secondaryText, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Add one in Settings', style: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 12)),
                          ],
                        ),
                ],
              ),
            ),

            // Bottom section: stat cards + vehicle switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  // Two main stat cards
                  Row(
                    children: [
                      // Avg Mileage card (accent bg)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Avg Mileage', style: TextStyle(color: onAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: onAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.speed, size: 18, color: onAccent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    displayMileage,
                                    style: TextStyle(color: onAccent, fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(UnitScope.mileageUnit(context), style: TextStyle(color: onAccent.withOpacity(0.7), fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Best: $bestMileage ${UnitScope.mileageUnit(context)}',
                                style: TextStyle(color: onAccent.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Refueling card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Refueling', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: textColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.local_gas_station, size: 18, color: textColor.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${UnitScope.volume(context, totalFuelFilled).toStringAsFixed(1)}',
                                        style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(UnitScope.volumeUnit(context), style: TextStyle(color: secondaryText, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalCost > 0 ? '${UnitScope.currency(context)}${totalCost.toStringAsFixed(0)} spent' : '${refuelingHistory.length} refills',
                                style: TextStyle(color: secondaryText, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleName(String name, Color textColor) {
    final style = TextStyle(
      color: textColor,
      fontSize: 34,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      shadows: [
        Shadow(color: textColor, offset: const Offset(0.5, 0), blurRadius: 0.5),
        Shadow(color: textColor, offset: const Offset(-0.5, 0), blurRadius: 0.5),
      ],
    );
    return Text(name, style: style);
  }
}

