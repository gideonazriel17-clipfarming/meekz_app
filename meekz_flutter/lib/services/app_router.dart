import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/child/child_profile_form_screen.dart';
import '../screens/assessment/assessment_menu_screen.dart';
import '../screens/game/game_screen.dart';
import '../screens/report/report_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

// Route name constants
class MeekzRoutes {
  MeekzRoutes._();
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const dashboard = '/dashboard';
  static const childNew = '/children/new';
  static const childEdit = '/children/:childId/edit';
  static const assessment = '/children/:childId/sessions/:sessionId/assessment';
  static const game = '/children/:childId/sessions/:sessionId/game/:domain';
  static const report = '/children/:childId/sessions/:sessionId/report';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: MeekzRoutes.onboarding,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isOnAuth = state.matchedLocation == MeekzRoutes.auth;
      final isOnOnboarding = state.matchedLocation == MeekzRoutes.onboarding;

      if (!isLoggedIn && !isOnAuth && !isOnOnboarding) {
        return MeekzRoutes.auth;
      }

      if (isLoggedIn && (isOnAuth || isOnOnboarding)) {
        return MeekzRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: MeekzRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: MeekzRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: MeekzRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: MeekzRoutes.childNew,
        builder: (context, state) => const ChildProfileFormScreen(),
      ),
      GoRoute(
        path: MeekzRoutes.childEdit,
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          return ChildProfileFormScreen(childId: childId);
        },
      ),
      GoRoute(
        path: MeekzRoutes.assessment,
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          final sessionId = state.pathParameters['sessionId']!;
          return AssessmentMenuScreen(
            childId: childId,
            sessionId: sessionId,
          );
        },
      ),
      GoRoute(
        path: MeekzRoutes.game,
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          final sessionId = state.pathParameters['sessionId']!;
          final domain = state.pathParameters['domain']!;
          return GameScreen(
            childId: childId,
            sessionId: sessionId,
            domain: domain,
          );
        },
      ),
      GoRoute(
        path: MeekzRoutes.report,
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          final sessionId = state.pathParameters['sessionId']!;
          return ReportScreen(
            childId: childId,
            sessionId: sessionId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
