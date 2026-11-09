import 'package:flutter/material.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura_ui/gestura_ui.dart';

class FlavorBanner extends StatelessWidget {
  const new({required this.flavor, required this.child, super.key});

  final Flavor flavor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Banner(
    message: flavor.name.toUpperCase(),
    location: BannerLocation.topEnd,
    color: context.gColors.coralStrong,
    child: child,
  );
}
