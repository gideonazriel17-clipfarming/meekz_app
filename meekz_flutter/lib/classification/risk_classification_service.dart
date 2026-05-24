import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_disclaimer.dart';
import '../models/app_enums.dart';
import '../models/game_result.dart';
import '../models/risk_classification.dart';
import '../services/firestore_paths.dart';
import '../services/game_result_service.dart';
import '../services/meekz_exception.dart';

class RiskClassificationDraft {
  const RiskClassificationDraft({
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
  });

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
}

class RiskClassificationService {
  RiskClassificationService({
    FirebaseFirestore? firestore,
    GameResultService? gameResultService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _gameResultService =
            gameResultService ?? GameResultService(firestore: firestore);

  static const missedPromptsHighThreshold = 3;
  static const inactivityHighThreshold = 3;
  static const repeatedErrorsHighThreshold = 2;

  final FirebaseFirestore _firestore;
  final GameResultService _gameResultService;

  CollectionReference<Map<String, dynamic>> get _classifications =>
      _firestore.collection(FirestorePaths.riskClassifications);

  Future<RiskClassification> generateClassification({
    required String userId,
    required String sessionId,
  }) async {
    final results = await _gameResultService.getResultsForSession(
      userId: userId,
      sessionId: sessionId,
    );

    if (results.isEmpty) {
      throw const MeekzException(
        'At least one game result is required before generating a preliminary screening result.',
      );
    }

    final firstResult = results.first;
    final draft = calculateClassification(
      userId: userId,
      childId: firstResult.childId,
      sessionId: sessionId,
      gameResults: results,
    );

    return _saveDraft(draft);
  }

  Future<RiskClassification?> getClassificationForSession({
    required String userId,
    required String sessionId,
  }) async {
    final snapshot = await _classifications
        .where('userId', isEqualTo: userId)
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return RiskClassification.fromFirestore(snapshot.docs.first.data());
  }

  Future<RiskClassification> recalculateClassification({
    required String userId,
    required String sessionId,
  }) async {
    final existing = await getClassificationForSession(
      userId: userId,
      sessionId: sessionId,
    );
    final results = await _gameResultService.getResultsForSession(
      userId: userId,
      sessionId: sessionId,
    );

    if (results.isEmpty) {
      throw const MeekzException(
        'At least one game result is required before recalculating indicators.',
      );
    }

    final draft = calculateClassification(
      userId: userId,
      childId: results.first.childId,
      sessionId: sessionId,
      gameResults: results,
    );

    if (existing == null) {
      return _saveDraft(draft);
    }

    final doc = _classifications.doc(existing.classificationId);
    await doc.update(_draftToFirestore(draft));
    final snapshot = await doc.get();
    return RiskClassification.fromFirestore(snapshot.data()!);
  }

  static RiskClassificationDraft calculateClassification({
    required String userId,
    required String childId,
    required String sessionId,
    required List<GameResult> gameResults,
  }) {
    final reasonCodes = <String>{'CHAPTER_3_POINT_BASED_SCORING'};
    final indicators = <ScreeningDomain, IndicatorLevel>{};
    var hasIncompleteTask = false;
    var hasReviewPattern = false;

    for (final domain in ScreeningDomain.values) {
      final domainResults =
          gameResults.where((result) => result.domain == domain).toList();

      if (domainResults.isEmpty) {
        indicators[domain] = IndicatorLevel.inconclusive;
        reasonCodes.add('DOMAIN_NOT_ASSESSED');
        continue;
      }

      final metrics = _aggregateDomainMetrics(domainResults);

      if (metrics.totalQuestions == 0) {
        indicators[domain] = IndicatorLevel.inconclusive;
        reasonCodes.add('DOMAIN_INSUFFICIENT_DATA');
        continue;
      }

      hasIncompleteTask = hasIncompleteTask || metrics.hasIncompleteTask;
      hasReviewPattern = hasReviewPattern || metrics.hasReviewPattern;

      final indicator = _indicatorFromMetrics(metrics, reasonCodes);
      indicators[domain] = indicator;
    }

    final assessedIndicators = indicators.values
        .where((indicator) => indicator != IndicatorLevel.inconclusive)
        .toList();

    final overallIndicator = _overallIndicator(assessedIndicators);
    final reliabilityFlag = _reliabilityFlag(
      assessedDomainCount: assessedIndicators.length,
      hasIncompleteTask: hasIncompleteTask,
      hasReviewPattern: hasReviewPattern,
      reasonCodes: reasonCodes,
    );

    return RiskClassificationDraft(
      sessionId: sessionId,
      childId: childId,
      userId: userId,
      literacyIndicator:
          indicators[ScreeningDomain.literacy] ?? IndicatorLevel.inconclusive,
      numeracyIndicator:
          indicators[ScreeningDomain.numeracy] ?? IndicatorLevel.inconclusive,
      attentionIndicator:
          indicators[ScreeningDomain.attention] ?? IndicatorLevel.inconclusive,
      overallIndicator: overallIndicator,
      reliabilityFlag: reliabilityFlag,
      reasonCodes: reasonCodes.toList()..sort(),
      disclaimer: meekzRequiredDisclaimer,
    );
  }

  Future<RiskClassification> _saveDraft(RiskClassificationDraft draft) async {
    final doc = _classifications.doc();
    await doc.set({
      'classificationId': doc.id,
      ..._draftToFirestore(draft),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await doc.get();
    return RiskClassification.fromFirestore(snapshot.data()!);
  }

  Map<String, dynamic> _draftToFirestore(RiskClassificationDraft draft) {
    return {
      'sessionId': draft.sessionId,
      'childId': draft.childId,
      'userId': draft.userId,
      'literacyIndicator': draft.literacyIndicator.value,
      'numeracyIndicator': draft.numeracyIndicator.value,
      'attentionIndicator': draft.attentionIndicator.value,
      'overallIndicator': draft.overallIndicator.value,
      'reliabilityFlag': draft.reliabilityFlag.value,
      'reasonCodes': draft.reasonCodes,
      'disclaimer': draft.disclaimer,
    };
  }

  static _DomainMetrics _aggregateDomainMetrics(List<GameResult> results) {
    final totalQuestions = results.fold<int>(
      0,
      (total, result) => total + result.totalQuestions,
    );
    final correctAnswers = results.fold<int>(
      0,
      (total, result) => total + result.correctAnswers,
    );
    final missedPrompts = results.fold<int>(
      0,
      (total, result) => total + result.missedPrompts,
    );
    final inactivityCount = results.fold<int>(
      0,
      (total, result) => total + result.inactivityCount,
    );
    final repeatedErrors = results.fold<int>(
      0,
      (total, result) => total + result.repeatedErrors,
    );
    final averageResponseTimeMs = results.isEmpty
        ? 0.0
        : results.fold<int>(
                0, (total, result) => total + result.averageResponseTimeMs) /
            results.length;

    return _DomainMetrics(
      totalQuestions: totalQuestions,
      accuracy: totalQuestions == 0 ? 0.0 : correctAnswers / totalQuestions,
      averageResponseTimeMs: averageResponseTimeMs,
      missedPrompts: missedPrompts,
      inactivityCount: inactivityCount,
      repeatedErrors: repeatedErrors,
      randomResponseFlag: results.any((result) => result.randomResponseFlag),
      hasIncompleteTask: results.any((result) => !result.completed),
    );
  }

  static IndicatorLevel _indicatorFromMetrics(
    _DomainMetrics metrics,
    Set<String> reasonCodes,
  ) {
    // 1. Accuracy risk points
    int accuracyPoints = 0;
    if (metrics.accuracy >= 0.80) {
      accuracyPoints = 0;
    } else if (metrics.accuracy >= 0.60) {
      accuracyPoints = 1;
      reasonCodes.add('ACCURACY_MODERATE');
    } else if (metrics.accuracy >= 0.40) {
      accuracyPoints = 2;
      reasonCodes.add('ACCURACY_LOW');
    } else {
      accuracyPoints = 3;
      reasonCodes.add('ACCURACY_VERY_LOW');
    }

    // 2. Consistency risk points (high = 0, moderate = 1, low = 2)
    // Feasible mapping: if child matches all repeated questions -> High (0 pts),
    // else if random response flag is flagged -> Low (2 pts), else High (0 pts).
    int consistencyPoints = 0;
    if (metrics.randomResponseFlag) {
      consistencyPoints = 2;
      reasonCodes.add('CONSISTENCY_LOW');
    } else {
      consistencyPoints = 0;
    }

    // 3. Missed prompts risk points (0-1 = 0 pts, 2-3 = 1 pt, >3 = 2 pts)
    int missedPromptsPoints = 0;
    if (metrics.missedPrompts > 3) {
      missedPromptsPoints = 2;
      reasonCodes.add('MISSED_PROMPTS_HIGH');
    } else if (metrics.missedPrompts >= 2) {
      missedPromptsPoints = 1;
      reasonCodes.add('MISSED_PROMPTS_MODERATE');
    }

    // 4. Completion risk points (complete = 0 pts, incomplete = 2 pts)
    int completionPoints = 0;
    if (metrics.hasIncompleteTask) {
      completionPoints = 2;
      reasonCodes.add('TASK_INCOMPLETE');
    }

    // 5. Random response risk points (false = 0 pts, true = 2 pts)
    int randomResponsePoints = 0;
    if (metrics.randomResponseFlag) {
      randomResponsePoints = 2;
      reasonCodes.add('RANDOM_RESPONSE_PATTERN');
    }

    // 6. Inactivity risk points (normal = 0 pts, long inactivity = 1 pt)
    int inactivityPoints = 0;
    if (metrics.inactivityCount >= 3) {
      inactivityPoints = 1;
      reasonCodes.add('LONG_INACTIVITY');
    }

    final totalPoints = accuracyPoints +
        consistencyPoints +
        missedPromptsPoints +
        completionPoints +
        randomResponsePoints +
        inactivityPoints;

    IndicatorLevel indicator;
    if (totalPoints >= 6) {
      indicator = IndicatorLevel.high;
    } else if (totalPoints >= 3) {
      indicator = IndicatorLevel.moderate;
    } else {
      indicator = IndicatorLevel.low;
    }

    // Override rule: "If accuracy is below 40% and the task is completed with valid data,
    // the result must be at least moderate."
    if (metrics.accuracy < 0.40 &&
        !metrics.hasIncompleteTask &&
        metrics.totalQuestions > 0) {
      if (indicator == IndicatorLevel.low) {
        indicator = IndicatorLevel.moderate;
      }
    }

    return indicator;
  }

  static IndicatorLevel _overallIndicator(
    List<IndicatorLevel> assessedIndicators,
  ) {
    if (assessedIndicators.isEmpty) {
      return IndicatorLevel.inconclusive;
    }

    // If any domain is high, overall indicator = high.
    if (assessedIndicators.contains(IndicatorLevel.high)) {
      return IndicatorLevel.high;
    }

    // If two or more domains are moderate, overall indicator = moderate.
    final moderateCount = assessedIndicators
        .where((ind) => ind == IndicatorLevel.moderate)
        .length;
    if (moderateCount >= 2) {
      return IndicatorLevel.moderate;
    }

    // If all completed domains are low, overall indicator = low.
    if (assessedIndicators.every((ind) => ind == IndicatorLevel.low)) {
      return IndicatorLevel.low;
    }

    // If exactly one domain is moderate and others are low, overall indicator is moderate (not all low).
    if (moderateCount == 1) {
      return IndicatorLevel.moderate;
    }

    return IndicatorLevel.inconclusive;
  }

  static ReliabilityFlag _reliabilityFlag({
    required int assessedDomainCount,
    required bool hasIncompleteTask,
    required bool hasReviewPattern,
    required Set<String> reasonCodes,
  }) {
    if (assessedDomainCount == 0) {
      return ReliabilityFlag.invalid;
    }

    // If one or more required domains are inconclusive (missing domains in session), reliability flag = caution (Review needed)
    if (assessedDomainCount < ScreeningDomain.values.length) {
      reasonCodes.add('PARTIAL_SCREENING_RESULT');
      return ReliabilityFlag.caution;
    }

    if (hasIncompleteTask || hasReviewPattern) {
      return ReliabilityFlag.caution;
    }

    return ReliabilityFlag.valid;
  }

  static ScreeningSessionStatus recommendedSessionStatusFor(
    ReliabilityFlag reliabilityFlag,
  ) {
    return switch (reliabilityFlag) {
      ReliabilityFlag.valid => ScreeningSessionStatus.completed,
      ReliabilityFlag.caution => ScreeningSessionStatus.repeatRecommended,
      ReliabilityFlag.invalid => ScreeningSessionStatus.invalid,
    };
  }
}

class _DomainMetrics {
  const _DomainMetrics({
    required this.totalQuestions,
    required this.accuracy,
    required this.averageResponseTimeMs,
    required this.missedPrompts,
    required this.inactivityCount,
    required this.repeatedErrors,
    required this.randomResponseFlag,
    required this.hasIncompleteTask,
  });

  final int totalQuestions;
  final double accuracy;
  final double averageResponseTimeMs;
  final int missedPrompts;
  final int inactivityCount;
  final int repeatedErrors;
  final bool randomResponseFlag;
  final bool hasIncompleteTask;

  bool get hasReviewPattern =>
      missedPrompts >= 2 || // Missed prompts moderate or high
      inactivityCount >= 3 || // Inactivity count high
      randomResponseFlag ||
      hasIncompleteTask;
}
