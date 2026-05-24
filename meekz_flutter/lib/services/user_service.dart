import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/adult_user_profile.dart';
import '../models/app_enums.dart';
import 'firestore_paths.dart';
import 'meekz_exception.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required AdultRole role,
    required bool consentAccepted,
  }) async {
    await _users.doc(userId).set({
      'userId': userId,
      'name': name.trim(),
      'email': email.trim(),
      'role': role.value,
      'consentAccepted': consentAccepted,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AdultUserProfile> getUserProfile(String userId) async {
    final snapshot = await _users.doc(userId).get();
    final data = snapshot.data();

    if (data == null) {
      try {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null && authUser.uid == userId) {
          await createUserProfile(
            userId: userId,
            name: authUser.displayName?.isNotEmpty == true
                ? authUser.displayName!
                : 'User',
            email: authUser.email ?? '',
            role: AdultRole.parent,
            consentAccepted: true,
          );
          final newSnapshot = await _users.doc(userId).get();
          return AdultUserProfile.fromFirestore(newSnapshot.data()!);
        }
      } catch (_) {}

      throw const MeekzException('Adult user profile was not found.');
    }

    return AdultUserProfile.fromFirestore(data);
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    AdultRole? role,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updates['name'] = name.trim();
    }

    if (role != null) {
      updates['role'] = role.value;
    }

    await _users.doc(userId).update(updates);
  }

  Future<void> updateConsent({
    required String userId,
    required bool consentAccepted,
  }) async {
    await _users.doc(userId).update({
      'consentAccepted': consentAccepted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
