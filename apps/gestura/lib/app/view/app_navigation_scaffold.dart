import 'package:flutter/material.dart';
import 'package:gestura/app/view/app_destination.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class AppNavigationScaffold extends StatelessWidget {
  const new({
    required this.selected,
    required this.onSelected,
    required this.body,
    super.key,
  });

  final AppDestination selected;
  final ValueChanged<AppDestination> onSelected;
  final Widget body;

  void _onIndexSelected(int index) => onSelected(AppDestination.values[index]);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!context.windowSizeClass.usesNavigationRail) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected.index,
          onDestinationSelected: _onIndexSelected,
          destinations: [
            for (final destination in AppDestination.values)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label(l10n),
              ),
          ],
        ),
      );
    }

    final leftToRight = Directionality.of(context) == TextDirection.ltr;
    return Scaffold(
      body: Row(
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: SafeArea(
              left: leftToRight,
              right: !leftToRight,
              child: NavigationRail(
                selectedIndex: selected.index,
                onDestinationSelected: _onIndexSelected,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -1,
                destinations: [
                  for (final destination in AppDestination.values)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.label(l10n)),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: leftToRight,
              removeRight: !leftToRight,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
