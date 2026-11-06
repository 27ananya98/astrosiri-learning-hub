import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../domain/models/learning_subject.dart';
import '../../../../domain/models/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/subject_image_widget.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final User user;
  final List<LearningSubject> subjects;

  const SubjectSelectionScreen({
    super.key,
    required this.user,
    required this.subjects,
  });

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  late final Set<String> _selectedIds;
  late final Set<String> _profileSelectedIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.user.areasOfInterest};

    // Keep the save payload canonical. Profile data can contain a subject
    // id, slug, or title, while the catalogue provides the canonical id.
    // Matching those values here also makes every visible subject reversible.
    for (final subject in widget.subjects) {
      final matchingValues = _selectedIds
          .where((value) => _subjectKeys(subject).contains(_normalize(value)))
          .toList();
      if (matchingValues.isNotEmpty) {
        _selectedIds
          ..removeAll(matchingValues)
          ..add(subject.id);
      }
    }

    // Subjects already saved in the Profile API remain selected and cannot
    // be removed here. Newly added subjects remain fully reversible.
    _profileSelectedIds = {..._selectedIds};
  }

  String _normalize(String value) => value.trim().toLowerCase();

  Set<String> _subjectKeys(LearningSubject subject) => {
    _normalize(subject.id),
    _normalize(subject.slug),
    _normalize(subject.title),
  };

  bool _isSubjectSelected(LearningSubject subject) {
    final keys = _subjectKeys(subject);
    return _selectedIds.any((value) => keys.contains(_normalize(value)));
  }

  void _toggleSubject(LearningSubject subject) {
    final keys = _subjectKeys(subject);
    final matchingValues = _selectedIds
        .where((value) => keys.contains(_normalize(value)))
        .toList();

    if (matchingValues.any(_profileSelectedIds.contains)) return;

    setState(() {
      if (matchingValues.isNotEmpty) {
        _selectedIds.removeAll(matchingValues);
      } else {
        _selectedIds.add(subject.id);
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_selectedIds.isEmpty) {
      AppToast.error(
        context,
        'Select at least one active subject to personalize your learning path.',
        title: 'Choose a Subject',
      );
      return;
    }

    setState(() => _isSaving = true);
    var didPopAfterSave = false;
    try {
      final saved = await context.read<AuthCubit>().updateUserSubjects(
        _selectedIds.toList(),
      );
      if (!mounted) return;
      if (saved) {
        // Clear the loading state before leaving the route so the popped
        // screen is never rebuilt with a stale async state.
        setState(() => _isSaving = false);
        didPopAfterSave = true;
        AppToast.success(
          context,
          'Your learning subjects were updated successfully.',
          title: 'Subjects Saved',
        );
        Navigator.of(context).pop(true);
      } else {
        AppToast.error(
          context,
          'We could not save your subjects. Please try again.',
          title: 'Save Failed',
        );
      }
    } finally {
      if (mounted && !didPopAfterSave) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSaving && mounted) {
          AppToast.info(
            context,
            'Please wait while your subjects are being saved.',
            title: 'Saving Subjects',
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
          title: Text(
            'Choose your subjects',
            style: AppTypography.headingMD(
              color: AppColors.midnightNavy,
              fontWeight: FontWeight.w600,
            ).copyWith(fontSize: 19),
          ),
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    widget.subjects.isEmpty
                        ? 'No subjects are available right now.'
                        : 'All available subjects (${widget.subjects.length})',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    itemCount: widget.subjects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final subject = widget.subjects[index];
                      final selected = _isSubjectSelected(subject);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        // Every visible subject is reversible, including a
                        // subject represented by a slug/title in the profile
                        // response or one marked inactive by that response.
                        onTap: _isSaving ? null : () => _toggleSubject(subject),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFFFBEB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.saffronGold
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SubjectImageWidget(
                                iconUrl: subject.iconUrl,
                                imageUrl: subject.imageUrl,
                                slug: subject.slug,
                                title: subject.title,
                                width: 58,
                                height: 58,
                                borderRadius: 10,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.title,
                                      style: AppTypography.headingMD(
                                        color: AppColors.midnightNavy,
                                        fontWeight: FontWeight.w600,
                                      ).copyWith(fontSize: 16),
                                    ),
                                    if (subject.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subject.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            AppTypography.bodyRegular(
                                              color: const Color(0xFF64748B),
                                              fontWeight: FontWeight.w400,
                                            ).copyWith(
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: selected
                                    ? AppColors.saffronGold
                                    : const Color(0xFFCBD5E1),
                                size: 26,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isSaving)
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midnightNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save subjects (${_selectedIds.length})',
                      style: AppTypography.buttonLabel(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
