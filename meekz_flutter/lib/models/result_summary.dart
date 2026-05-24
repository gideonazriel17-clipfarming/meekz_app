import 'app_disclaimer.dart';
import 'app_enums.dart';
import 'firestore_date.dart';

class ResultSummary {
  const ResultSummary({
    required this.summaryId,
    required this.sessionId,
    required this.childId,
    required this.userId,
    required this.explanationText,
    required this.recommendationText,
    required this.generatedBy,
    required this.disclaimer,
    required this.createdAt,
  });

  final String summaryId;
  final String sessionId;
  final String childId;
  final String userId;
  final String explanationText;
  final String recommendationText;
  final SummaryGenerator generatedBy;
  final String disclaimer;
  final DateTime? createdAt;

  factory ResultSummary.fromFirestore(Map<String, dynamic> data) {
    return ResultSummary(
      summaryId: data['summaryId'] as String,
      sessionId: data['sessionId'] as String,
      childId: data['childId'] as String,
      userId: data['userId'] as String,
      explanationText: data['explanationText'] as String,
      recommendationText: data['recommendationText'] as String,
      generatedBy: SummaryGeneratorFirestore.fromValue(
        data['generatedBy'] as String,
      ),
      disclaimer: data['disclaimer'] as String? ?? meekzRequiredDisclaimer,
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }
}
