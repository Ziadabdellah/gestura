import 'package:flutter/material.dart';
import 'package:gestura/app/view/app_destination.dart';
import 'package:gestura/app/view/app_navigation_scaffold.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) => AppNavigationScaffold(
    selected: AppDestination.values[navigationShell.currentIndex],
    onSelected: (destination) => _select(destination.index),
    body: navigationShell,
  );
}
