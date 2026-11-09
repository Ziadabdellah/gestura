import 'package:flutter/material.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura_ui/gestura_ui.dart';

class SignTile extends StatelessWidget {
  const new({required this.sign, super.key});

  static const Size thumbnailSize = Size(48, 60);

  final Sign sign;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    final width = sizes.scaled(thumbnailSize.width);
    final height = sizes.scaled(thumbnailSize.height);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return ListTile(
      contentPadding: EdgeInsetsDirectional.symmetric(
        horizontal: context.windowSizeClass.screenPadding,
        vertical: sizes.xxs,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(sizes.radiusSm),
        child: Image.asset(
          sign.media.thumbnailAsset,
          width: width,
          height: height,
          cacheWidth: (width * pixelRatio).round(),
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: SizedBox(width: width, height: height),
          ),
        ),
      ),
      title: Text(sign.gloss),
      subtitle: Text(sign.meaning.of(context)),
    );
  }
}
