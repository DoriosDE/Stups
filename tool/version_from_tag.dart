enum BuildFlavor { dev, prod }

class BuildVersion {
  const BuildVersion({
    required this.name,
    required this.code,
    required this.flavor,
  });

  final String name;
  final int code;
  final BuildFlavor flavor;

  /// App-ID der Variante. Muss zu `android/app/build.gradle.kts` passen; die
  /// CI prüft das an der gebauten APK.
  String get appId => switch (flavor) {
    BuildFlavor.prod => 'de.dorios.stups',
    BuildFlavor.dev => 'de.dorios.stups.dev',
  };

  /// Name, den Android unter dem Icon anzeigt.
  String get label => switch (flavor) {
    BuildFlavor.prod => 'Stups',
    BuildFlavor.dev => 'Stups Dev',
  };
}

class InvalidTagException implements Exception {
  const InvalidTagException(this.tag);

  final String tag;

  @override
  String toString() =>
      'Ungültiger Tag "$tag". Erwartet: v<Major>.<Minor>.<Patch> '
      'oder v<Major>.<Minor>.<Patch>-dev, ohne führende Nullen.';
}

/// Minor und Patch haben je drei Stellen im versionCode. Android erlaubt
/// höchstens 2.100.000.000, daher ist Major bis 2099 möglich.
const _maxMinorOrPatch = 999;
const _maxMajor = 2099;
const _majorWeight = 1000000;
const _minorWeight = 1000;

final _tagPattern = RegExp(
  r'^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-dev)?$',
);

/// Berechnet Name, Code und Flavor aus einem Git-Tag. Ohne Tag (`null`, lokaler
/// Build) entsteht eine erkennbare Entwicklungsversion.
BuildVersion versionFromTag(String? tag) {
  if (tag == null) {
    return const BuildVersion(
      name: '0.0.0-lokal',
      code: 1,
      flavor: BuildFlavor.dev,
    );
  }
  final match = _tagPattern.firstMatch(tag);
  if (match == null) throw InvalidTagException(tag);
  final major = int.parse(match[1]!);
  final minor = int.parse(match[2]!);
  final patch = int.parse(match[3]!);
  if (major > _maxMajor ||
      minor > _maxMinorOrPatch ||
      patch > _maxMinorOrPatch) {
    throw InvalidTagException(tag);
  }
  return BuildVersion(
    name: tag.substring(1),
    code: major * _majorWeight + minor * _minorWeight + patch,
    flavor: match[4] == null ? BuildFlavor.prod : BuildFlavor.dev,
  );
}
