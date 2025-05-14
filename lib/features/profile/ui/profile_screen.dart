// lib/features/profile/ui/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/widgets/ui_helpers.dart';
import '../../auth/pages/login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Fetch the signed-in user’s email + role from Firestore
  Future<Map<String, String>> _userInfo() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return {
      'email': user.email ?? '—',
      'role': (snap.data()?['userType'] ?? snap.data()?['role'] ?? 'customer')
          .toString(),
    };
  }

  /// Sign out and return to the login page
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => MainScaffold(
        selectedIndex: 4, // ← choose the correct tab index
        title: 'Profile', // AppBar title; MainScaffold hides back-arrow
        body: FutureBuilder<Map<String, String>>(
          future: _userInfo(),
          builder: (_, snap) {
            if (!snap.hasData) return customLoadingSpinner();
            final data = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: accentColor,
                  child:
                      const Icon(Icons.person, size: 48, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    data['email']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Role: ${data['role']}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Log Out'),
                  onTap: () => _logout(context),
                ),
              ],
            );
          },
        ),
      );
}
