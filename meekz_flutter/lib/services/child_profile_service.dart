import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_enums.dart';
import '../models/child_profile.dart';
import 'firestore_paths.dart';
import 'meekz_exception.dart';

class ChildProfileService {
  ChildProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _children =>
      _firestore.collection(FirestorePaths.children);

  Future<ChildProfile> createChildProfile({
    required String userId,
    required String nameOrNickname,
    required int age,
    required LanguageCode preferredLanguage,
    String? gender,
    String? schoolYear,
  }) async {
    _validateAge(age);

    final doc = _children.doc();
    await doc.set({
      'childId': doc.id,
      'userId': userId,
      'nameOrNickname': nameOrNickname.trim(),
      'age': age,
      'gender': gender,
      'schoolYear': schoolYear,
      'preferredLanguage': preferredLanguage.value,
      'isDeleted': false,
      'deletedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await doc.get();
    return ChildProfile.fromFirestore(snapshot.data()!);
  }

  Future<List<ChildProfile>> getActiveChildProfiles(String userId) async {
    final snapshot = await _children
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => ChildProfile.fromFirestore(doc.data()))
        .toList();
  }

  Future<ChildProfile> getChildProfile({
    required String userId,
    required String childId,
  }) async {
    final snapshot = await _children.doc(childId).get();
    final data = snapshot.data();

    if (data == null || data['userId'] != userId) {
      throw const MeekzException('Child profile was not found.');
    }

    return ChildProfile.fromFirestore(data);
  }

  Future<void> updateChildProfile({
    required String userId,
    required String childId,
    String? nameOrNickname,
    int? age,
    String? gender,
    String? schoolYear,
    LanguageCode? preferredLanguage,
  }) async {
    final existing = await getChildProfile(userId: userId, childId: childId);

    if (existing.isDeleted) {
      throw const MeekzException('Deleted child profiles cannot be updated.');
    }

    if (age != null) {
      _validateAge(age);
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (nameOrNickname != null) {
      updates['nameOrNickname'] = nameOrNickname.trim();
    }

    if (age != null) {
      updates['age'] = age;
    }

    if (gender != null) {
      updates['gender'] = gender;
    }

    if (schoolYear != null) {
      updates['schoolYear'] = schoolYear;
    }

    if (preferredLanguage != null) {
      updates['preferredLanguage'] = preferredLanguage.value;
    }

    await _children.doc(childId).update(updates);
  }

  Future<void> softDeleteChildProfile({
    required String userId,
    required String childId,
  }) async {
    await getChildProfile(userId: userId, childId: childId);

    await _children.doc(childId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ChildProfile>> getDeletedChildProfiles(String userId) async {
    final snapshot = await _children
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ChildProfile.fromFirestore(doc.data()))
        .toList();
  }

  Future<void> restoreChildProfile({
    required String userId,
    required String childId,
  }) async {
    final child = await getChildProfile(userId: userId, childId: childId);
    if (!child.isDeleted) {
      throw const MeekzException('Child profile is not deleted.');
    }

    await _children.doc(childId).update({
      'isDeleted': false,
      'deletedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validateAge(int age) {
    if (age < 6 || age > 8) {
      throw const MeekzException(
        'Only children aged 6 to 8 can proceed with screening.',
      );
    }
  }
}
