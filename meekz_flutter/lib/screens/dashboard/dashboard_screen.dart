import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/child_profile.dart';
import '../../models/app_enums.dart';
import '../../services/screening_session_service.dart';
import '../../services/app_providers.dart';
import '../../services/app_router.dart';
import '../../widgets/meekz_theme.dart';
import '../../widgets/shared_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(body: LoadingBody()),
      error: (e, _) => Scaffold(body: ErrorBody(message: e.toString())),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go(MeekzRoutes.auth));
          return const Scaffold(body: LoadingBody());
        }

        return _DashboardContent(uid: user.uid);
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final childrenAsync = ref.watch(childrenProvider(uid));

    return Scaffold(
      backgroundColor: MeekzColors.background,
      appBar: AppBar(
        title: const Text('Meekz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) context.go(MeekzRoutes.auth);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(MeekzRoutes.childNew),
        backgroundColor: MeekzColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Child',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeekzRadius.xl)),
      ),
      body: RefreshIndicator(
        color: MeekzColors.primary,
        onRefresh: () async {
          ref.invalidate(userProfileProvider(uid));
          ref.invalidate(childrenProvider(uid));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            // ── Greeting ────────────────────────────────────────────────
            profileAsync.when(
              loading: () => const _GreetingShimmer(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) => _GreetingHeader(
                name: profile.name.split(' ').first,
                role: profile.role,
              ),
            ),
            const SizedBox(height: 24),

            // ── Children list ────────────────────────────────────────────
            SectionHeader(
              title: 'Children',
              subtitle: 'Tap "Start Screening" to begin a session',
            ),
            const SizedBox(height: 16),
            childrenAsync.when(
              loading: () => const LoadingBody(message: 'Loading profiles…'),
              error: (e, _) => ErrorBody(
                message: e.toString(),
                onRetry: () => ref.invalidate(childrenProvider(uid)),
              ),
              data: (children) => children.isEmpty
                  ? _EmptyChildState(uid: uid)
                  : Column(
                      children: children
                          .map((child) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ChildCard(child: child, uid: uid),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Greeting header ──────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.name, required this.role});
  final String name;
  final AdultRole role;

  String get _roleLabel => switch (role) {
        AdultRole.parent => 'Parent',
        AdultRole.teacher => 'Teacher',
        AdultRole.schoolCounselor => 'School Counsellor',
        AdultRole.supportPersonnel => 'Support Personnel',
        AdultRole.admin => 'Admin',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Warm green gradient header — welcoming, professional.
          gradient: LinearGradient(
            colors: [
              MeekzColors.primary.withValues(alpha: 0.92),
              MeekzColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(MeekzRadius.xl),
          boxShadow: [
            BoxShadow(
              color: MeekzColors.primary.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name 👋',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel,
                    style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(MeekzRadius.pill),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Text(
                _roleLabel,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Child card ───────────────────────────────────────────────────────────────
class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.child, required this.uid});
  final ChildProfile child;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langLabel = switch (child.preferredLanguage) {
      LanguageCode.en => 'English',
      LanguageCode.ms => 'Bahasa Melayu',
      LanguageCode.zh => '中文',
    };

    return MeekzCard(
      onTap: () => _startOrResumeSession(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Coloured avatar circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      MeekzColors.literacy,
                      MeekzColors.numeracy,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(MeekzRadius.md),
                ),
                child: Center(
                  child: Text(
                    child.nameOrNickname.isNotEmpty
                        ? child.nameOrNickname[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.nameOrNickname,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: MeekzColors.ink,
                      ),
                    ),
                    Text(
                      'Age ${child.age}  ·  $langLabel',
                      style: GoogleFonts.quicksand(
                          fontSize: 13, color: MeekzColors.muted),
                    ),
                  ],
                ),
              ),
              // Edit icon
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: MeekzColors.muted, size: 20),
                onPressed: () => context.push(
                  MeekzRoutes.childEdit.replaceAll(':childId', child.childId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: MeekzColors.border.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          MeekzButton(
            label: 'Start Screening',
            onPressed: () => _startOrResumeSession(context, ref),
            icon: Icons.play_arrow_rounded,
          ),
        ],
      ),
    );
  }

  Future<void> _startOrResumeSession(
      BuildContext context, WidgetRef ref) async {
    final sessionService = ScreeningSessionService();
    final lang = ref.read(selectedLanguageProvider);
    try {
      final session = await sessionService.startSession(
        userId: uid,
        childId: child.childId,
        language: lang,
        consentConfirmed: true,
      );
      if (context.mounted) {
        context.push(
          MeekzRoutes.assessment
              .replaceAll(':childId', child.childId)
              .replaceAll(':sessionId', session.sessionId),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: MeekzColors.danger,
          ),
        );
      }
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyChildState extends StatelessWidget {
  const _EmptyChildState({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            // Pastel illustration container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: MeekzColors.pastelBlue,
                borderRadius: BorderRadius.circular(MeekzRadius.xl),
              ),
              child: const Center(
                  child: Text('👶', style: TextStyle(fontSize: 56))),
            ),
            const SizedBox(height: 20),
            Text(
              'No children added yet',
              style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MeekzColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Child" to create a profile\nand begin a screening session.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(fontSize: 14, color: MeekzColors.muted),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: MeekzButton(
                label: 'Add Child',
                onPressed: () => context.push(MeekzRoutes.childNew),
                icon: Icons.add_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Greeting shimmer ─────────────────────────────────────────────────────────
class _GreetingShimmer extends StatelessWidget {
  const _GreetingShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: MeekzColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(MeekzRadius.xl),
        ),
      ),
    );
  }
}
