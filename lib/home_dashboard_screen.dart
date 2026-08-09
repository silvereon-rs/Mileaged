import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'main.dart';
import 'models.dart';
import 'profile_store.dart';
import 'mileage_history_screen.dart';
import 'refueling_history_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final List<MileageRecord> mileageHistory;
  final List<RefuelingRecord> refuelingHistory;
  final double? meanMileage;
  final String vehicleName;
  final void Function(int, RefuelingRecord)? onRefuelEdited;

  const HomeDashboardScreen({
    super.key,
    required this.mileageHistory,
    required this.refuelingHistory,
    required this.meanMileage,
    required this.vehicleName,
    this.onRefuelEdited,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String? _selectedMonth; // null = "All Time"

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final current = '${_monthName(now.month)} ${now.year}';
    final available = _getAvailableMonths();
    _selectedMonth = available.contains(current) ? current : available.isNotEmpty ? available.first : null;
  }

  List<String> _getAvailableMonths() {
    final months = <String>{};
    for (final r in widget.mileageHistory) {
      months.add('${_monthName(r.date.month)} ${r.date.year}');
    }
    for (final r in widget.refuelingHistory) {
      months.add('${_monthName(r.date.month)} ${r.date.year}');
    }
    final sorted = months.toList()
      ..sort((a, b) {
        final pa = _parseMonthYear(a);
        final pb = _parseMonthYear(b);
        return pb.compareTo(pa); // newest first
      });
    return sorted;
  }

  DateTime _parseMonthYear(String s) {
    final parts = s.split(' ');
    final month = _monthNumber(parts[0]);
    final year = int.parse(parts[1]);
    return DateTime(year, month);
  }

  static String _monthName(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  static int _monthNumber(String name) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'].indexOf(name) + 1;

  List<MileageRecord> get _filteredMileage {
    if (_selectedMonth == null) return widget.mileageHistory;
    final dt = _parseMonthYear(_selectedMonth!);
    return widget.mileageHistory.where((r) => r.date.year == dt.year && r.date.month == dt.month).toList();
  }

  List<RefuelingRecord> get _filteredRefueling {
    if (_selectedMonth == null) return widget.refuelingHistory;
    final dt = _parseMonthYear(_selectedMonth!);
    return widget.refuelingHistory.where((r) => r.date.year == dt.year && r.date.month == dt.month).toList();
  }

  Widget _buildAvatar(Uint8List? imageBytes, String? photoUrl, double radius, Color accent, ColorScheme cs) {
    final size = radius * 2;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surface),
      child: Icon(Icons.person, color: accent, size: radius),
    );
    if (imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          imageBytes,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    } else if (photoUrl != null) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _selectedMonth is valid for the dropdown
    if (_selectedMonth != null && !_getAvailableMonths().contains(_selectedMonth)) {
      _selectedMonth = _getAvailableMonths().isNotEmpty ? _getAvailableMonths().first : null;
    }

    final mileageHistory = _filteredMileage;
    final refuelingHistory = _filteredRefueling;
    final meanMileage = mileageHistory.isNotEmpty
        ? mileageHistory.fold<double>(0, (s, r) => s + r.mileage) / mileageHistory.length
        : widget.meanMileage;
    final totalDistance = mileageHistory.fold<double>(0, (s, r) => s + r.distance);
    final totalFuelFilled = refuelingHistory.fold<double>(0, (s, r) => s + r.fuelFilled);
    final totalCost = refuelingHistory
        .where((r) => r.cost != null)
        .fold<double>(0, (s, r) => s + r.cost!);

    // Total kms from odometer (last end - first start)
    final totalKms = mileageHistory.isNotEmpty
        ? mileageHistory.last.endOdometer - mileageHistory.first.startOdometer
        : 0.0;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = AccentColorScope.onAccent(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = ProfileStore.name;
    final userPhoto = ProfileStore.photoUrl;
    final userImageBytes = ProfileStore.imageBytes;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildAvatar(userImageBytes, userPhoto, 24, accent, cs),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                    ),
                    Text(
                      user,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedMonth,
                      isDense: true,
                      dropdownColor: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      icon: Icon(Icons.keyboard_arrow_down, color: cs.onSurface, size: 16),
                      style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Time'),
                        ),
                        ..._getAvailableMonths().map((m) => DropdownMenuItem<String?>(
                          value: m,
                          child: Text(m),
                        )),
                      ],
                      onChanged: (v) => setState(() => _selectedMonth = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress Card (dark)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mileage',
                    style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  if (mileageHistory.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _BarChartPainter(records: mileageHistory, meanMileage: meanMileage, accentColor: accent, unitLabel: UnitScope.mileageUnit(context)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 150,
                      child: Center(
                        child: Text(
                          'Start tracking to see your progress',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stat cards
            Row(
              children: [
                Expanded(
                  child: _LimeStatCard(
                    label: 'Avg Mileage',
                    value: meanMileage != null ? UnitScope.mileage(context, meanMileage!).toStringAsFixed(1) : '--',
                    unit: UnitScope.mileageUnit(context),
                    bgColor: accent,
                    textColor: onAccent,
                    arrowBgColor: onAccent.withOpacity(0.2),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MileageHistoryScreen(records: mileageHistory))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LimeStatCard(
                    label: 'Total Fuel',
                    value: UnitScope.volume(context, totalFuelFilled).toStringAsFixed(1),
                    unit: UnitScope.volumeUnit(context),
                    bgColor: cs.surface,
                    textColor: cs.onSurface,
                    onTap: () async {
                      await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => RefuelingHistoryScreen(records: widget.refuelingHistory, onRefuelEdited: widget.onRefuelEdited)));
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row (dark themed)
            Row(
              children: [
                _StatChip(icon: Icons.location_on_outlined, label: '${UnitScope.distance(context, totalKms).toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}'),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.currency_rupee, label: '${UnitScope.currency(context)}${totalCost.toStringAsFixed(0)}'),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.local_gas_station_outlined, label: '${refuelingHistory.length} refuels'),
              ],
            ),
            const SizedBox(height: 24),

            // Comparison
            if (mileageHistory.length >= 2) ...[
              _buildComparisonCard(mileageHistory, accent),
              const SizedBox(height: 24),
            ],

            // Last 5 Refuels
            if (refuelingHistory.isNotEmpty) ...[
              _buildRecentRefuelsCard(refuelingHistory, cs),
              const SizedBox(height: 24),
            ],

            if (mileageHistory.isEmpty && refuelingHistory.isEmpty)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  children: [
                    Icon(Icons.speed, size: 48, color: Color(0xFFC7C7CC)),
                    SizedBox(height: 12),
                    Text('No records yet', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Start tracking your mileage!', style: TextStyle(color: Color(0xFFC7C7CC), fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(List<MileageRecord> mileageHistory, Color accent) {
    final latest = mileageHistory.last.mileage;
    final prev = mileageHistory.sublist(0, mileageHistory.length - 1);
    final expected = prev.fold<double>(0, (s, r) => s + r.mileage) / prev.length;
    final diff = latest - expected;
    final pct = expected > 0 ? (diff / expected) * 100 : 0.0;
    final isUp = diff >= 0;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actual vs Expected',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _CompareCol(label: 'Latest', value: UnitScope.mileage(context, latest).toStringAsFixed(2), unit: UnitScope.mileageUnit(context), color: accent)),
            Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
            Expanded(child: _CompareCol(label: 'Expected', value: UnitScope.mileage(context, expected).toStringAsFixed(2), unit: UnitScope.mileageUnit(context), color: Colors.white70)),
            Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
            Expanded(child: Column(children: [
              Text('Diff', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: accent, size: 20),
                Text('${pct.abs().toStringAsFixed(1)}%',
                  style: TextStyle(color: accent,
                    fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ])),
          ]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (latest / (math.max(latest, expected) * 1.2)).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRecentRefuelsCard(List<RefuelingRecord> records, ColorScheme cs) {
    final recent = records.length > 5 ? records.sublist(records.length - 5).reversed.toList() : records.reversed.toList();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Refuels', style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...recent.map((r) {
            final dateStr = '${r.date.day} ${months[r.date.month - 1]}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.local_gas_station, size: 18, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r.fuelFilled.toStringAsFixed(2)} L', style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(dateStr, style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (r.cost != null)
                    Text('${UnitScope.currency(context)}${r.cost!.toStringAsFixed(0)}', style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LimeStatCard extends StatelessWidget {
  final String label, value, unit;
  final Color bgColor;
  final Color textColor;
  final Color? arrowBgColor;
  final VoidCallback? onTap;
  const _LimeStatCard({required this.label, required this.value, required this.unit, required this.bgColor, required this.textColor, this.arrowBgColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final effectiveArrowBg = arrowBgColor ?? textColor.withOpacity(0.15);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: bgColor != Theme.of(context).colorScheme.primary
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: effectiveArrowBg, shape: BoxShape.circle),
              child: Icon(Icons.north_east, size: 20, color: textColor)),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _CompareCol extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _CompareCol({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis)),
      ]),
    ));
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MileageRecord> records;
  final double? meanMileage;
  final Color accentColor;
  final String unitLabel;
  _BarChartPainter({required this.records, this.meanMileage, required this.accentColor, required this.unitLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final display = records.length > 7 ? records.sublist(records.length - 7) : records;
    final values = display.map((r) => r.mileage).toList();
    final maxVal = values.reduce(math.max) * 1.2;
    if (maxVal == 0) return;

    final avg = meanMileage ?? (values.reduce((a, b) => a + b) / values.length);

    const leftPad = 40.0;
    const barCount = 7;
    final chartW = size.width - leftPad;
    final barWidth = chartW / barCount * 0.45;
    final spacing = chartW / barCount;
    final chartH = size.height - 20;

    // Y-axis labels (numbers only, no unit prefix)
    const ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      final y = chartH - (chartH * i / ySteps);
      final val = (maxVal * i / ySteps).toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(text: val, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y),
        Paint()..color = Colors.white.withOpacity(0.08)..strokeWidth = 1);
    }

    // km/l unit label — below y-axis
    final unitTp = TextPainter(
      text: TextSpan(text: unitLabel, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    unitTp.paint(canvas, Offset(leftPad / 2 - unitTp.width / 2, chartH + 6));

    // Bars
    for (int i = 0; i < barCount; i++) {
      final x = leftPad + i * spacing + (spacing - barWidth) / 2;
      final hasData = i < values.length;
      final barH = hasData ? (values[i] / maxVal) * chartH : chartH * 0.25;
      final isAboveAvg = hasData && values[i] >= avg;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartH - barH, barWidth, barH), const Radius.circular(8));

      final color = hasData
          ? (isAboveAvg ? accentColor : const Color(0xFF3A3A3C))
          : Colors.white.withOpacity(0.06);
      canvas.drawRRect(rect, Paint()..color = color);

      if (hasData) {
        final tp = TextPainter(
          text: TextSpan(text: '${display[i].date.day}/${display[i].date.month}',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
          textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, chartH + 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => true;
}

class _MileageTile extends StatelessWidget {
  final MileageRecord record;
  const _MileageTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.speed, color: Theme.of(context).colorScheme.onSurface, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${UnitScope.mileage(context, record.mileage).toStringAsFixed(2)} ${UnitScope.mileageUnit(context)}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Row(children: [
            _TripInfo('Distance', '${UnitScope.distance(context, record.distance).toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}'),
            const SizedBox(width: 16),
            _TripInfo('Fuel', '${UnitScope.volume(context, record.fuelUsed).toStringAsFixed(1)} ${UnitScope.volumeUnitShort(context)}'),
          ]),
        ])),
        Container(width: 28, height: 28,
          decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.north_east, size: 14, color: Color(0xFF8E8E93))),
      ]),
    );
  }
}

class _TripInfo extends StatelessWidget {
  final String label, value;
  const _TripInfo(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 10)),
      Text(value, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _RefuelTile extends StatelessWidget {
  final RefuelingRecord record;
  const _RefuelTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: const Color(0xFF34C759).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.local_gas_station, color: Color(0xFF34C759), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${UnitScope.volume(context, record.fuelFilled).toStringAsFixed(1)} ${UnitScope.volumeUnitShort(context)}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Row(children: [
            if (record.cost != null) _TripInfo('Cost', '₹${record.cost!.toStringAsFixed(0)}'),
            if (record.cost != null) const SizedBox(width: 16),
            _TripInfo('Range', '${UnitScope.distance(context, record.range).toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}'),
          ]),
        ])),
        Text('${record.date.day}/${record.date.month}',
          style: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 12)),
      ]),
    );
  }
}