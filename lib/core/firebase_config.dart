// lib/core/firebase_config.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

/// Initializes Firebase with the correct configuration for Web or Mobile.
Future<void> initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAZ3_7pF_NC8qrChpW_jsOX8KnS22Hj3vI',
        authDomain: 'appfb-a7bec.firebaseapp.com',
        projectId: 'appfb-a7bec',
        storageBucket: 'appfb-a7bec.appspot.com',
        messagingSenderId: '785864137651',
        appId: '1:785864137651:web:2dabc450045e17302909c6',
        measurementId: 'G-SQ0DV0TLHT',
      ),
    );
  } else {
    await Firebase.initializeApp(); // For Mobile (auto-configured)
  }
}
