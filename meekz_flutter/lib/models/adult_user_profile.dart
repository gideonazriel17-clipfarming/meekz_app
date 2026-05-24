import 'app_enums.dart';
import 'firestore_date.dart';

class AdultUserProfile {
  const AdultUserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.consentAccepted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String name;
  final String email;
  final AdultRole role;
  final bool consentAccepted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdultUserProfile.fromFirestore(Map<String, dynamic> data) {
    return AdultUserProfile(
      userId: data['userId'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      role: AdultRoleFirestore.fromValue(data['role'] as String),
      consentAccepted: data['consentAccepted'] as bool? ?? false,
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
    );
  }
}
