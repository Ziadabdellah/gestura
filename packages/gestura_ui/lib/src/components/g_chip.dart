import 'package:flutter/material.dart';

class GChip extends StatelessWidget {
  const new({
    required this.label,
    required this.onSelected,
    super.key,
    this.selected = false,
    this.icon,
    this.tooltip,
  });

  final String label;
  final ValueChanged<bool>? onSelected;
  final bool selected;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final data = icon;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      tooltip: tooltip,
      avatar: data == null || selected ? null : Icon(data),
    );
  }
}
