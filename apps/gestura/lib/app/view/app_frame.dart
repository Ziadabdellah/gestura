import 'package:flutter/material.dart';
import 'package:gestura/app/view/flavor_banner.dart';
import 'package:gestura/config/app_config.dart';

class AppFrame extends StatelessWidget {
  const new({
    required this.flavor,
    required this.reduceMotion,
    required this.child,
    super.key,
  });

  final Flavor flavor;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final framed = MediaQuery(
      data: mediaQuery.copyWith(
        disableAnimations: mediaQuery.disableAnimations || reduceMotion,
      ),
      child: child,
    );
    return switch (flavor) {
      Flavor.prod => framed,
      Flavor.dev ||
      Flavor.staging => FlavorBanner(flavor: flavor, child: framed),
    };
  }
}
