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

  @override
  Widget build(BuildContext context) {
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
