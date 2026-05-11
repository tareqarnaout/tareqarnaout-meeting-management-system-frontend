import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'constants/app_theme.dart';
import 'constants/api_constants.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_meeting_screen.dart';
import 'screens/review_sign_screen.dart';
import 'models/meeting.dart';
import 'screens/meeting_sign_detail_screen.dart';
import 'screens/decision_graph_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/minute_taker_screen.dart';
import 'screens/secretary_inbox_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

void main() {
  ApiService.onSessionExpired = () {
    AuthService.clearCaches();
    _router.go('/login');
  };
  runApp(const MyApp());
}

/// Returns a [CustomTransitionPage] that fades in from 8px below on enter
/// and fades out to 8px above on exit — matching Framer Motion's
/// `initial={{ opacity: 0, y: 8 }}` / `exit={{ opacity: 0, y: -8 }}`.
CustomTransitionPage<void> _fadeSlide({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
      );

      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (BuildContext ctx, Widget? child) {
            // Enter: +8px → 0  (slides upward into view)
            // Exit:   0 → -8px (continues upward out of view)
            final bool exiting =
                animation.status == AnimationStatus.reverse ||
                animation.status == AnimationStatus.dismissed;
            final double dy = exiting
                ? -(1.0 - curved.value) * 8.0
                : (1.0 - curved.value) * 8.0;
            return Transform.translate(
              offset: Offset(0, dy),
              child: child,
            );
          },
        ),
      );
    },
  );
}

final AuthService _authService = AuthService();

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) async {
    final bool loggedIn = await _authService.isAuthenticated();
    final bool goingToLogin = state.matchedLocation == '/login';

    final bool goingToRegister = state.matchedLocation == '/register';
    if (!loggedIn && !goingToLogin && !goingToRegister) return '/login';
    if (loggedIn && (goingToLogin || goingToRegister)) return '/';

    if (loggedIn) {
      final int? roleId = await _authService.getRoleId();
      final String location = state.matchedLocation;
      final bool isAdminRoute = location == '/users';
      final bool isMinuteRoute = location == '/minute';

      if (isAdminRoute && roleId != UserRole.admin) return '/';
      if (isMinuteRoute &&
          roleId != UserRole.minuteTaker &&
          roleId != UserRole.admin) {
        return '/';
      }

      final bool isSecretaryRoute = location == '/secretary';
      if (isSecretaryRoute &&
          roleId != UserRole.secretary &&
          roleId != UserRole.admin) {
        return '/';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _fadeSlide(state: state, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _fadeSlide(state: state, child: const RegisterScreen()),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ShellScreen(
          currentRoute: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              _fadeSlide(state: state, child: const DashboardScreen()),
        ),
        GoRoute(
          path: '/create',
          pageBuilder: (BuildContext context, GoRouterState state) {
            final Meeting? editMeeting = state.extra as Meeting?;
            return _fadeSlide(
              state: state,
              child: CreateMeetingScreen(editMeeting: editMeeting),
            );
          },
        ),
        GoRoute(
          path: '/review',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              _fadeSlide(state: state, child: const ReviewSignScreen()),
        ),
        GoRoute(
          path: '/review/:id',
          pageBuilder: (BuildContext context, GoRouterState state) {
            final int meetingId =
                int.parse(state.pathParameters['id']!);
            final Meeting? meeting = state.extra as Meeting?;
            return _fadeSlide(
              state: state,
              child: MeetingSignDetailScreen(meetingId: meetingId, meeting: meeting),
            );
          },
        ),
        GoRoute(
          path: '/graph',
          pageBuilder: (BuildContext context, GoRouterState state) {
            final String? meetingParam =
                state.uri.queryParameters['meeting'];
            final int? meetingId =
                meetingParam != null ? int.tryParse(meetingParam) : null;
            return _fadeSlide(
              state: state,
              child: DecisionGraphScreen(meetingId: meetingId),
            );
          },
        ),
        GoRoute(
          path: '/archive',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              _fadeSlide(state: state, child: const ArchiveScreen()),
        ),
        GoRoute(
          path: '/users',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              _fadeSlide(state: state, child: const UserManagementScreen()),
        ),
        GoRoute(
          path: '/minute',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              _fadeSlide(state: state, child: const MinuteTakerScreen()),
        ),
        GoRoute(
          path: '/secretary',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              _fadeSlide(
                  state: state,
                  child: const SecretaryInboxScreen()),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Post-Meeting Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryTeal,
          brightness: Brightness.light,
        ),
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: AppColors.pageBg,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
