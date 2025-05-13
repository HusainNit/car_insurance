// lib/features/policies/ui/policies_screen.dart
import 'package:flutter/material.dart';
import 'package:car_insurance_app/core/widgets/main_scaffold.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 3,
      title: 'Your Policies',
      body: Center(
        child: Text(
          'Policies Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
