import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'models.dart';

class EditRefuelingScreen extends StatefulWidget {
  final RefuelingRecord record;
  final int index;
  final void Function(int index, RefuelingRecord updated) onSave;

  const EditRefuelingScreen({
    super.key,
    required this.record,
    required this.index,
    required this.onSave,
  });

  @override
  State<EditRefuelingScreen> createState() => _EditRefuelingScreenState();
}

class _EditRefuelingScreenState extends State<EditRefuelingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fuelCtrl;
  late final TextEditingController _costCtrl;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _fuelCtrl = TextEditingController(text: widget.record.fuelFilled.toStringAsFixed(2));
    _costCtrl = TextEditingController(
        text: widget.record.cost != null ? widget.record.cost!.toStringAsFixed(0) : '');
    _selectedDate = widget.record.date;
  }

  @override
  void dispose() {
    _fuelCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
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
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final fuel = double.parse(_fuelCtrl.text.trim());
    final cost = _costCtrl.text.trim().isNotEmpty ? double.parse(_costCtrl.text.trim()) : null;
    final updated = RefuelingRecord(
      odometer: widget.record.odometer,
      fuelFilled: fuel,
      cost: cost,
      meanMileage: widget.record.meanMileage,
      range: widget.record.range,
      finalOdometer: widget.record.finalOdometer,
      date: _selectedDate,
      isTankFilling: widget.record.isTankFilling,
    );
    widget.onSave(widget.index, updated);
    Navigator.pop(context);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    bool readOnly = true,
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
      style: TextStyle(color: cs.onSurface, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.4)),
        floatingLabelBehavior: readOnly && onTap != null ? FloatingLabelBehavior.never : FloatingLabelBehavior.auto,
        suffixText: suffix,
        suffixStyle: TextStyle(color: cs.onSurface.withOpacity(0.3)),
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
          borderSide: BorderSide(color: cs.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = cs.primary;
    final onAccent = AccentColorScope.onAccent(context);
    final textColor = cs.onSurface;
    final fieldFill = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Refueling'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_gas_station, color: onAccent, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Odometer', style: TextStyle(color: onAccent.withOpacity(0.7), fontSize: 12)),
                                  Text('${widget.record.odometer.toStringAsFixed(1)} ${UnitScope.distanceUnit(context)}', style: TextStyle(color: onAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date
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
                                child: Text(dateStr, style: TextStyle(color: textColor, fontSize: 16)),
                              ),
                              Icon(Icons.calendar_month, color: textColor.withOpacity(0.5), size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Fuel
                      _buildField(
                        controller: _fuelCtrl,
                        label: 'Fuel Filled',
                        suffix: UnitScope.volumeUnit(context),
                        icon: Icons.local_gas_station_rounded,
                        onTap: () => _showNumpadSheet(_fuelCtrl, 'Fuel Filled'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final f = double.tryParse(v.trim());
                          if (f == null) return 'Invalid';
                          if (f <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Cost
                      _buildField(
                        controller: _costCtrl,
                        label: 'Cost',
                        suffix: UnitScope.currency(context),
                        icon: Icons.currency_rupee,
                        onTap: () => _showNumpadSheet(_costCtrl, 'Cost'),
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: onAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Update'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reuse the same numpad from mileage_calculator_screen
class _NumpadSheet extends StatefulWidget {
  final String initialValue;
  final String title;
  final ValueChanged<String> onDone;

  const _NumpadSheet({required this.initialValue, required this.title, required this.onDone});

  @override
  State<_NumpadSheet> createState() => _NumpadSheetState();
}

class _NumpadSheetState extends State<_NumpadSheet> {
  String _expression = '';
  String _result = '';
  bool _committed = false;
  bool _isFirstInput = true;
  final _ops = {'÷', '×', '-', '+'};

  bool get _endsWithOp => _expression.isNotEmpty && _ops.contains(_expression[_expression.length - 1]);

  @override
  void initState() {
    super.initState();
    _expression = widget.initialValue;
    _isFirstInput = widget.initialValue.isNotEmpty;
  }

  void _onDigit(String d) {
    setState(() {
      if (_isFirstInput && d != '.') {
        _expression = d;
        _isFirstInput = false;
        _evaluate();
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
          final parts = lastNum.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        } else {
          if (lastNum.length >= 6) return;
        }
        _expression += d;
      }
      _evaluate();
    });
  }

  void _onOp(String op) {
    if (_expression.isEmpty) return;
    _isFirstInput = false;
    setState(() {
      if (_endsWithOp) {
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }
      _result = '';
    });
  }

  void _onBackspace() {
    if (_expression.isEmpty) return;
    _isFirstInput = false;
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _evaluate();
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) { _result = ''; return; }
    try {
      final val = _evalBodmas(_expression);
      if (val != null) _result = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
    } catch (_) {}
  }

  double? _evalBodmas(String expr) {
    final tokens = <String>[];
    var buf = '';
    for (var i = 0; i < expr.length; i++) {
      final c = expr[i];
      if (_ops.contains(c)) {
        if (buf.isNotEmpty) tokens.add(buf);
        tokens.add(c);
        buf = '';
      } else {
        buf += c;
      }
    }
    if (buf.isNotEmpty) tokens.add(buf);
    final numbers = <double>[];
    final ops = <String>[];
    for (final t in tokens) {
      if (_ops.contains(t)) { ops.add(t); } else {
        final n = double.tryParse(t);
        if (n == null) return null;
        numbers.add(n);
      }
    }
    if (numbers.isEmpty) return null;
    // Mul/Div first
    for (var i = 0; i < ops.length;) {
      if (ops[i] == '×' || ops[i] == '÷') {
        final res = ops[i] == '×' ? numbers[i] * numbers[i + 1] : numbers[i] / numbers[i + 1];
        numbers[i] = res;
        numbers.removeAt(i + 1);
        ops.removeAt(i);
      } else {
        i++;
      }
    }
    var result = numbers[0];
    for (var j = 0; j < ops.length; j++) {
      if (ops[j] == '+') {
        result += numbers[j + 1];
      } else {
        result -= numbers[j + 1];
      }
    }
    return result;
  }

  void _onDone() {
    if (_committed) return;
    _committed = true;
    var value = _result.isNotEmpty ? _result : (_expression.isNotEmpty && !_endsWithOp ? _expression : '');
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
    final hasOps = _expression.split('').any((c) => _ops.contains(c));

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
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: textColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _expression.isEmpty ? '0' : _expression,
                          style: TextStyle(color: _expression.isEmpty ? textColor.withOpacity(0.3) : textColor.withOpacity(0.5), fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _endsWithOp ? '' : _result.isNotEmpty ? _result : (_expression.isEmpty ? '0' : _expression),
                        style: TextStyle(color: textColor, fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: gridBg, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    children: [
                      _numRow(['1', '2', '3', '÷'], textColor, isDark),
                      const SizedBox(height: 6),
                      _numRow(['4', '5', '6', '×'], textColor, isDark),
                      const SizedBox(height: 6),
                      _numRow(['7', '8', '9', '-'], textColor, isDark),
                      const SizedBox(height: 6),
                      _numRow(['.', '0', '⌫', '+'], textColor, isDark),
                    ],
                  ),
                ),
              ),
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

  Widget _numRow(List<String> keys, Color keyText, bool isDark) {
    final isOp = {'÷', '×', '-', '+'};
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
                  if (isBackspace) { _onBackspace(); }
                  else if (isOperator) { _onOp(k); }
                  else { _onDigit(k); }
                },
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: isBackspace
                      ? Icon(Icons.backspace_outlined, color: keyText, size: 22)
                      : Text(k, style: TextStyle(color: isOperator ? keyText : keyText.withOpacity(0.7), fontSize: isOperator ? 24 : 22, fontWeight: FontWeight.w500)),
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
