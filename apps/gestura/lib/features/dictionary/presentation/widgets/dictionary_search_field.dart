import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';

class DictionarySearchField extends StatelessWidget {
  const new({
    required this.controller,
    required this.onChanged,
    required this.onCleared,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: l10n.searchSignsHint,
          prefixIcon: const ExcludeSemantics(child: Icon(Icons.search_rounded)),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.clearSearch,
                  onPressed: onCleared,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}
