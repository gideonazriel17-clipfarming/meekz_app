import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_enums.dart';
import '../../services/child_profile_service.dart';
import '../../services/app_providers.dart';
import '../../widgets/meekz_theme.dart';
import '../../widgets/shared_widgets.dart';

class ChildProfileFormScreen extends ConsumerStatefulWidget {
  const ChildProfileFormScreen({super.key, this.childId});
  final String? childId;

  @override
  ConsumerState<ChildProfileFormScreen> createState() =>
      _ChildProfileFormScreenState();
}

class _ChildProfileFormScreenState
    extends ConsumerState<ChildProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  int? _selectedAge;
  String? _selectedGender;
  LanguageCode _selectedLanguage = LanguageCode.en;
  final _schoolCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.childId != null;

  final _ageOptions = [6, 7, 8];

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadChild();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChild() async {
    setState(() => _loading = true);
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) return;
      final child = await ChildProfileService().getChildProfile(
        userId: uid,
        childId: widget.childId!,
      );
      _nameCtrl.text = child.nameOrNickname;
      _selectedAge = child.age;
      _selectedGender = child.gender;
      _selectedLanguage = child.preferredLanguage;
      _schoolCtrl.text = child.schoolYear ?? '';
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAge == null) {
      setState(() => _error = 'Please select the child\'s age.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception('Not signed in');

      final service = ChildProfileService();

      if (_isEditing) {
        await service.updateChildProfile(
          userId: uid,
          childId: widget.childId!,
          nameOrNickname: _nameCtrl.text,
          age: _selectedAge,
          gender: _selectedGender,
          preferredLanguage: _selectedLanguage,
          schoolYear: _schoolCtrl.text.isNotEmpty ? _schoolCtrl.text : null,
        );
      } else {
        await service.createChildProfile(
          userId: uid,
          nameOrNickname: _nameCtrl.text,
          age: _selectedAge!,
          preferredLanguage: _selectedLanguage,
          gender: _selectedGender,
          schoolYear: _schoolCtrl.text.isNotEmpty ? _schoolCtrl.text : null,
        );
      }

      ref.invalidate(childrenProvider(uid));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeekzRadius.xl)),
        title: Text('Delete profile?',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to delete this child profile? This action is permanent and all screening progress will be lost.',
          style: GoogleFonts.quicksand(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: MeekzColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteProfile();
    }
  }

  Future<void> _deleteProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception('Not signed in');

      await ChildProfileService().softDeleteChildProfile(
        userId: uid,
        childId: widget.childId!,
      );

      ref.invalidate(childrenProvider(uid));
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeekzColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Child Profile' : 'Add Child'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading && _isEditing
          ? const LoadingBody(message: 'Loading profile…')
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ── Name ────────────────────────────────────────────
                  SectionHeader(title: 'Child\'s name or nickname'),
                  const SizedBox(height: 10),
                  MeekzTextField(
                    controller: _nameCtrl,
                    label: 'Name / Nickname',
                    hint: 'e.g. Amir, Lily',
                    textCapitalization: TextCapitalization.words,
                    maxLength: 40,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),

                  const SizedBox(height: 30),

                  // ── Age — large tiles ────────────────────────────────
                  SectionHeader(
                    title: 'Age',
                    subtitle: 'Meekz supports children aged 6 to 8 only.',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: _ageOptions
                        .map(
                          (age) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _AgeTile(
                                age: age,
                                selected: _selectedAge == age,
                                onTap: () => setState(() => _selectedAge = age),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 30),

                  // ── Gender ──────────────────────────────────────────
                  SectionHeader(title: 'Gender (optional)'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _GenderChip(
                        label: '👦 Boy',
                        value: 'boy',
                        selected: _selectedGender == 'boy',
                        onTap: () => setState(() => _selectedGender = 'boy'),
                      ),
                      _GenderChip(
                        label: '👧 Girl',
                        value: 'girl',
                        selected: _selectedGender == 'girl',
                        onTap: () => setState(() => _selectedGender = 'girl'),
                      ),
                      _GenderChip(
                        label: 'Prefer not to say',
                        value: 'preferNotToSay',
                        selected: _selectedGender == 'preferNotToSay',
                        onTap: () =>
                            setState(() => _selectedGender = 'preferNotToSay'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── Language — colourful tiles ───────────────────────
                  SectionHeader(title: 'Preferred language'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _LangTile(
                        label: 'English',
                        abbr: 'EN',
                        accentColor: MeekzColors.primary,
                        code: LanguageCode.en,
                        selected: _selectedLanguage == LanguageCode.en,
                        onTap: () =>
                            setState(() => _selectedLanguage = LanguageCode.en),
                      ),
                      const SizedBox(width: 10),
                      _LangTile(
                        label: 'Bahasa\nMelayu',
                        abbr: 'BM',
                        accentColor: MeekzColors.numeracy,
                        code: LanguageCode.ms,
                        selected: _selectedLanguage == LanguageCode.ms,
                        onTap: () =>
                            setState(() => _selectedLanguage = LanguageCode.ms),
                      ),
                      const SizedBox(width: 10),
                      _LangTile(
                        label: '中文',
                        abbr: '中',
                        accentColor: MeekzColors.literacy,
                        code: LanguageCode.zh,
                        selected: _selectedLanguage == LanguageCode.zh,
                        onTap: () =>
                            setState(() => _selectedLanguage = LanguageCode.zh),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── School year (optional) ───────────────────────────
                  SectionHeader(title: 'School year (optional)'),
                  const SizedBox(height: 10),
                  MeekzTextField(
                    controller: _schoolCtrl,
                    label: 'e.g. Year 1, Darjah 1',
                  ),

                  const SizedBox(height: 30),
                  if (_error != null) ...[
                    _ErrorBanner(_error!),
                    const SizedBox(height: 16),
                  ],
                  MeekzButton(
                    label: _isEditing ? 'Save Changes' : 'Add Child',
                    onPressed: _submit,
                    isLoading: _loading,
                    icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 14),
                    MeekzButton(
                      label: 'Delete Profile',
                      variant: MeekzButtonVariant.danger,
                      onPressed: () => _confirmDelete(context),
                      isLoading: _loading,
                      icon: Icons.delete_forever_rounded,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ─── Age tile — extra-large for children to tap easily ───────────────────────
class _AgeTile extends StatelessWidget {
  const _AgeTile({
    required this.age,
    required this.selected,
    required this.onTap,
  });

  final int age;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 88,
        decoration: BoxDecoration(
          color: selected ? MeekzColors.primary : MeekzColors.surface,
          borderRadius: BorderRadius.circular(MeekzRadius.xl),
          border: Border.all(
            color: selected ? MeekzColors.primary : MeekzColors.border,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: MeekzColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$age',
              style: GoogleFonts.quicksand(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : MeekzColors.ink,
              ),
            ),
            Text(
              'years',
              style: GoogleFonts.quicksand(
                fontSize: 11,
                color: selected
                    ? Colors.white.withValues(alpha: 0.8)
                    : MeekzColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gender chip ──────────────────────────────────────────────────────────────
class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : MeekzColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─── Language tile — clean no-flag design ────────────────────────────────────
class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.abbr,
    required this.accentColor,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String abbr;
  final Color accentColor;
  final LanguageCode code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? accentColor : MeekzColors.surface;
    final borderColor = selected ? accentColor : MeekzColors.border;
    final labelColor = selected ? Colors.white : MeekzColors.ink;
    final mutedColor =
        selected ? Colors.white.withValues(alpha: 0.75) : MeekzColors.muted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 115,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(MeekzRadius.xl),
            border: Border.all(
              color: borderColor,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Abbreviation badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  abbr,
                  style: GoogleFonts.quicksand(
                    fontSize: abbr.length > 2 ? 18 : 16,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  height: 1.3,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: mutedColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
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
