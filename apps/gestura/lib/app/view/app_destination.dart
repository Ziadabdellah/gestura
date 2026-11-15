import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';

enum AppDestination {
  today(icon: Icons.today_outlined, selectedIcon: Icons.today_rounded),
  learn(icon: Icons.school_outlined, selectedIcon: Icons.school_rounded),
  dictionary(
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
  ),
  profile(
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  );

  new({required this.icon, required this.selectedIcon});

  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    today => l10n.tabToday,
    learn => l10n.tabLearn,
    dictionary => l10n.tabDictionary,
    profile => l10n.tabProfile,
  };
}
