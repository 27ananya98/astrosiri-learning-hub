import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/network_error.dart';
import '../../../../domain/models/learning_subject.dart';
import '../../../../domain/models/user.dart';
import '../../../../domain/repositories/learning_repository.dart';
import 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  final LearningRepository learningRepository;

  LearningCubit({required this.learningRepository})
    : super(const LearningInitial());

  Future<void> fetchSubjects(String userId, {String? token}) async {
    emit(const LearningLoading());
    try {
      final allSubjects = await learningRepository.getAllSubjects(token: token);
      List<LearningSubject> userSubjects = const [];
      try {
        userSubjects = await learningRepository.getUserSubjects(
          userId,
          token: token,
        );
      } catch (_) {
        userSubjects = const [];
      }

      User? profile;
      try {
        profile = await learningRepository.getProfile(userId, token: token);
      } catch (_) {
        profile = null;
      }
      userSubjects = _resolveUserSubjects(allSubjects, userSubjects, profile);

      emit(
        LearningLoaded(
          allSubjects: allSubjects,
          userSubjects: userSubjects,
          filteredSubjects: allSubjects,
          selectedCategory: 'All',
          userProfile: profile,
        ),
      );
    } catch (e) {
      emit(
        LearningError(
          message: NetworkErrorUtils.message(
            e,
            fallback: 'Unable to load subjects.',
          ),
          fallbackSubjects: const [],
        ),
      );
    }
  }

  void filterByCategory(String category) {
    if (state is LearningLoaded) {
      final currentState = state as LearningLoaded;
      final List<LearningSubject> filtered;

      if (category.toLowerCase() == 'all') {
        filtered = currentState.allSubjects;
      } else {
        filtered = currentState.allSubjects
            .where(
              (s) =>
                  s.title.toLowerCase() == category.toLowerCase() ||
                  s.slug.toLowerCase() == category.toLowerCase(),
            )
            .toList();
      }

      emit(
        currentState.copyWith(
          selectedCategory: category,
          filteredSubjects: filtered,
        ),
      );
    }
  }

  Future<void> refresh(String userId, {String? token}) async {
    try {
      final allSubjects = await learningRepository.getAllSubjects(token: token);
      List<LearningSubject> userSubjects = const [];
      final previousUserSubjects = state is LearningLoaded
          ? (state as LearningLoaded).userSubjects
          : const <LearningSubject>[];
      try {
        userSubjects = await learningRepository.getUserSubjects(
          userId,
          token: token,
        );
      } catch (_) {
        userSubjects = previousUserSubjects;
      }

      User? profile;
      try {
        profile = await learningRepository.getProfile(userId, token: token);
      } catch (_) {
        profile = null;
      }
      userSubjects = _resolveUserSubjects(
        allSubjects,
        userSubjects,
        profile,
        fallback: previousUserSubjects,
      );

      final currentCategory = state is LearningLoaded
          ? (state as LearningLoaded).selectedCategory
          : 'All';

      final List<LearningSubject> filtered;
      if (currentCategory.toLowerCase() == 'all') {
        filtered = allSubjects;
      } else {
        filtered = allSubjects
            .where(
              (s) =>
                  s.title.toLowerCase() == currentCategory.toLowerCase() ||
                  s.slug.toLowerCase() == currentCategory.toLowerCase(),
            )
            .toList();
      }

      emit(
        LearningLoaded(
          allSubjects: allSubjects,
          userSubjects: userSubjects,
          filteredSubjects: filtered,
          selectedCategory: currentCategory,
          userProfile: profile,
        ),
      );
    } catch (e) {
      // Keep existing data if already loaded
      if (state is! LearningLoaded) {
        emit(
          LearningError(
            message: NetworkErrorUtils.message(
              e,
              fallback: 'Unable to refresh subjects.',
            ),
          ),
        );
      }
    }
  }

  List<LearningSubject> _resolveUserSubjects(
    List<LearningSubject> allSubjects,
    List<LearningSubject> apiSubjects,
    User? profile, {
    List<LearningSubject> fallback = const [],
  }) {
    final catalogueIds = allSubjects.map((subject) => subject.id).toSet();
    final userResponseIsCatalogue =
        apiSubjects.isNotEmpty &&
        apiSubjects.length == allSubjects.length &&
        apiSubjects.every((subject) => catalogueIds.contains(subject.id));

    // The deployed user endpoint returns only the subjects assigned to that
    // user (for example, the supplied userId currently returns Astrology).
    // Trust that subset directly; only use profile areasOfInterest to narrow
    // a response that appears to be the complete catalogue.
    if (apiSubjects.isNotEmpty && !userResponseIsCatalogue) {
      return apiSubjects;
    }

    final selectedIds = profile?.areasOfInterest ?? const <String>[];
    if (selectedIds.isNotEmpty) {
      final normalized = selectedIds.map((id) => id.toLowerCase()).toSet();
      final source = userResponseIsCatalogue ? allSubjects : apiSubjects;
      return source
          .where(
            (subject) =>
                normalized.contains(subject.id.toLowerCase()) ||
                normalized.contains(subject.slug.toLowerCase()) ||
                normalized.contains(subject.title.toLowerCase()),
          )
          .toList();
    }

    if (apiSubjects.isNotEmpty) return apiSubjects;

    return fallback;
  }
}
