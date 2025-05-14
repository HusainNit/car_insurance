import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTapped;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onNavTapped,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.black,
      selectedIndex: currentIndex,
      onDestinationSelected: onNavTapped,
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.time_to_leave), label: 'Vehicles'),
        NavigationDestination(icon: Icon(Icons.car_rental), label: 'Register'),
        NavigationDestination(icon: Icon(Icons.article), label: 'Claims'),
        NavigationDestination(icon: Icon(Icons.policy), label: 'Policies'),
        NavigationDestination(
            icon: Icon(Icons.account_circle), label: 'Profile'),
      ],
    );
  }
}
