import 'package:flutter/material.dart';

class ClaimModel {
  final String vin, policy, location, description;
  final DateTime date;
  final TimeOfDay time;
  final double repairCost;
  final bool expectedLow;

  ClaimModel({
    required this.vin,
    required this.policy,
    required this.location,
    required this.description,
    required this.date,
    required this.time,
    required this.repairCost,
    required this.expectedLow,
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
        'expectedLow': expectedLow,
      };
}
