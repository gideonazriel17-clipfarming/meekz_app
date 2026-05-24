import 'app_enums.dart';
import 'firestore_date.dart';

class ScreeningSession {
  const ScreeningSession({
    required this.sessionId,
    required this.childId,
    required this.userId,
    required this.language,
    required this.startedAt,
    required this.status,
    required this.consentConfirmed,
    required this.domainsCompleted,
    required this.createdAt,
    this.completedAt,
  });

  final String sessionId;
  final String childId;
  final String userId;
  final LanguageCode language;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final ScreeningSessionStatus status;
  final bool consentConfirmed;
  final List<ScreeningDomain> domainsCompleted;
  final DateTime? createdAt;

  factory ScreeningSession.fromFirestore(Map<String, dynamic> data) {
    return ScreeningSession(
      sessionId: data['sessionId'] as String,
      childId: data['childId'] as String,
      userId: data['userId'] as String,
      language: LanguageCodeFirestore.fromValue(data['language'] as String),
      startedAt: dateTimeFromFirestore(data['startedAt']),
      completedAt: dateTimeFromFirestore(data['completedAt']),
      status: ScreeningSessionStatusFirestore.fromValue(
        data['status'] as String,
      ),
      consentConfirmed: data['consentConfirmed'] as bool? ?? false,
      domainsCompleted: ((data['domainsCompleted'] as List<dynamic>?) ?? [])
          .map((value) => ScreeningDomainFirestore.fromValue(value as String))
          .toList(),
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }
}
