import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_enums.dart';
import '../models/screening_session.dart';
import 'child_profile_service.dart';
import 'firestore_paths.dart';
import 'meekz_exception.dart';
import 'user_service.dart';

class ScreeningSessionService {
  ScreeningSessionService({
    FirebaseFirestore? firestore,
    UserService? userService,
    ChildProfileService? childProfileService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userService = userService ?? UserService(firestore: firestore),
        _childProfileService =
            childProfileService ?? ChildProfileService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final UserService _userService;
  final ChildProfileService _childProfileService;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(FirestorePaths.screeningSessions);

  Future<ScreeningSession> startSession({
    required String userId,
    required String childId,
    required LanguageCode language,
    required bool consentConfirmed,
  }) async {
    if (!consentConfirmed) {
      throw const MeekzException('Consent must be provided before screening.');
    }

    final userProfile = await _userService.getUserProfile(userId);
    if (!userProfile.consentAccepted) {
      throw const MeekzException('Adult consent is required before screening.');
    }

    final child = await _childProfileService.getChildProfile(
      userId: userId,
      childId: childId,
    );
    if (!child.isEligibleForScreening) {
      throw const MeekzException(
        'This child profile is not eligible to start screening.',
      );
    }

    final doc = _sessions.doc();
    await doc.set({
      'sessionId': doc.id,
      'childId': childId,
      'userId': userId,
      'language': language.value,
      'startedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'status': ScreeningSessionStatus.notStarted.value,
      'consentConfirmed': true,
      'domainsCompleted': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await doc.get();
    return ScreeningSession.fromFirestore(snapshot.data()!);
  }

  Future<ScreeningSession> getSession({
    required String userId,
    required String sessionId,
  }) async {
    final snapshot = await _sessions.doc(sessionId).get();
    final data = snapshot.data();

    if (data == null || data['userId'] != userId) {
      throw const MeekzException('Screening session was not found.');
    }

    return ScreeningSession.fromFirestore(data);
  }

  Future<void> markSessionInProgress({
    required String userId,
    required String sessionId,
  }) async {
    await getSession(userId: userId, sessionId: sessionId);
    await _sessions.doc(sessionId).update({
      'status': ScreeningSessionStatus.inProgress.value,
    });
  }

  Future<void> updateDomainsCompleted({
    required String userId,
    required String sessionId,
    required List<ScreeningDomain> domainsCompleted,
  }) async {
    await getSession(userId: userId, sessionId: sessionId);
    final uniqueDomains =
        domainsCompleted.map((domain) => domain.value).toSet();

    await _sessions.doc(sessionId).update({
      'domainsCompleted': uniqueDomains.toList(),
      'status': ScreeningSessionStatus.inProgress.value,
    });
  }

  Future<void> completeSession({
    required String userId,
    required String sessionId,
  }) async {
    await getSession(userId: userId, sessionId: sessionId);
    await _sessions.doc(sessionId).update({
      'status': ScreeningSessionStatus.completed.value,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markSessionInvalid({
    required String userId,
    required String sessionId,
  }) async {
    await getSession(userId: userId, sessionId: sessionId);
    await _sessions.doc(sessionId).update({
      'status': ScreeningSessionStatus.invalid.value,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
