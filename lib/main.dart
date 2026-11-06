import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_toast.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/learning_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/learning_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/dashboard/presentation/cubit/courses_cubit.dart';
import 'features/dashboard/presentation/cubit/dashboard_nav_cubit.dart';
import 'features/dashboard/presentation/cubit/learning_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AstroSiriApp());
}

class AstroSiriApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const AstroSiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        RepositoryProvider<LearningRepository>(
          create: (_) => LearningRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) =>
                AuthCubit(authRepository: context.read<AuthRepository>())
                  ..checkCurrentUser(),
          ),
          BlocProvider<LearningCubit>(
            create: (context) => LearningCubit(
              learningRepository: context.read<LearningRepository>(),
            ),
          ),
          BlocProvider<CoursesCubit>(
            create: (context) => CoursesCubit(
              learningRepository: context.read<LearningRepository>(),
            ),
          ),
          BlocProvider<DashboardNavCubit>(create: (_) => DashboardNavCubit()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            return BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is Unauthenticated &&
                    state.message != null &&
                    state.message!.isNotEmpty) {
                  final targetContext = navigatorKey.currentContext ?? context;
                  AppToast.error(
                    targetContext,
                    state.message!,
                    title: 'Session Expired',
                  );
                  navigatorKey.currentState?.pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
