import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:meta/meta.dart';

@immutable
final class SignMedia {
  const new({
    required this.videoAsset,
    required this.thumbnailAsset,
    required this.duration,
  });

  final String videoAsset;
  final String thumbnailAsset;
  final Duration duration;
}

@immutable
final class ContentSource {
  const new({required this.name, required this.license, this.url});

  static const String placeholderLicense = 'placeholder';

  final String name;
  final String license;
  final Uri? url;

  bool get isPlaceholder => license == placeholderLicense;
}

@immutable
final class SignCategory {
  const new({required this.id, required this.name});

  final CategoryId id;
  final LocalizedText name;
}

@immutable
final class Sign {
  const new({
    required this.id,
    required this.gloss,
    required this.meaning,
    required this.category,
    required this.media,
    required this.source,
  });

  final SignId id;
  final String gloss;
  final LocalizedText meaning;
  final CategoryId category;
  final SignMedia media;
  final ContentSource source;

  bool get isPlaceholder => source.isPlaceholder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Sign && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
