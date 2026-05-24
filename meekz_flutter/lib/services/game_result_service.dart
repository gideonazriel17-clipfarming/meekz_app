import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_enums.dart';
import '../models/game_result.dart';
import 'firestore_paths.dart';
import 'meekz_exception.dart';

class GameResultService {
  GameResultService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _gameResults =>
      _firestore.collection(FirestorePaths.gameResults);

  Future<GameResult> saveGameResult({
    required String userId,
    required String sessionId,
    required String childId,
    required ScreeningDomain domain,
    required String gameType,
    required int totalQuestions,
    required int correctAnswers,
    required int incorrectAnswers,
    required int averageResponseTimeMs,
    required int missedPrompts,
    required int inactivityCount,
    required int repeatedErrors,
    required bool randomResponseFlag,
    required bool completed,
    double? completionRate,
    double? consistencyScore,
  }) async {
    _validateMetrics(
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      averageResponseTimeMs: averageResponseTimeMs,
      missedPrompts: missedPrompts,
      inactivityCount: inactivityCount,
      repeatedErrors: repeatedErrors,
    );

    final accuracy = correctAnswers / totalQuestions;
    final doc = _gameResults.doc();

    await doc.set({
      'resultId': doc.id,
      'sessionId': sessionId,
      'childId': childId,
      'userId': userId,
      'domain': domain.value,
      'gameType': gameType.trim(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'accuracy': double.parse(accuracy.toStringAsFixed(4)),
      'averageResponseTimeMs': averageResponseTimeMs,
      'missedPrompts': missedPrompts,
      'inactivityCount': inactivityCount,
      'repeatedErrors': repeatedErrors,
      'randomResponseFlag': randomResponseFlag,
      'completed': completed,
      'completionRate': completionRate,
      'consistencyScore': consistencyScore,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await doc.get();
    return GameResult.fromFirestore(snapshot.data()!);
  }

  Future<List<GameResult>> getResultsForSession({
    required String userId,
    required String sessionId,
  }) async {
    final snapshot = await _gameResults
        .where('userId', isEqualTo: userId)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    return snapshot.docs
        .map((doc) => GameResult.fromFirestore(doc.data()))
        .toList();
  }

  Future<List<GameResult>> getResultsForChild({
    required String userId,
    required String childId,
  }) async {
    final snapshot = await _gameResults
        .where('userId', isEqualTo: userId)
        .where('childId', isEqualTo: childId)
        .get();

    return snapshot.docs
        .map((doc) => GameResult.fromFirestore(doc.data()))
        .toList();
  }

  void _validateMetrics({
    required int totalQuestions,
    required int correctAnswers,
    required int incorrectAnswers,
    required int averageResponseTimeMs,
    required int missedPrompts,
    required int inactivityCount,
    required int repeatedErrors,
  }) {
    if (totalQuestions <= 0) {
      throw const MeekzException(
          'A game result must contain at least one question.');
    }

    if (correctAnswers < 0 ||
        incorrectAnswers < 0 ||
        averageResponseTimeMs < 0 ||
        missedPrompts < 0 ||
        inactivityCount < 0 ||
        repeatedErrors < 0) {
      throw const MeekzException('Game result metrics cannot be negative.');
    }

    if (correctAnswers + incorrectAnswers > totalQuestions) {
      throw const MeekzException(
        'Correct and incorrect answers cannot exceed total questions.',
      );
    }
  }
}
