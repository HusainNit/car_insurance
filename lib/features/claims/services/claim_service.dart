// lib/features/claims/services/claim_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/claim_model.dart';

class ClaimService {
  final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> createClaim(
          ClaimModel c) =>
      _db.collection('claims').add(c.toJson());

  Future<void> addPhoto({
    required String docId,
    required String spot,
    required String url,
  }) =>
      _db
          .collection('claims')
          .doc(docId)
          .collection('photos')
          .add({'url': url, 'spot': spot, 'ts': FieldValue.serverTimestamp()});
}
