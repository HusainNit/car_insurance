import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/claim_model.dart';

class ClaimService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new claim and return its document reference.
  Future<DocumentReference<Map<String, dynamic>>> createClaim(
      ClaimModel claim) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not signed in');

    final data = <String, dynamic>{
      ...claim.toJson(),
      'createdBy': user.uid,                
      'submitted': false,
      'submittedAt': null,
    };

    return _firestore.collection('claims').add(data);
  }

  Future<void> addPhoto({
    required String docId,
    required String spot,
    required String url,
  }) async {
    await _firestore
        .collection('claims')
        .doc(docId)
        .collection('photos')
        .add({'spot': spot, 'url': url, 'ts': FieldValue.serverTimestamp()});
  }
}
