import 'package:flutter/foundation.dart';

enum Flavor {
  dev,
  staging,
  prod;

  factory fromName(String? name) => values.firstWhere(
    (flavor) => flavor.name == name,
    orElse: () => Flavor.dev,
  );
}

@immutable
final class AppConfig {
  const new({required this.flavor});

  final Flavor flavor;

  bool get isProd => flavor == Flavor.prod;

  Uri get contentBase => Uri.https(
    isProd ? 'gestura-prod-content.web.app' : 'gestura-dev-content.web.app',
    '/content/',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppConfig && other.flavor == flavor;

  @override
  int get hashCode => flavor.hashCode;
}
