import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/adult_user_profile.dart';
import '../models/app_enums.dart';
import '../models/child_profile.dart';
import 'auth_service.dart';
import 'child_profile_service.dart';
import 'user_service.dart';

// ─── Service providers ──────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userServiceProvider = Provider<UserService>((ref) => UserService());
final childProfileServiceProvider =
    Provider<ChildProfileService>((ref) => ChildProfileService());

// ─── Auth state ─────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

// ─── Current user profile ───────────────────────────────────────────────────
final userProfileProvider =
    FutureProvider.family<AdultUserProfile, String>((ref, uid) {
  return ref.watch(userServiceProvider).getUserProfile(uid);
});

// ─── Children for current user ──────────────────────────────────────────────
final childrenProvider =
    FutureProvider.family<List<ChildProfile>, String>((ref, uid) {
  return ref.watch(childProfileServiceProvider).getActiveChildProfiles(uid);
});

// ─── Selected language (cached in session) ──────────────────────────────────
final selectedLanguageProvider =
    StateProvider<LanguageCode>((ref) => LanguageCode.en);
