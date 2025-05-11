// lib/main.dart
import 'package:flutter/material.dart';
import 'core/firebase_config.dart';
import 'core/constants.dart';
import 'features/claims/ui/claims_overview_screen.dart';
import 'features/vehicles/ui/vehicles_screen.dart';
import 'features/policies/ui/policies_screen.dart';
import 'features/profile/ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  runApp(const ClaimsApp());
}

class ClaimsApp extends StatelessWidget {
  const ClaimsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Insurance Claims',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: bgColor),
      initialRoute: '/claims',
      routes: {
        '/claims': (_) => const ClaimsOverviewScreen(),
        '/vehicles': (_) => const VehiclesScreen(),
        '/policies': (_) => const PoliciesScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
