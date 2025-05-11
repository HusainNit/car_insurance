import 'package:flutter/material.dart';
import 'package:car_insurance_app/core/widgets/bottom_nav.dart';
import 'package:car_insurance_app/core/constants.dart';

/// A scaffold for main pages with top bar (no back button) and bottom navigation.
class MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final Widget body;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1.5),
                blurRadius: 2,
                color: Colors.black38,
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, Color(0xFF2A2A2A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: body,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: selectedIndex,
        onNavTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/vehicles');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/claims');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/policies');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
