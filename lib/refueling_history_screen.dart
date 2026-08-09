import 'package:flutter/material.dart';
import 'models.dart';
import 'main.dart';
import 'edit_refueling_screen.dart';

class RefuelingHistoryScreen extends StatefulWidget {
  final List<RefuelingRecord> records;
  final void Function(int, RefuelingRecord)? onRefuelEdited;

  const RefuelingHistoryScreen({super.key, required this.records, this.onRefuelEdited});

  @override
  State<RefuelingHistoryScreen> createState() => _RefuelingHistoryScreenState();
}

class _RefuelingHistoryScreenState extends State<RefuelingHistoryScreen> {
  List<RefuelingRecord> get records => widget.records;
  void Function(int, RefuelingRecord)? get onRefuelEdited => widget.onRefuelEdited;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refueling History'),
        centerTitle: true,
      ),
      body: records.isEmpty
          ? Center(
              child: Text('No refueling records yet.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.5))))
          : _buildList(context, cs),
    );
  }

  Widget _buildList(BuildContext context, ColorScheme cs) {
    final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final sorted = records.reversed.toList();

    final widgets = <Widget>[];
    String? lastMonthKey;
    for (var i = 0; i < sorted.length; i++) {
      final record = sorted[i];
      final originalIndex = records.length - 1 - i;
      final monthKey = '${monthNames[record.date.month - 1]} ${record.date.year}';
      if (monthKey != lastMonthKey) {
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
      widgets.add(_buildRecordCard(context, record, originalIndex, cs, monthNames));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: widgets,
    );
  }

  Widget _buildRecordCard(BuildContext context, RefuelingRecord record, int originalIndex, ColorScheme cs, List<String> monthNames) {
    return GestureDetector(
      onTap: onRefuelEdited != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditRefuelingScreen(
                    record: record,
                    index: originalIndex,
                    onSave: (i, updated) {
                      onRefuelEdited!(i, updated);
                      setState(() {});
                    },
                  ),
                ),
              );
            }
          : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
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
                '${record.date.day} ${monthNames[record.date.month - 1]}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AccentColorScope.onAccent(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
                  '${record.fuelFilled.toStringAsFixed(2)} L${record.cost != null ? '  \u2022  ${UnitScope.currency(context)}${record.cost!.toStringAsFixed(0)}' : ''}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Odo: ${record.odometer.toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}  •  ${UnitScope.mileage(context, record.meanMileage).toStringAsFixed(2)} ${UnitScope.mileageUnit(context)}',
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          if (onRefuelEdited != null)
            Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.3), size: 20),
        ],
      ),
      ),
    );
  }
}
