import 'package:flutter/material.dart';
import 'package:gestura/core/media/media_image.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/features/content/presentation/sign_hero.dart';
import 'package:gestura_ui/gestura_ui.dart';

class SignTile extends StatelessWidget {
  const new({required this.sign, required this.onTap, super.key});

  static const Size thumbnailSize = Size(48, 60);

  final Sign sign;
  final VoidCallback onTap;

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
      onTap: onTap,
      leading: SignHero(
        signId: sign.id,
        thumbnail: sign.media.thumbnail,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(sizes.radiusSm),
          child: MediaImage(
            media: sign.media.thumbnail,
            width: width,
            height: height,
            cacheWidth: (width * pixelRatio).round(),
          ),
        ),
      ),
      title: Text(sign.gloss),
      subtitle: Text(sign.meaning.of(context)),
      trailing: const ExcludeSemantics(child: Icon(Icons.chevron_right)),
    );
  }
}
