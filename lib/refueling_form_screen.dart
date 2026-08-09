import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'models.dart';
import 'refueling_history_screen.dart';

class RefuelingFormScreen extends StatefulWidget {
  final double? meanMileage;
  final void Function(RefuelingRecord) onRefuelingAdded;
  final List<RefuelingRecord> refuelingHistory;

  const RefuelingFormScreen({
    super.key,
    required this.meanMileage,
    required this.onRefuelingAdded,
    required this.refuelingHistory,
  });

  @override
  State<RefuelingFormScreen> createState() => _RefuelingFormScreenState();
}

class _RefuelingFormScreenState extends State<RefuelingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odoCtrl = TextEditingController();
  final _fuelCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  double? _rangeResult;
  double? _finalOdoResult;
  DateTime _selectedDate = DateTime.now();

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.meanMileage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calculate at least one mileage first')),
      );
      return;
    }

    final odo = double.parse(_odoCtrl.text.trim());
    final fuel = double.parse(_fuelCtrl.text.trim());
    final costText = _costCtrl.text.trim();
    final cost = costText.isEmpty ? null : double.tryParse(costText);

    final range = fuel * widget.meanMileage!;
    final finalOdo = odo + range;

    widget.onRefuelingAdded(RefuelingRecord(
      odometer: odo,
      fuelFilled: fuel,
      cost: cost,
      meanMileage: widget.meanMileage!,
      range: range,
      finalOdometer: finalOdo,
      date: _selectedDate,
    ));

    setState(() {
      _rangeResult = range;
      _finalOdoResult = finalOdo;
      _odoCtrl.clear();
      _fuelCtrl.clear();
      _costCtrl.clear();
    });
  }

  @override
  void dispose() {
    _odoCtrl.dispose();
    _fuelCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Refueling'),
        actions: [
          if (widget.refuelingHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RefuelingHistoryScreen(records: widget.refuelingHistory),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4A9BFF).withOpacity(0.2),
                          const Color(0xFF2B6FC7).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.local_gas_station_rounded,
                            color: Color(0xFF4A9BFF), size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          'New Refueling',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.meanMileage != null
                              ? 'Mean mileage: ${UnitScope.mileage(context, widget.meanMileage!).toStringAsFixed(2)} ${UnitScope.mileageUnit(context)}'
                              : 'Calculate mileage first to get range',
                          style: TextStyle(
                            color: widget.meanMileage != null
                                ? Colors.white54
                                : Colors.orangeAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _odoCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_NumericLimitFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Current Odometer',
                      suffixText: UnitScope.distanceUnit(context),
                      prefixIcon: const Icon(Icons.speed_rounded),
                      hintText: 'e.g. 46000',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _fuelCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_NumericLimitFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Fuel Filled',
                      suffixText: UnitScope.volumeUnit(context),
                      prefixIcon: const Icon(Icons.local_gas_station_rounded),
                      hintText: 'e.g. 5.0',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final f = double.tryParse(v.trim());
                      if (f == null) return 'Invalid number';
                      if (f <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _costCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_NumericLimitFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Cost',
                      suffixText: UnitScope.currency(context),
                      prefixIcon: const Icon(Icons.currency_rupee),
                      hintText: 'e.g. 500',
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: widget.meanMileage != null ? _calculate : null,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Refueling & Calculate Range'),
                  ),
                  if (_rangeResult != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232740),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Range: ${_rangeResult!.toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Final Odometer: ${_finalOdoResult!.toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumericLimitFormatter extends TextInputFormatter {
  static const int _maxValue = 999999999;

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
      return TextEditingValue(
        text: _maxValue.toString(),
        selection: TextSelection.collapsed(offset: _maxValue.toString().length),
      );
    }
    
    return newValue;
  }
}
