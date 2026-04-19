import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';

class ShellScreen extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const ShellScreen({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  static const double _mobileBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < _mobileBreakpoint;

    if (isMobile) {
      return Scaffold(
        drawer: Sidebar(currentRoute: currentRoute),
        body: SafeArea(
          child: Column(
            children: [
              const AppHeader(showMenuButton: true),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                const AppHeader(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
