import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'models.dart';
import 'mileage_history_screen.dart';
import 'refueling_history_screen.dart';

class MileageCalculatorScreen extends StatefulWidget {
  final void Function(MileageRecord) onMileageAdded;
  final void Function(double fuel, double? cost, double estRange, DateTime date, [double? startOdometer]) onFuelAdded;
  final List<MileageRecord> mileageHistory;
  final List<RefuelingRecord> refuelingHistory;
  final double? meanMileage;
  final double accumulatedFuel;
  final double? lastEndOdometer;
  final double estimatedOdometer; // start odo + accumulated range

  const MileageCalculatorScreen({
    super.key,
    required this.onMileageAdded,
    required this.onFuelAdded,
    required this.mileageHistory,
    required this.refuelingHistory,
    required this.meanMileage,
    required this.accumulatedFuel,
    required this.lastEndOdometer,
    required this.estimatedOdometer,
  });

  @override
  State<MileageCalculatorScreen> createState() =>
      _MileageCalculatorScreenState();
}

class _MileageCalculatorScreenState extends State<MileageCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startOdoCtrl = TextEditingController();
  final _endOdoCtrl = TextEditingController();
  final _newFuelCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  double? _lastMileage;
  double? _lastRange;
  bool _isFirstEntry = true;
  String _category = 'Refueling'; // 'Refueling' or 'Tank to Tank'
  DateTime _selectedDate = DateTime.now();

  @override
  void didUpdateWidget(covariant MileageCalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStartOdo();
  }

  double _previewFuel = 0;
  double _previewRange = 0;

  @override
  void initState() {
    super.initState();
    _syncStartOdo();
    _newFuelCtrl.addListener(_onFuelTextChanged);
  }

  void _onFuelTextChanged() {
    final fuel = double.tryParse(_newFuelCtrl.text.trim()) ?? 0;
    final range = (widget.meanMileage != null && fuel > 0) ? double.parse((fuel * widget.meanMileage!).toStringAsFixed(1)) : 0.0;
    if (fuel != _previewFuel) {
      setState(() {
        _previewFuel = fuel;
        _previewRange = range;
      });
    }
  }

  void _syncStartOdo() {
    if (widget.lastEndOdometer != null) {
      _startOdoCtrl.text = widget.lastEndOdometer!.toStringAsFixed(1);
      _isFirstEntry = false;
    } else {
      _isFirstEntry = true;
    }
  }

  void _addFuelOnly() {
    // Validate start odometer
    final startText = _startOdoCtrl.text.trim();
    if (startText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter starting odometer first')),
      );
      return;
    }
    if (double.tryParse(startText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid odometer reading')),
      );
      return;
    }

    final fuelText = _newFuelCtrl.text.trim();
    if (fuelText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter fuel amount')),
      );
      return;
    }
    final fuel = double.tryParse(fuelText);
    if (fuel == null || fuel <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid fuel amount')),
      );
      return;
    }

    final costText = _costCtrl.text.trim();
    final cost = costText.isEmpty ? null : double.tryParse(costText);

    // Calculate estimated range for this refuel
    final estRange = widget.meanMileage != null ? double.parse((fuel * widget.meanMileage!).toStringAsFixed(1)) : 0.0;

    // Pass start odo on first fuel add to lock it in app_shell
    final startOdo = _isFirstEntry ? double.parse(startText) : null;
    widget.onFuelAdded(fuel, cost, estRange, _selectedDate, startOdo);
    setState(() {
      _lastRange = estRange > 0 ? estRange : null;
      _newFuelCtrl.clear();
      _costCtrl.clear();
    });
  }

  void _calculateMileage() {
    if (!_formKey.currentState!.validate()) return;

    final start = double.parse(_startOdoCtrl.text.trim());
    final end = double.parse(_endOdoCtrl.text.trim());

    // For T2T, also count the fuel being entered now
    final fuelNow = double.tryParse(_newFuelCtrl.text.trim()) ?? 0;
    // Tank filling fuel is excluded from accumulatedFuel, so always use accumulatedFuel + fuelNow
    final totalFuel = widget.accumulatedFuel + fuelNow;

    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End odometer must be greater than start')),
      );
      return;
    }
    if (totalFuel <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total fuel must be greater than 0')),
      );
      return;
    }

    // Also add refueling record for the final fill if fuel entered
    final costText = _costCtrl.text.trim();
    final cost = costText.isEmpty ? null : double.tryParse(costText);
    if (fuelNow > 0) {
      final estRange = widget.meanMileage != null ? double.parse((fuelNow * widget.meanMileage!).toStringAsFixed(1)) : 0.0;
      widget.onFuelAdded(fuelNow, cost, estRange, _selectedDate);
    }

    final mileage = (end - start) / totalFuel;
    final record = MileageRecord(
      startOdometer: start,
      endOdometer: end,
      fuelUsed: totalFuel,
      mileage: mileage,
      date: _selectedDate,
    );

    widget.onMileageAdded(record);
    setState(() {
      _lastMileage = mileage;
      _lastRange = null;
      _category = 'Refueling';
      _endOdoCtrl.clear();
      _newFuelCtrl.clear();
      _costCtrl.clear();
    });
  }

  @override
  void dispose() {
    _newFuelCtrl.removeListener(_onFuelTextChanged);
    _startOdoCtrl.dispose();
    _endOdoCtrl.dispose();
    _newFuelCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAccumulated = widget.accumulatedFuel > 0 || _previewFuel > 0;
    final liveEstOdometer = widget.estimatedOdometer + _previewRange;
    final liveTotalFuel = widget.accumulatedFuel + _previewFuel;
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = AccentColorScope.onAccent(context);
    final isTT = _category == 'Tank to Tank';
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = cs.surface;
    final textColor = cs.onSurface;
    final labelColor = cs.onSurface.withOpacity(0.5);
    final secondaryText = cs.onSurface.withOpacity(0.4);
    final fieldFill = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final dropdownBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    // Last refuel info
    final lastRefuel = widget.refuelingHistory.isNotEmpty ? widget.refuelingHistory.last : null;
    final expectedDist = widget.meanMileage != null && liveTotalFuel > 0
        ? (liveTotalFuel * widget.meanMileage!).toStringAsFixed(1)
        : '--';

    // Date display
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year
        ? 'Today'
        : '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hero cards row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                // Odometer card
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(child: Text('Odometer', style: TextStyle(color: onAccent, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 40, height: 40,
                                              decoration: BoxDecoration(color: onAccent.withOpacity(0.2), shape: BoxShape.circle),
                                              child: Icon(Icons.speed, size: 20, color: onAccent),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  (!_isFirstEntry && widget.lastEndOdometer != null)
                                                      ? '${widget.lastEndOdometer!.toStringAsFixed(1)}'
                                                      : '--',
                                                  style: TextStyle(color: onAccent, fontSize: 28, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(UnitScope.distanceUnit(context), style: TextStyle(color: onAccent.withOpacity(0.7), fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Fuel card
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(child: Text('Fuel Added', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 40, height: 40,
                                              decoration: BoxDecoration(color: textColor.withOpacity(0.15), shape: BoxShape.circle),
                                              child: Icon(Icons.local_gas_station, size: 20, color: textColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  hasAccumulated
                                                      ? '${liveTotalFuel.toStringAsFixed(2)}'
                                                      : '0.00',
                                                  style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(UnitScope.volumeUnit(context), style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Category
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // Category
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 54,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: fieldFill,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _category,
                                            isExpanded: true,
                                            dropdownColor: dropdownBg,
                                            borderRadius: BorderRadius.circular(16),
                                            style: TextStyle(color: textColor, fontSize: 16),
                                            icon: Icon(Icons.keyboard_arrow_down, color: textColor.withOpacity(0.5)),
                                            items: [
                                              DropdownMenuItem(value: 'Refueling', child: Text(widget.refuelingHistory.isEmpty ? 'Tank Filling' : 'Refueling')),
                                              const DropdownMenuItem(value: 'Tank to Tank', child: Text('Tank to Tank')),
                                            ],
                                            onChanged: (v) {
                                              if (v != null) setState(() => _category = v);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _selectedDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                            builder: (ctx, child) => Theme(
                                              data: Theme.of(ctx).copyWith(
                                                colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: accent),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) setState(() => _selectedDate = picked);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: fieldFill,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(dateStr,
                                                    style: TextStyle(color: textColor, fontSize: 16)),
                                              ),
                                              Icon(Icons.calendar_month, color: textColor.withOpacity(0.5), size: 22),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Input fields
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Start Odometer — only show when first entry
                                if (_isFirstEntry) ...[
                                  _buildDarkField(
                                    controller: _startOdoCtrl,
                                    label: 'Start Odometer',
                                    suffix: UnitScope.distanceUnit(context),
                                    hint: '',
                                    icon: Icons.play_arrow_rounded,
                                    readOnly: true,
                                    onTap: widget.accumulatedFuel > 0
                                        ? null
                                        : () => _showNumpadSheet(_startOdoCtrl, 'Start Odometer'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Required';
                                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Fuel
                                _buildDarkField(
                                  controller: _newFuelCtrl,
                                  label: 'Fuel Filled',
                                  suffix: UnitScope.volumeUnit(context),
                                  hint: '',
                                  icon: Icons.local_gas_station_rounded,
                                  readOnly: true,
                                  onTap: () => _showNumpadSheet(_newFuelCtrl, 'Fuel Filled'),
                                  validator: isTT
                                      ? null
                                      : (v) {
                                          if (v == null || v.trim().isEmpty) return 'Required';
                                          final f = double.tryParse(v.trim());
                                          if (f == null) return 'Invalid';
                                          if (f <= 0) return 'Must be > 0';
                                          return null;
                                        },
                                ),
                                const SizedBox(height: 12),

                                // Cost
                                _buildDarkField(
                                  controller: _costCtrl,
                                  label: 'Cost',
                                  suffix: UnitScope.currency(context),
                                  hint: '',
                                  icon: Icons.currency_rupee,
                                  readOnly: true,
                                  onTap: () => _showNumpadSheet(_costCtrl, 'Cost'),
                                ),
                                const SizedBox(height: 12),

                                // End Odometer (only for T2T)
                                if (isTT) ...[
                                  _buildDarkField(
                                    controller: _endOdoCtrl,
                                    label: 'End Odometer',
                                    suffix: UnitScope.distanceUnit(context),
                                    hint: '',
                                    icon: Icons.flag_rounded,
                                    readOnly: true,
                                    onTap: () => _showNumpadSheet(_endOdoCtrl, 'End Odometer'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Required';
                                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            ),
                          ),

                          // Info card — last refuel + expected distance
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: fieldFill,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (lastRefuel != null) ...[
                                        Text(
                                          'Last refuel: ${lastRefuel.fuelFilled.toStringAsFixed(2)} ${UnitScope.volumeUnitShort(context)}'
                                          '${lastRefuel.cost != null ? '  •  ${UnitScope.currency(context)}${lastRefuel.cost!.toStringAsFixed(0)}' : ''}',
                                          style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
                                        ),
                                        if (hasAccumulated && widget.meanMileage != null) const SizedBox(height: 8),
                                      ],
                                      if (hasAccumulated && widget.meanMileage != null) ...[
                                        Row(
                                          children: [
                                            Icon(Icons.near_me, color: accent, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Expected distance: $expectedDist ${UnitScope.distanceUnit(context)}',
                                              style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        if (liveEstOdometer > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Est. odometer: ${liveEstOdometer.toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}',
                                            style: TextStyle(color: secondaryText, fontSize: 12),
                                          ),
                                        ],
                                      ],
                                      if (lastRefuel == null && !hasAccumulated)
                                        Text(
                                          'No refueling data yet. Add your first tank filling.',
                                          style: TextStyle(color: secondaryText, fontSize: 14),
                                        ),
                                      if (widget.meanMileage == null) ...[
                                        if (lastRefuel != null || hasAccumulated)
                                          Padding(
                                            padding: EdgeInsets.only(top: lastRefuel != null ? 8 : 0),
                                            child: Text(
                                              'Complete a Tank to Tank entry to see expected distance & odometer.',
                                              style: TextStyle(color: secondaryText, fontSize: 13),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // T2T result card
                          if (_lastMileage != null) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.speed, color: onAccent, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Last T2T Mileage', style: TextStyle(color: onAccent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_lastMileage!.toStringAsFixed(2)} ${UnitScope.mileageUnit(context)}',
                                            style: TextStyle(color: onAccent, fontSize: 22, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Cancel / clear
                    _BottomCircleBtn(
                      icon: Icons.refresh,
                      onTap: () {
                        setState(() {
                          _newFuelCtrl.clear();
                          _costCtrl.clear();
                          _endOdoCtrl.clear();
                          _lastMileage = null;
                          _category = 'Refueling';
                        });
                      },
                    ),
                    const Spacer(),
                    // Submit
                    GestureDetector(
                      onTap: isTT ? _calculateMileage : _addFuelOnly,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.check, color: onAccent, size: 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNumpadSheet(TextEditingController controller, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NumpadSheet(
        initialValue: controller.text,
        title: title,
        onDone: (value) {
          controller.text = value;
          controller.selection = TextSelection.collapsed(offset: controller.text.length);
          FocusScope.of(context).unfocus();
          // Trigger fuel preview update if it's the fuel controller
          if (controller == _newFuelCtrl) _onFuelTextChanged();
        },
      ),
    );
  }

  Widget _buildDarkField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFillColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      showCursor: onTap == null,
      enableInteractiveSelection: onTap == null,
      canRequestFocus: onTap == null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_NumericLimitFormatter()],
      style: TextStyle(color: readOnly && onTap == null ? cs.onSurface.withOpacity(0.3) : cs.onSurface, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.4)),
        floatingLabelBehavior: readOnly && onTap != null ? FloatingLabelBehavior.never : FloatingLabelBehavior.auto,
        suffixText: suffix,
        suffixStyle: TextStyle(color: cs.onSurface.withOpacity(0.3)),
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.2)),
        prefixIcon: Icon(icon, color: cs.onSurface.withOpacity(0.3)),
        filled: true,
        fillColor: fieldFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}

class _BottomCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BottomCircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 36),
      ),
    );
  }
}

class _NumpadSheet extends StatefulWidget {
  final String initialValue;
  final String title;
  final ValueChanged<String> onDone;

  const _NumpadSheet({required this.initialValue, required this.title, required this.onDone});

  @override
  State<_NumpadSheet> createState() => _NumpadSheetState();
}

class _NumpadSheetState extends State<_NumpadSheet> {
  late String _expression; // full expression string e.g. "56-24+6×7"
  String _result = '';
  bool _isFirstInput = false;

  @override
  void initState() {
    super.initState();
    _expression = widget.initialValue.isEmpty ? '' : widget.initialValue;
    _isFirstInput = widget.initialValue.isNotEmpty;
    _evaluateExpression();
  }

  static const _ops = {'+', '-', '×', '÷'};

  bool get _endsWithOp => _expression.isNotEmpty && _ops.contains(_expression[_expression.length - 1]);

  void _onDigit(String d) {
    setState(() {
      if (_isFirstInput && d != '.') {
        _expression = d;
        _isFirstInput = false;
        _evaluateExpression();
        return;
      }
      _isFirstInput = false;

      // Find the last number segment
      int lastOpIdx = -1;
      for (int i = _expression.length - 1; i >= 0; i--) {
        if (_ops.contains(_expression[i])) { lastOpIdx = i; break; }
      }
      final lastNum = _expression.substring(lastOpIdx + 1);

      if (d == '.') {
        if (lastNum.contains('.')) return;
        if (lastNum.isEmpty) {
          _expression += '0.';
        } else {
          _expression += '.';
        }
      } else {
        // Enforce limits on the current number segment
        if (lastNum.contains('.')) {
          // Limit to 2 decimal places
          final parts = lastNum.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        } else {
          // Limit to 6 integer digits
          if (lastNum.length >= 6) return;
        }
        _expression += d;
      }
      _evaluateExpression();
    });
  }

  void _onBackspace() {
    _isFirstInput = false;
    setState(() {
      if (_expression.isEmpty) return;
      _expression = _expression.substring(0, _expression.length - 1);
      _evaluateExpression();
    });
  }

  void _onOp(String op) {
    _isFirstInput = false;
    setState(() {
      if (_expression.isEmpty) return;
      if (_endsWithOp) {
        // Replace last operator
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }
    });
  }

  /// Tokenize and evaluate with BODMAS
  void _evaluateExpression() {
    if (_expression.isEmpty || _endsWithOp) {
      _result = '';
      return;
    }
    try {
      final result = _evalBodmas(_expression);
      if (result == null) {
        _result = '';
      } else {
        _result = result == result.roundToDouble()
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
      }
    } catch (_) {
      _result = '';
    }
  }

  /// Parse expression into numbers and operators, then evaluate × ÷ first, then + -
  double? _evalBodmas(String expr) {
    final numbers = <double>[];
    final operators = <String>[];
    var buf = '';
    for (int i = 0; i < expr.length; i++) {
      final c = expr[i];
      if (_ops.contains(c) && buf.isNotEmpty) {
        final n = double.tryParse(buf);
        if (n == null) return null;
        numbers.add(n);
        operators.add(c);
        buf = '';
      } else {
        buf += c;
      }
    }
    if (buf.isNotEmpty) {
      final n = double.tryParse(buf);
      if (n == null) return null;
      numbers.add(n);
    }
    if (numbers.isEmpty) return null;

    // First pass: × and ÷
    int i = 0;
    while (i < operators.length) {
      if (operators[i] == '×' || operators[i] == '÷') {
        final a = numbers[i];
        final b = numbers[i + 1];
        numbers[i] = operators[i] == '×' ? a * b : (b != 0 ? a / b : 0);
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else {
        i++;
      }
    }
    // Second pass: + and -
    double result = numbers[0];
    for (int j = 0; j < operators.length; j++) {
      if (operators[j] == '+') {
        result += numbers[j + 1];
      } else {
        result -= numbers[j + 1];
      }
    }
    return result;
  }

  bool _committed = false;

  void _onDone() {
    if (_committed) return;
    _committed = true;
    var value = _result.isNotEmpty ? _result : (_expression.isNotEmpty && !_endsWithOp ? _expression : '');
    // Clamp to max 999999.99
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 999999.99) {
      value = '999999';
    }
    widget.onDone(value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final gridBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final textColor = cs.onSurface;
    // Determine if expression is a simple number (no ops) — don't show result separately
    final hasOps = _expression.split('').any((c) => _ops.contains(c));
    final showResult = hasOps && _result.isNotEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _onDone();
      },
      child: Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: textColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            // Header + expression + result
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Expression on the left (always visible)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _expression.isEmpty ? '0' : _expression,
                        style: TextStyle(
                          color: _expression.isEmpty ? textColor.withOpacity(0.3) : textColor.withOpacity(0.5),
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Right side: result or current number
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _endsWithOp
                          ? ''
                          : _result.isNotEmpty ? _result : (_expression.isEmpty ? '0' : _expression),
                      style: TextStyle(color: textColor, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Numpad grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gridBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _numRow(['1', '2', '3', '÷']),
                    const SizedBox(height: 6),
                    _numRow(['4', '5', '6', '×']),
                    const SizedBox(height: 6),
                    _numRow(['7', '8', '9', '-']),
                    const SizedBox(height: 6),
                    _numRow(['.', '0', '⌫', '+']),
                  ],
                ),
              ),
            ),
            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _onDone();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AccentColorScope.onAccent(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _numRow(List<String> keys) {
    final isOp = {'÷', '×', '-', '+'};
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyText = cs.onSurface;
    final opBg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    return Row(
      children: keys.map((k) {
        final isOperator = isOp.contains(k);
        final isBackspace = k == '⌫';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: isOperator ? opBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (isBackspace) {
                    _onBackspace();
                  } else if (isOperator) {
                    _onOp(k);
                  } else {
                    _onDigit(k);
                  }
                },
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: isBackspace
                      ? Icon(Icons.backspace_outlined, color: keyText, size: 22)
                      : Text(
                          k,
                          style: TextStyle(
                            color: isOperator ? keyText : keyText.withOpacity(0.7),
                            fontSize: isOperator ? 24 : 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NumericLimitFormatter extends TextInputFormatter {
  static const double _maxValue = 999999.99;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final double? value = double.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }
    
    if (value > _maxValue) {
      final clamped = _maxValue.toInt().toString();
      return TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
    
    return newValue;
  }
}
