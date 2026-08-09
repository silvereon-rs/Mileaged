import 'dart:typed_data';

class MileageRecord {
  final double startOdometer;
  final double endOdometer;
  final double fuelUsed;
  final double mileage;
  final DateTime date;

  MileageRecord({
    required this.startOdometer,
    required this.endOdometer,
    required this.fuelUsed,
    required this.mileage,
    required this.date,
  });

  double get distance => endOdometer - startOdometer;

  Map<String, dynamic> toJson() => {
        'startOdometer': startOdometer,
        'endOdometer': endOdometer,
        'fuelUsed': fuelUsed,
        'mileage': mileage,
        'date': date.toIso8601String(),
      };

  factory MileageRecord.fromJson(Map<String, dynamic> json) => MileageRecord(
        startOdometer: (json['startOdometer'] as num).toDouble(),
        endOdometer: (json['endOdometer'] as num).toDouble(),
        fuelUsed: (json['fuelUsed'] as num).toDouble(),
        mileage: (json['mileage'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}

class RefuelingRecord {
  final double odometer;
  final double fuelFilled;
  final double? cost;
  final double meanMileage;
  final double range;
  final double finalOdometer;
  final DateTime date;
  final bool isTankFilling;

  RefuelingRecord({
    required this.odometer,
    required this.fuelFilled,
    this.cost,
    required this.meanMileage,
    required this.range,
    required this.finalOdometer,
    required this.date,
    this.isTankFilling = false,
  });

  Map<String, dynamic> toJson() => {
        'odometer': odometer,
        'fuelFilled': fuelFilled,
        'cost': cost,
        'meanMileage': meanMileage,
        'range': range,
        'finalOdometer': finalOdometer,
        'date': date.toIso8601String(),
        'isTankFilling': isTankFilling,
      };

  factory RefuelingRecord.fromJson(Map<String, dynamic> json) =>
      RefuelingRecord(
        odometer: (json['odometer'] as num).toDouble(),
        fuelFilled: (json['fuelFilled'] as num).toDouble(),
        cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
        meanMileage: (json['meanMileage'] as num).toDouble(),
        range: (json['range'] as num).toDouble(),
        finalOdometer: (json['finalOdometer'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        isTankFilling: json['isTankFilling'] as bool? ?? false,
      );
}

class Vehicle {
  String name;
  Uint8List? imageBytes;
  final List<MileageRecord> mileageHistory = [];
  final List<RefuelingRecord> refuelingHistory = [];
  double accumulatedFuel = 0;
  double accumulatedRange = 0;
  double? firstStartOdometer;

  Vehicle({required this.name, this.imageBytes});

  double? get meanMileage {
    if (mileageHistory.isEmpty) return null;
    final totalDist = mileageHistory.fold<double>(0, (s, r) => s + r.distance);
    final totalFuel = mileageHistory.fold<double>(0, (s, r) => s + r.fuelUsed);
    if (totalFuel == 0) return null;
    return totalDist / totalFuel;
  }

  double get estimatedOdometer {
    if (mileageHistory.isNotEmpty) {
      return mileageHistory.last.endOdometer + accumulatedRange;
    }
    if (firstStartOdometer != null) {
      return firstStartOdometer! + accumulatedRange;
    }
    return 0;
  }
}