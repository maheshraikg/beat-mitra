/// Recorded walking routes ("tracks"): pure helpers for length, following a
/// saved route, Google Maps links and GPX export. No Flutter imports, so it is
/// unit-tested directly.
library;

import 'dart:math' as math;

import 'geo.dart';

class TrackPoint {
  const TrackPoint(this.lat, this.lng, {this.accuracyM = 0, this.time = 0});
  final double lat;
  final double lng;
  final double accuracyM;

  /// Milliseconds since epoch.
  final int time;

  GeoPoint get point => GeoPoint(lat, lng);
}

/// Total length in metres.
double trackLength(List<TrackPoint> pts) {
  var d = 0.0;
  for (var i = 1; i < pts.length; i++) {
    d += haversineMeters(pts[i - 1].point, pts[i].point);
  }
  return d;
}

/// Cumulative distance from the first point to each point.
List<double> cumulativeDistances(List<TrackPoint> pts) {
  final out = List<double>.filled(pts.length, 0);
  for (var i = 1; i < pts.length; i++) {
    out[i] = out[i - 1] + haversineMeters(pts[i - 1].point, pts[i].point);
  }
  return out;
}

/// Decides whether a new GPS fix is worth storing: accurate enough and far
/// enough from the last stored point (keeps files small, removes GPS jitter).
bool shouldRecord(TrackPoint? last, TrackPoint next, {double maxAccuracyM = 35, double minStepM = 8}) {
  if (next.accuracyM > maxAccuracyM) return false;
  if (last == null) return true;
  return haversineMeters(last.point, next.point) >= math.max(minStepM, next.accuracyM * 0.5);
}

/// Index of the track point closest to [here]. When [fromIndex] is given,
/// only points from there on are considered (so a route that crosses itself
/// is followed in order).
int nearestIndex(List<TrackPoint> pts, GeoPoint here, {int fromIndex = 0, int window = 1 << 30}) {
  var best = math.min(math.max(0, fromIndex), math.max(0, pts.length - 1));
  var bestD = double.infinity;
  final end = math.min(pts.length, fromIndex + window);
  for (var i = fromIndex; i < end; i++) {
    final d = haversineMeters(here, pts[i].point);
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

class FollowState {
  FollowState({
    required this.nearest,
    required this.target,
    required this.offRouteM,
    required this.remainingM,
    required this.done,
  });

  /// Index of the closest point on the route.
  final int nearest;

  /// Index of the point to walk towards (a little ahead on the route).
  final int target;

  /// Distance from you to the route line (nearest point).
  final double offRouteM;

  /// Distance left along the route from the nearest point to the end.
  final double remainingM;
  final bool done;
}

/// Where to walk next when following [pts] (already in walking order; reverse
/// the list to walk a route backwards). [progress] is the last known nearest
/// index, so the follower does not jump back to an earlier part of the route.
FollowState follow(
  List<TrackPoint> pts,
  GeoPoint here, {
  int progress = 0,
  double lookAheadM = 25,
  double arriveM = 20,
}) {
  if (pts.isEmpty) return FollowState(nearest: 0, target: 0, offRouteM: 0, remainingM: 0, done: true);
  // Search forward from the current progress (and a few points back for
  // GPS noise); fall back to a full search if we are far from that part.
  final from = math.max(0, progress - 3);
  var n = nearestIndex(pts, here, fromIndex: from, window: 200);
  if (haversineMeters(here, pts[n].point) > 80) n = nearestIndex(pts, here);
  final cum = cumulativeDistances(pts);
  final remaining = cum.last - cum[n];
  var t = n;
  while (t < pts.length - 1 && cum[t] - cum[n] < lookAheadM) {
    t++;
  }
  final off = haversineMeters(here, pts[n].point);
  final done = haversineMeters(here, pts.last.point) <= arriveM;
  return FollowState(nearest: n, target: t, offRouteM: off, remainingM: remaining, done: done);
}

/// Picks at most [max] points evenly spaced along the route, excluding the
/// ends (used as Google Maps waypoints).
List<TrackPoint> sampleWaypoints(List<TrackPoint> pts, {int max = 8}) {
  if (pts.length <= 2 || max <= 0) return const [];
  final cum = cumulativeDistances(pts);
  final total = cum.last;
  if (total <= 0) return const [];
  final out = <TrackPoint>[];
  var j = 1;
  for (var k = 1; k <= max; k++) {
    final want = total * k / (max + 1);
    while (j < pts.length - 1 && cum[j] < want) {
      j++;
    }
    if (j >= pts.length - 1) break;
    if (out.isEmpty || !identical(out.last, pts[j])) out.add(pts[j]);
  }
  return out;
}

String _ll(GeoPoint p) => '${p.lat.toStringAsFixed(6)},${p.lng.toStringAsFixed(6)}';

/// Free Google Maps directions link (opens the Google Maps app; no API key).
String googleMapsDirectionsUrl({
  GeoPoint? origin,
  required GeoPoint destination,
  List<GeoPoint> waypoints = const [],
  String mode = 'walking',
}) {
  final q = <String>[
    'api=1',
    if (origin != null) 'origin=${_ll(origin)}',
    'destination=${_ll(destination)}',
    if (waypoints.isNotEmpty) 'waypoints=${Uri.encodeComponent(waypoints.map(_ll).join('|'))}',
    'travelmode=$mode',
  ];
  return 'https://www.google.com/maps/dir/?${q.join('&')}';
}

/// Google Maps link that walks a saved route (start → sampled points → end).
String googleMapsRouteUrl(List<TrackPoint> pts, {bool reverse = false}) {
  final p = reverse ? pts.reversed.toList() : pts;
  return googleMapsDirectionsUrl(
    origin: p.first.point,
    destination: p.last.point,
    waypoints: sampleWaypoints(p).map((e) => e.point).toList(),
  );
}

String _xml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

/// GPX 1.1 file (opens in OsmAnd, Organic Maps, Google Earth, …).
String toGpx(String name, List<TrackPoint> pts) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<gpx version="1.1" creator="Beat Mitra" xmlns="http://www.topografix.com/GPX/1/1">')
    ..writeln('  <trk><name>${_xml(name)}</name><trkseg>');
  for (final p in pts) {
    b.write('    <trkpt lat="${p.lat.toStringAsFixed(7)}" lon="${p.lng.toStringAsFixed(7)}">');
    if (p.time > 0) {
      b.write('<time>${DateTime.fromMillisecondsSinceEpoch(p.time, isUtc: true).toIso8601String()}</time>');
    }
    b.writeln('</trkpt>');
  }
  b
    ..writeln('  </trkseg></trk>')
    ..writeln('</gpx>');
  return b.toString();
}

/// Simple local projection (metres east / north of [origin]) for drawing.
({double x, double y}) projectMeters(GeoPoint origin, GeoPoint p) {
  const r = 6371000.0;
  final x = (p.lng - origin.lng) * math.pi / 180 * r * math.cos(origin.lat * math.pi / 180);
  final y = (p.lat - origin.lat) * math.pi / 180 * r;
  return (x: x, y: y);
}
