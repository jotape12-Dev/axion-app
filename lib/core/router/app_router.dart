import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:axion/features/splash/presentation/splash_screen.dart';
import 'package:axion/features/onboarding/presentation/onboarding_screen.dart';
import 'package:axion/features/home/presentation/home_screen.dart';
import 'package:axion/features/history/presentation/history_screen.dart';
import 'package:axion/features/profile/presentation/profile_screen.dart';
import 'package:axion/features/profile_setup/presentation/profile_setup_screen.dart';
import 'package:axion/features/interview/presentation/setup_screen.dart';
import 'package:axion/features/interview/presentation/pre_interview_screen.dart';
import 'package:axion/features/interview/presentation/interview_screen.dart';
import 'package:axion/features/interview/presentation/interview_ended_screen.dart';
import 'package:axion/features/interview/presentation/completion_screen.dart';
import 'package:axion/features/report/presentation/report_screen.dart';
import 'package:axion/features/profile/providers/profile_providers.dart';

/// Makes GoRouter reactive to [userProfileProvider] changes.
/// When the profile state changes, the router re-evaluates its redirect.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(userProfileProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final profile = ref.read(userProfileProvider);
      final location = state.matchedLocation;

      // Profile still loading (null) → allow freely; splash controls initial flow.
      if (profile == null) return null;

      // Onboarding not completed → must go to profile-setup.
      if (!profile.onboardingCompleted) {
        if (location == '/profile-setup') return null;
        return '/profile-setup';
      }

      // Onboarding done but still on profile-setup or splash → go to home.
      if (location == '/profile-setup' || location == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Interview Flow (Direct nav, no TabBar)
      GoRoute(
        path: '/setup',
        builder: (context, state) => const InterviewSetupScreen(),
      ),
      GoRoute(
        path: '/pre-interview',
        builder: (context, state) => const PreInterviewScreen(),
      ),
      GoRoute(
        path: '/interview',
        builder: (context, state) => const InterviewScreen(),
      ),
      GoRoute(
        path: '/interview-ended',
        builder: (context, state) => const InterviewEndedScreen(),
      ),
      GoRoute(
        path: '/completion/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CompletionScreen(interviewId: id);
        },
      ),
      GoRoute(
        path: '/report/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReportScreen(interviewId: id);
        },
      ),
    ],
  );
});
