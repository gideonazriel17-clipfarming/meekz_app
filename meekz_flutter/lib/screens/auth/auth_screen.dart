import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_enums.dart';
import '../../services/app_providers.dart';
import '../../services/app_router.dart';
import '../../widgets/meekz_theme.dart';
import '../../widgets/shared_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeekzColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),

              // ── Logo block ────────────────────────────────────────────
              Row(
                children: [
                  // Warm-teal rounded logo badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: MeekzColors.primary,
                      borderRadius: BorderRadius.circular(MeekzRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: MeekzColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('M',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meekz',
                        style: GoogleFonts.quicksand(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: MeekzColors.ink,
                        ),
                      ),
                      Text(
                        'Learning indicator screening · Ages 6–8',
                        style: GoogleFonts.quicksand(
                            fontSize: 12, color: MeekzColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Tab selector ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: MeekzColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(MeekzRadius.lg),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: MeekzColors.surface,
                    borderRadius: BorderRadius.circular(MeekzRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: MeekzColors.ink.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  labelColor: MeekzColors.ink,
                  unselectedLabelColor: MeekzColors.muted,
                  labelStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700, fontSize: 15),
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Form views (no fixed height — grows to fit) ─────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _tabIndex == 0
                    ? const _SignInForm(key: ValueKey('signin'))
                    : const _SignUpForm(key: ValueKey('signup')),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sign In Form ─────────────────────────────────────────────────────────────
class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm({super.key});

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).login(
            email: _emailCtrl.text,
            password: _passCtrl.text,
          );
      if (mounted) context.go(MeekzRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authMessage(e.code, e.message));
    } catch (_) {
      setState(
          () => _error = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeekzTextField(
            controller: _emailCtrl,
            label: 'Email address',
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 14),
          MeekzTextField(
            controller: _passCtrl,
            label: 'Password',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: MeekzColors.muted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? 'Minimum 6 characters' : null,
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            _ErrorCard(_error!),
            const SizedBox(height: 14),
          ],
          MeekzButton(
            label: 'Sign In',
            onPressed: _submit,
            isLoading: _loading,
            icon: Icons.login_rounded,
          ),
        ],
      ),
    );
  }
}

// ─── Sign Up Form ─────────────────────────────────────────────────────────────
class _SignUpForm extends ConsumerStatefulWidget {
  const _SignUpForm({super.key});

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _consent = false;
  AdultRole _role = AdultRole.parent;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      setState(
          () => _error = 'You must accept the consent statement to continue.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signUpAdult(
            email: _emailCtrl.text,
            password: _passCtrl.text,
            name: _nameCtrl.text,
            role: _role,
            consentAccepted: true,
          );
      if (mounted) context.go(MeekzRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authMessage(e.code, e.message));
    } catch (_) {
      setState(
          () => _error = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeekzTextField(
            controller: _nameCtrl,
            label: 'Full name',
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          MeekzTextField(
            controller: _emailCtrl,
            label: 'Email address',
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 14),
          MeekzTextField(
            controller: _passCtrl,
            label: 'Password',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: MeekzColors.muted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? 'Minimum 6 characters' : null,
          ),
          const SizedBox(height: 16),

          // ── Role selector ────────────────────────────────────────────
          Text(
            'I am a',
            style: GoogleFonts.quicksand(
                fontSize: 13,
                color: MeekzColors.muted,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _RoleChip(
                label: 'Parent',
                selected: _role == AdultRole.parent,
                onTap: () => setState(() => _role = AdultRole.parent),
              ),
              _RoleChip(
                label: 'Teacher',
                selected: _role == AdultRole.teacher,
                onTap: () => setState(() => _role = AdultRole.teacher),
              ),
              _RoleChip(
                label: 'Counsellor',
                selected: _role == AdultRole.schoolCounselor,
                onTap: () =>
                    setState(() => _role = AdultRole.schoolCounselor),
              ),
              _RoleChip(
                label: 'Support',
                selected: _role == AdultRole.supportPersonnel,
                onTap: () =>
                    setState(() => _role = AdultRole.supportPersonnel),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Consent ──────────────────────────────────────────────────
          _ConsentCheckbox(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            _ErrorCard(_error!),
            const SizedBox(height: 14),
          ],
          MeekzButton(
            label: 'Create Account',
            onPressed: _submit,
            isLoading: _loading,
            icon: Icons.person_add_rounded,
          ),
        ],
      ),
    );
  }
}

// ─── Role chip ────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: selected ? MeekzColors.primary : MeekzColors.surface,
          borderRadius: BorderRadius.circular(MeekzRadius.pill),
          border: Border.all(
            color: selected ? MeekzColors.primary : MeekzColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : MeekzColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─── Consent checkbox ─────────────────────────────────────────────────────────
class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value
              ? MeekzColors.primary.withValues(alpha: 0.06)
              : MeekzColors.surface,
          borderRadius: BorderRadius.circular(MeekzRadius.md),
          border: Border.all(
            color: value ? MeekzColors.primary : MeekzColors.border,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: MeekzColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'I understand that Meekz provides preliminary screening indicators only, and I consent to data being stored securely for this purpose.',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: MeekzColors.muted,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MeekzColors.indicatorHighBg,
        borderRadius: BorderRadius.circular(MeekzRadius.md),
        border: Border.all(color: MeekzColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: MeekzColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.quicksand(
                  color: MeekzColors.danger, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Auth error message helper (unchanged logic) ─────────────────────────────
String _authMessage(String code, [String? message]) {
  final normalizedMessage = message?.toLowerCase() ?? '';
  if (normalizedMessage.contains('configuration_not_found')) {
    return 'Firebase Authentication is not configured for this project. Enable Email/Password sign-in in Firebase Console.';
  }

  return switch (code) {
    'user-not-found' => 'No account found with this email.',
    'wrong-password' => 'Incorrect password. Please try again.',
    'invalid-credential' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Password is too weak. Use at least 6 characters.',
    'network-request-failed' =>
      'No internet connection. Please check your network.',
    'internal-error' =>
      'Firebase Authentication is not configured for this project. Enable Email/Password sign-in in Firebase Console.',
    _ => 'Authentication failed. Please try again.',
  };
}
