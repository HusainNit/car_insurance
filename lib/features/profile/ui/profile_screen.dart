// lib/features/profile/ui/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:car_insurance_app/core/widgets/main_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 4,
      title: 'Your Profile',
      body: Center(
        child: Text(
          'Profile Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
