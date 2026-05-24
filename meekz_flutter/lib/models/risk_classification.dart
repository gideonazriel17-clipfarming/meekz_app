import 'app_disclaimer.dart';
import 'app_enums.dart';
import 'firestore_date.dart';

class RiskClassification {
  const RiskClassification({
    required this.classificationId,
    required this.sessionId,
    required this.childId,
    required this.userId,
    required this.literacyIndicator,
    required this.numeracyIndicator,
    required this.attentionIndicator,
    required this.overallIndicator,
    required this.reliabilityFlag,
    required this.reasonCodes,
    required this.disclaimer,
    required this.createdAt,
  });

  final String classificationId;
  final String sessionId;
  final String childId;
  final String userId;
  final IndicatorLevel literacyIndicator;
  final IndicatorLevel numeracyIndicator;
  final IndicatorLevel attentionIndicator;
  final IndicatorLevel overallIndicator;
  final ReliabilityFlag reliabilityFlag;
  final List<String> reasonCodes;
  final String disclaimer;
  final DateTime? createdAt;

  factory RiskClassification.fromFirestore(Map<String, dynamic> data) {
    return RiskClassification(
      classificationId: data['classificationId'] as String,
      sessionId: data['sessionId'] as String,
      childId: data['childId'] as String,
      userId: data['userId'] as String,
      literacyIndicator: IndicatorLevelFirestore.fromValue(
        data['literacyIndicator'] as String,
      ),
      numeracyIndicator: IndicatorLevelFirestore.fromValue(
        data['numeracyIndicator'] as String,
      ),
      attentionIndicator: IndicatorLevelFirestore.fromValue(
        data['attentionIndicator'] as String,
      ),
      overallIndicator: IndicatorLevelFirestore.fromValue(
        data['overallIndicator'] as String,
      ),
      reliabilityFlag: ReliabilityFlagFirestore.fromValue(
        data['reliabilityFlag'] as String,
      ),
      reasonCodes: List<String>.from(data['reasonCodes'] as List<dynamic>),
      disclaimer: data['disclaimer'] as String? ?? meekzRequiredDisclaimer,
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }
}
