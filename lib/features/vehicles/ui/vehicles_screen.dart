// lib/features/vehicles/ui/vehicles_screen.dart
import 'package:flutter/material.dart';
import 'package:car_insurance_app/core/widgets/main_scaffold.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 0,
      title: 'Your Vehicles',
      body: Center(
        child: Text(
          'Vehicles Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
