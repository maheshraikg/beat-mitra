import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/geo.dart';
import '../../core/track.dart';

/// Draws a recorded route offline (no map tiles): the path, start (green),
/// end (red), optional current position (blue) and follow target.
class TrackView extends StatelessWidget {
  const TrackView({
    super.key,
    required this.points,
    this.here,
    this.target,
    this.progress,
    this.height = 260,
    this.places = const [],
  });
  final List<TrackPoint> points;
  final GeoPoint? here;
  final GeoPoint? target;

  /// Index up to which the route is already walked (drawn greyed).
  final int? progress;
  final double height;
  final List<GeoPoint> places;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Route drawing',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            size: Size.infinite,
            painter: _TrackPainter(points, here, target, progress, places, scheme),
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.points, this.here, this.target, this.progress, this.places, this.scheme);
  final List<TrackPoint> points;
  final GeoPoint? here;
  final GeoPoint? target;
  final int? progress;
  final List<GeoPoint> places;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final origin = points.first.point;
    final all = [...points.map((p) => p.point), ?here];
    final xy = all.map((p) => projectMeters(origin, p)).toList();
    var minX = xy.map((e) => e.x).reduce(math.min), maxX = xy.map((e) => e.x).reduce(math.max);
    var minY = xy.map((e) => e.y).reduce(math.min), maxY = xy.map((e) => e.y).reduce(math.max);
    // At least 60 m across so a short route is not blown up.
    final span = math.max(60.0, math.max(maxX - minX, maxY - minY));
    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    const pad = 24.0;
    final scale = (math.min(size.width, size.height) - 2 * pad) / span;
    Offset toScreen(GeoPoint p) {
      final m = projectMeters(origin, p);
      return Offset(size.width / 2 + (m.x - cx) * scale, size.height / 2 - (m.y - cy) * scale);
    }

    // Scale bar.
    final bar = _niceLength(span / 4);
    final barPx = bar * scale;
    final barPaint = Paint()
      ..color = scheme.onSurfaceVariant
      ..strokeWidth = 2;
    final by = size.height - 12;
    canvas.drawLine(Offset(12, by), Offset(12 + barPx, by), barPaint);
    _text(canvas, formatDistance(bar), Offset(14, by - 18), scheme.onSurfaceVariant, 12);
    _text(canvas, 'N ↑', Offset(size.width - 34, 6), scheme.onSurfaceVariant, 13);

    for (final p in places) {
      canvas.drawCircle(toScreen(p), 4, Paint()..color = scheme.tertiary.withValues(alpha: 0.7));
    }

    final path = Path()..moveTo(toScreen(points.first.point).dx, toScreen(points.first.point).dy);
    for (final p in points.skip(1)) {
      final o = toScreen(p.point);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = scheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (progress != null && progress! > 0) {
      final done = Path()..moveTo(toScreen(points.first.point).dx, toScreen(points.first.point).dy);
      for (final p in points.take(progress! + 1).skip(1)) {
        final o = toScreen(p.point);
        done.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        done,
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    void dot(GeoPoint p, Color c, double r) {
      final o = toScreen(p);
      canvas.drawCircle(o, r + 2, Paint()..color = Colors.white);
      canvas.drawCircle(o, r, Paint()..color = c);
    }

    dot(points.first.point, Colors.green.shade700, 8);
    dot(points.last.point, Colors.red.shade700, 8);
    if (target != null) dot(target!, scheme.secondary, 6);
    if (here != null) dot(here!, Colors.blue.shade700, 9);
  }

  double _niceLength(double m) {
    for (final v in [10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000]) {
      if (v >= m) return v.toDouble();
    }
    return 20000;
  }

  void _text(Canvas c, String s, Offset at, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.points != points || old.here != here || old.target != target || old.progress != progress;
}
