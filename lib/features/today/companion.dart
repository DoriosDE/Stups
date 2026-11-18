import 'package:material_ui/material_ui.dart';

/// Schlüssel, an dem Tests den Begleiter erkennen.
const companionKey = Key('companion');

/// Der Begleiter: das Staubwölkchen aus dem Prototyp (siehe docs/SPEC.md,
/// Abschnitt Design). Er ist reine Zierde und für Screenreader unsichtbar; der
/// Name steht im Text daneben.
class Companion extends StatelessWidget {
  const Companion({
    super.key,
    this.size = 56,
    this.color = const Color(0xFFE4DEFF),
    this.cheering = false,
  });

  final double size;

  /// Farbe des Körpers.
  final Color color;

  /// Jubelnd statt ruhig: geschlossene Augen, offener Mund, Funken.
  final bool cheering;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        key: companionKey,
        size: Size.square(size),
        painter: _CompanionPainter(color: color, cheering: cheering),
      ),
    );
  }
}

class _CompanionPainter extends CustomPainter {
  _CompanionPainter({required this.color, required this.cheering});

  final Color color;
  final bool cheering;

  static const _ink = Color(0xFF1F1A3D);
  static const _cheek = Color(0xB3FF8A7A);
  static const _spark = Color(0xFFFFC93C);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final body = Paint()..color = color;
    for (final (x, y, r) in const [
      (50.0, 56.0, 32.0),
      (27.0, 40.0, 14.0),
      (73.0, 40.0, 14.0),
      (50.0, 28.0, 15.0),
      (22.0, 63.0, 13.0),
      (78.0, 63.0, 13.0),
      (36.0, 82.0, 12.0),
      (64.0, 82.0, 12.0),
    ]) {
      canvas.drawCircle(Offset(x, y), r, body);
    }
    final cheeks = Paint()..color = _cheek;
    canvas.drawCircle(const Offset(31, 64), 5, cheeks);
    canvas.drawCircle(const Offset(69, 64), 5, cheeks);

    final ink = Paint()..color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.4;
    if (cheering) {
      canvas.drawPath(
        Path()
          ..moveTo(34, 55)
          ..quadraticBezierTo(40, 49, 46, 55)
          ..moveTo(54, 55)
          ..quadraticBezierTo(60, 49, 66, 55),
        line,
      );
      canvas.drawPath(
        Path()
          ..moveTo(40, 65)
          ..quadraticBezierTo(50, 77, 60, 65)
          ..close(),
        ink,
      );
      for (final (x, y, r) in const [
        (50.0, 9.0, 7.0),
        (14.0, 19.0, 5.0),
        (86.0, 19.0, 5.0),
      ]) {
        canvas.drawPath(_star(x, y, r), Paint()..color = _spark);
      }
    } else {
      canvas.drawCircle(const Offset(40, 54), 6, ink);
      canvas.drawCircle(const Offset(60, 54), 6, ink);
      final shine = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawCircle(const Offset(42, 52), 2, shine);
      canvas.drawCircle(const Offset(62, 52), 2, shine);
      canvas.drawPath(
        Path()
          ..moveTo(43, 66)
          ..quadraticBezierTo(50, 73, 57, 66),
        line..strokeWidth = 3,
      );
    }
  }

  /// Ein vierzackiger Funke um die Mitte ([x], [y]).
  Path _star(double x, double y, double r) {
    final inner = r * 0.3;
    return Path()
      ..moveTo(x, y - r)
      ..lineTo(x + inner, y - inner)
      ..lineTo(x + r, y)
      ..lineTo(x + inner, y + inner)
      ..lineTo(x, y + r)
      ..lineTo(x - inner, y + inner)
      ..lineTo(x - r, y)
      ..lineTo(x - inner, y - inner)
      ..close();
  }

  @override
  bool shouldRepaint(_CompanionPainter old) =>
      old.color != color || old.cheering != cheering;
}
