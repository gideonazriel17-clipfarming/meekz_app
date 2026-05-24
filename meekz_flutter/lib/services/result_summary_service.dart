import 'package:cloud_firestore/cloud_firestore.dart';

import '../classification/risk_classification_service.dart';
import '../models/app_enums.dart';
import '../models/result_summary.dart';
import '../models/risk_classification.dart';
import 'firestore_paths.dart';
import 'meekz_exception.dart';
import 'template_explanation_service.dart';

class ResultSummaryService {
  ResultSummaryService({
    FirebaseFirestore? firestore,
    RiskClassificationService? riskClassificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _riskClassificationService = riskClassificationService ??
            RiskClassificationService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final RiskClassificationService _riskClassificationService;

  CollectionReference<Map<String, dynamic>> get _summaries =>
      _firestore.collection(FirestorePaths.resultSummaries);

  Future<ResultSummary> generateTemplateSummary({
    required String userId,
    required String sessionId,
    required String classificationId,
    LanguageCode language = LanguageCode.en,
  }) async {
    final classification = await _getClassification(
      userId: userId,
      classificationId: classificationId,
    );
    final template = const TemplateExplanationService().build(
      classification: classification,
      language: language,
    );

    final doc = _summaries.doc();
    await doc.set({
      'summaryId': doc.id,
      'sessionId': sessionId,
      'childId': classification.childId,
      'userId': userId,
      'explanationText': template.explanationText,
      'recommendationText': template.recommendationText,
      'generatedBy': SummaryGenerator.template.value,
      'disclaimer': template.disclaimer,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await doc.get();
    return ResultSummary.fromFirestore(snapshot.data()!);
  }

  Future<ResultSummary?> getSummaryForSession({
    required String userId,
    required String sessionId,
  }) async {
    final snapshot = await _summaries
        .where('userId', isEqualTo: userId)
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return ResultSummary.fromFirestore(snapshot.docs.first.data());
  }

  Future<ResultSummary> regenerateTemplateSummary({
    required String userId,
    required String sessionId,
    LanguageCode language = LanguageCode.en,
  }) async {
    final classification = await _riskClassificationService
        .getClassificationForSession(userId: userId, sessionId: sessionId);

    if (classification == null) {
      throw const MeekzException(
        'A rule-based classification is required before generating a summary.',
      );
    }

    return generateTemplateSummary(
      userId: userId,
      sessionId: sessionId,
      classificationId: classification.classificationId,
      language: language,
    );
  }

  static String buildExplanationText({
    required RiskClassification classification,
    LanguageCode language = LanguageCode.en,
  }) {
    return TemplateExplanationService.buildExplanationText(
      overallIndicator: classification.overallIndicator,
      reliabilityFlag: classification.reliabilityFlag,
      language: language,
    );
  }

  static String buildRecommendationText({
    required RiskClassification classification,
    LanguageCode language = LanguageCode.en,
  }) {
    return TemplateExplanationService.buildRecommendationText(
      overallIndicator: classification.overallIndicator,
      reliabilityFlag: classification.reliabilityFlag,
      language: language,
    );
  }

  static void assertSafeText(String text) {
    TemplateExplanationService.assertSafeText(text);
  }

  Future<RiskClassification> _getClassification({
    required String userId,
    required String classificationId,
  }) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.riskClassifications)
        .doc(classificationId)
        .get();
    final data = snapshot.data();

    if (data == null || data['userId'] != userId) {
      throw const MeekzException('Rule-based classification was not found.');
    }

    return RiskClassification.fromFirestore(data);
  }
}
