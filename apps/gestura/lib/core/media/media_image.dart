import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/sign.dart';

class MediaImage extends StatelessWidget {
  const new({
    required this.media,
    super.key,
    this.width,
    this.height,
    this.cacheWidth,
    this.fit = BoxFit.cover,
  });

  final MediaRef media;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final BoxFit fit;

  Widget _fallback(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: SizedBox(width: width, height: height),
  );

  @override
  Widget build(BuildContext context) => switch (media) {
    AssetMedia(:final path) => Image.asset(
      path,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      fit: fit,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    ),
    RemoteMedia(:final uri) => _RemoteImage(
      uri: uri,
      builder: (context, file) => switch (file) {
        final File file => Image.file(
          file,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          fit: fit,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => _fallback(context),
        ),
        null => _fallback(context),
      },
    ),
  };
}

class _RemoteImage extends StatefulWidget {
  const new({required this.uri, required this.builder});

  final Uri uri;
  final Widget Function(BuildContext context, File? file) builder;

  @override
  State<_RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<_RemoteImage> {
  late Future<File> _file = getIt<MediaCache>().file(widget.uri);

  @override
  void didUpdateWidget(_RemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _file = getIt<MediaCache>().file(widget.uri);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File>(
    future: _file,
    builder: (context, snapshot) => widget.builder(context, snapshot.data),
  );
}
