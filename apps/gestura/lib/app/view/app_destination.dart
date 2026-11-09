import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';

enum AppDestination {
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
    learn => l10n.tabLearn,
    dictionary => l10n.tabDictionary,
    profile => l10n.tabProfile,
  };
}
