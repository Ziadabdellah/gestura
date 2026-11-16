import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';

class GAvatar extends StatelessWidget {
  const new({required this.name, super.key, this.image, this.size = 40});

  final String name;
  final ImageProvider? image;
  final double size;

  static const List<(Color, Color)> _palette = [
    (Color(0xFFCDE8E5), Color(0xFF0B4F4A)),
    (Color(0xFFFFDBCF), Color(0xFF7A2E16)),
    (Color(0xFFE3DFFF), Color(0xFF332A7A)),
    (Color(0xFFFFE7B0), Color(0xFF3D2800)),
    (Color(0xFFD4F3DF), Color(0xFF0A3A1F)),
  ];

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p.characters.first.toUpperCase());
    return letters.join();
  }

  @override
  Widget build(BuildContext context) {
    final side = context.gSizes.scaled(size);
    final (background, foreground) =
        _palette[name.hashCode.abs() % _palette.length];
    final picture = image;

    return Semantics(
      image: true,
      label: name,
      child: ExcludeSemantics(
        child: CircleAvatar(
          radius: side / 2,
          backgroundColor: background,
          foregroundImage: picture,
          child: Text(
            initialsOf(name),
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: side * 0.38,
            ),
          ),
        ),
      ),
    );
  }
}
