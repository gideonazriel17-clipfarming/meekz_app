import 'app_enums.dart';
import 'firestore_date.dart';

class GameResult {
  const GameResult({
    required this.resultId,
    required this.sessionId,
    required this.childId,
    required this.userId,
    required this.domain,
    required this.gameType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracy,
    required this.averageResponseTimeMs,
    required this.missedPrompts,
    required this.inactivityCount,
    required this.repeatedErrors,
    required this.randomResponseFlag,
    required this.completed,
    required this.createdAt,
    this.completionRate,
    this.consistencyScore,
  });

  final String resultId;
  final String sessionId;
  final String childId;
  final String userId;
  final ScreeningDomain domain;
  final String gameType;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;
  final int averageResponseTimeMs;
  final int missedPrompts;
  final int inactivityCount;
  final int repeatedErrors;
  final bool randomResponseFlag;
  final bool completed;
  final DateTime? createdAt;
  final double? completionRate;
  final double? consistencyScore;

  factory GameResult.fromFirestore(Map<String, dynamic> data) {
    return GameResult(
      resultId: data['resultId'] as String,
      sessionId: data['sessionId'] as String,
      childId: data['childId'] as String,
      userId: data['userId'] as String,
      domain: ScreeningDomainFirestore.fromValue(data['domain'] as String),
      gameType: data['gameType'] as String,
      totalQuestions: data['totalQuestions'] as int,
      correctAnswers: data['correctAnswers'] as int,
      incorrectAnswers: data['incorrectAnswers'] as int,
      accuracy: (data['accuracy'] as num).toDouble(),
      averageResponseTimeMs: data['averageResponseTimeMs'] as int,
      missedPrompts: data['missedPrompts'] as int,
      inactivityCount: data['inactivityCount'] as int,
      repeatedErrors: data['repeatedErrors'] as int,
      randomResponseFlag: data['randomResponseFlag'] as bool? ?? false,
      completed: data['completed'] as bool? ?? false,
      createdAt: dateTimeFromFirestore(data['createdAt']),
      completionRate: data['completionRate'] != null
          ? (data['completionRate'] as num).toDouble()
          : null,
      consistencyScore: data['consistencyScore'] != null
          ? (data['consistencyScore'] as num).toDouble()
          : null,
    );
  }
}
