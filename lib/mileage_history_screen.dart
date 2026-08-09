import 'package:flutter/material.dart';
import 'models.dart';
import 'main.dart';

class MileageHistoryScreen extends StatelessWidget {
  final List<MileageRecord> records;

  const MileageHistoryScreen({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mileage History'),
        centerTitle: true,
      ),
      body: records.isEmpty
          ? Center(
              child: Text('No mileage records yet.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.5))))
          : _buildList(context, cs),
    );
  }

  Widget _buildList(BuildContext context, ColorScheme cs) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    // Reversed list (newest first)
    final sorted = records.reversed.toList();

    // Build items with month dividers
    final widgets = <Widget>[];
    String? lastMonthKey;
    for (final record in sorted) {
      final monthKey = '${months[record.date.month - 1]} ${record.date.year}';
      if (monthKey != lastMonthKey) {
        if (lastMonthKey != null) const SizedBox(height: 4);
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: lastMonthKey != null ? 12 : 0, bottom: 8),
            child: Text(
              monthKey,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        lastMonthKey = monthKey;
      }
      widgets.add(_buildRecordCard(context, record, cs, months));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: widgets,
    );
  }

  Widget _buildRecordCard(BuildContext context, MileageRecord record, ColorScheme cs, List<String> months) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 70,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${record.date.day} ${months[record.date.month - 1]}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AccentColorScope.onAccent(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${UnitScope.mileage(context, record.mileage).toStringAsFixed(2)} ${UnitScope.mileageUnit(context)}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${UnitScope.distance(context, record.distance).toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}  •  ${UnitScope.volume(context, record.fuelUsed).toStringAsFixed(1)} ${UnitScope.volumeUnitShort(context)}  •  Odo: ${record.startOdometer.toStringAsFixed(1)}→${record.endOdometer.toStringAsFixed(1)}',
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}