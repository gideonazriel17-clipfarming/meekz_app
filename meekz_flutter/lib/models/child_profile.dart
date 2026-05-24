import 'app_enums.dart';
import 'firestore_date.dart';

class ChildProfile {
  const ChildProfile({
    required this.childId,
    required this.userId,
    required this.nameOrNickname,
    required this.age,
    required this.preferredLanguage,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.gender,
    this.schoolYear,
    this.deletedAt,
  });

  final String childId;
  final String userId;
  final String nameOrNickname;
  final int age;
  final String? gender;
  final String? schoolYear;
  final LanguageCode preferredLanguage;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isEligibleForScreening => !isDeleted && age >= 6 && age <= 8;

  factory ChildProfile.fromFirestore(Map<String, dynamic> data) {
    return ChildProfile(
      childId: data['childId'] as String,
      userId: data['userId'] as String,
      nameOrNickname: data['nameOrNickname'] as String,
      age: data['age'] as int,
      gender: data['gender'] as String?,
      schoolYear: data['schoolYear'] as String?,
      preferredLanguage: LanguageCodeFirestore.fromValue(
        data['preferredLanguage'] as String,
      ),
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: dateTimeFromFirestore(data['deletedAt']),
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
    );
  }
}
