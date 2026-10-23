import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/tokens.dart';

/// A bottom navigation bar over the branches of a [StatefulNavigationShell].
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
  });

  final StatefulNavigationShell navigationShell;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: NiscalaColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          destinations: destinations,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
