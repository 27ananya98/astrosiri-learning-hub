import 'package:flutter/material.dart';
import '../../domain/models/learning_subject.dart';
import '../../domain/models/user.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/subject_courses_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String profileSetup = '/profile-setup';
  static const String dashboard = '/dashboard';
  static const String courses = '/courses';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case otpVerification:
        final contact = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(contact: contact),
        );
      case profileSetup:
        final user =
            settings.arguments as User? ?? const User(id: '', fullName: '');
        return MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(user: user),
        );
      case dashboard:
        final user = settings.arguments as User?;
        return MaterialPageRoute(builder: (_) => DashboardScreen(user: user));
      case courses:
        final subject = settings.arguments as LearningSubject;
        return MaterialPageRoute(
          builder: (_) => SubjectCoursesScreen(subject: subject),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
  };
}
