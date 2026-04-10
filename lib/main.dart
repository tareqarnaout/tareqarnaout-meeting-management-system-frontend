import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'constants/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_meeting_screen.dart';
import 'screens/review_sign_screen.dart';
import 'screens/decision_graph_screen.dart';
import 'screens/archive_screen.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginScreen(),
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
          builder: (BuildContext context, GoRouterState state) =>
              const DashboardScreen(),
        ),
        GoRoute(
          path: '/create',
          builder: (BuildContext context, GoRouterState state) =>
              const CreateMeetingScreen(),
        ),
        GoRoute(
          path: '/review',
          builder: (BuildContext context, GoRouterState state) =>
              const ReviewSignScreen(),
        ),
        GoRoute(
          path: '/graph',
          builder: (BuildContext context, GoRouterState state) {
            final String? meeting = state.uri.queryParameters['meeting'];
            return DecisionGraphScreen(focusMeeting: meeting);
          },
        ),
        GoRoute(
          path: '/archive',
          builder: (BuildContext context, GoRouterState state) =>
              const ArchiveScreen(),
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
