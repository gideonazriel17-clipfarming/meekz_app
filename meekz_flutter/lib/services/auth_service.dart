import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_enums.dart';
import 'user_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    UserService? userService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseAuth _firebaseAuth;
  final UserService _userService;

  User? getCurrentUser() => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<UserCredential> signUpAdult({
    required String email,
    required String password,
    required String name,
    required AdultRole role,
    required bool consentAccepted,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await _userService.createUserProfile(
        userId: user.uid,
        name: name,
        email: email,
        role: role,
        consentAccepted: consentAccepted,
      );
    }

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() => _firebaseAuth.signOut();
}
