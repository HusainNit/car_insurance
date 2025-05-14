import 'package:flutter/material.dart';

class ClaimModel {
  final String vin;
  final String policy;
  final String location;
  final String description;
  final DateTime date;          // accident date
  final TimeOfDay time;         // accident time
  final double repairCost;
  final List<String> damagedParts;
  final double consumptionRate; // 0.10 or 0.15
  final String status;          // default = Pending

  ClaimModel({
    required this.vin,
    required this.policy,
    required this.location,
    required this.description,
    required this.date,
    required this.time,
    required this.repairCost,
    required this.damagedParts,
    required this.consumptionRate,
    this.status = 'Pending',
  });

  Map<String, dynamic> toJson() => {
        'vin': vin,
        'policy': policy,
        'location': location,
        'description': description,
        'date': date.toIso8601String(),
        'time':
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'repairCost': repairCost,
        'damagedParts': damagedParts,
        'consumptionRate': consumptionRate,
        'status': status,
      };
}
