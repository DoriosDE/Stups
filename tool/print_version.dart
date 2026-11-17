import 'dart:io';

import 'version_from_tag.dart';

/// Gibt Name, Code, Flavor, App-ID und App-Name zu einem Git-Tag als
/// `schlüssel=wert`-Zeilen aus, passend für `$GITHUB_OUTPUT` und für
/// Shell-Skripte.
///
/// Aufruf: `dart run tool/print_version.dart [tag]`. Ein leerer oder fehlender
/// Tag steht für einen lokalen Build ohne Tag.
void main(List<String> args) {
  exit(run(args, stdout, stderr));
}

/// Führt den Aufruf aus und liefert den Exit-Code. Ausgaben gehen an [out] und
/// [err], damit Tests ohne eigenen Prozess auskommen.
int run(List<String> args, StringSink out, StringSink err) {
  final tag = args.isEmpty || args.first.isEmpty ? null : args.first;
  try {
    final version = versionFromTag(tag);
    out
      ..writeln('name=${version.name}')
      ..writeln('code=${version.code}')
      ..writeln('flavor=${version.flavor.name}')
      ..writeln('app_id=${version.appId}')
      ..writeln('label=${version.label}');
    return 0;
  } on InvalidTagException catch (e) {
    err.writeln(e);
    return 64;
  }
}
