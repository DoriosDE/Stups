import 'dart:io';

import 'version_from_tag.dart';

/// Gibt Name, Code und Flavor zu einem Git-Tag als `schlüssel=wert`-Zeilen aus,
/// passend für `$GITHUB_OUTPUT` und für Shell-Skripte.
///
/// Aufruf: `dart run tool/print_version.dart [tag]`. Ein leerer oder fehlender
/// Tag steht für einen lokalen Build ohne Tag.
void main(List<String> args) {
  final tag = args.isEmpty || args.first.isEmpty ? null : args.first;
  try {
    final version = versionFromTag(tag);
    stdout
      ..writeln('name=${version.name}')
      ..writeln('code=${version.code}')
      ..writeln('flavor=${version.flavor.name}');
  } on InvalidTagException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}
