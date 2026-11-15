import 'package:flutter/material.dart';
import 'package:gestura/core/media/media_image.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';

class SignHero extends StatelessWidget {
  const new({
    required this.signId,
    required this.child,
    super.key,
    this.thumbnail,
  });

  final SignId signId;
  final Widget child;
  final MediaRef? thumbnail;

  static String tagOf(SignId id) => 'sign-media-${id.value}';

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final thumbnail = this.thumbnail;
    return Hero(
      tag: tagOf(signId),
      flightShuttleBuilder: thumbnail == null
          ? null
          : (context, animation, direction, from, to) =>
                MediaImage(media: thumbnail),
      child: child,
    );
  }
}
