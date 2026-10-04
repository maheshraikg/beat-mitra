import 'package:beat_mitra/core/geo.dart';
import 'package:beat_mitra/core/track.dart';
import 'package:flutter_test/flutter_test.dart';

/// Straight walk north: one point every ~11 m (0.0001°).
List<TrackPoint> line(int n, {double lat0 = 12.97, double lng = 77.64}) => [
  for (var i = 0; i < n; i++) TrackPoint(lat0 + i * 0.0001, lng, accuracyM: 5, time: i * 10000),
];

void main() {
  test('length and cumulative distance', () {
    final pts = line(11);
    expect(trackLength(pts), closeTo(111.2, 1));
    expect(cumulativeDistances(pts).last, closeTo(trackLength(pts), 1e-6));
    expect(trackLength(const []), 0);
  });

  test('shouldRecord filters jitter and bad accuracy', () {
    const a = TrackPoint(12.97, 77.64, accuracyM: 5);
    expect(shouldRecord(null, a), isTrue);
    expect(shouldRecord(a, const TrackPoint(12.97002, 77.64, accuracyM: 5)), isFalse); // ~2 m
    expect(shouldRecord(a, const TrackPoint(12.9701, 77.64, accuracyM: 5)), isTrue); // ~11 m
    expect(shouldRecord(a, const TrackPoint(12.9705, 77.64, accuracyM: 80)), isFalse); // poor fix
  });

  test('follow: target is ahead on the line, remaining shrinks, arrival', () {
    final pts = line(21); // ~222 m
    final s0 = follow(pts, const GeoPoint(12.97, 77.64001));
    expect(s0.nearest, 0);
    expect(s0.target, greaterThan(0));
    expect(s0.remainingM, closeTo(222, 3));
    expect(s0.done, isFalse);
    final s1 = follow(pts, const GeoPoint(12.9710, 77.64), progress: s0.nearest);
    expect(s1.nearest, 10);
    expect(s1.remainingM, closeTo(111, 3));
    final end = follow(pts, const GeoPoint(12.9720, 77.64), progress: 10);
    expect(end.done, isTrue);
  });

  test('follow reports off-route distance', () {
    final pts = line(11);
    final s = follow(pts, const GeoPoint(12.9705, 77.6410)); // ~108 m east
    expect(s.offRouteM, greaterThan(90));
  });

  test('following backwards = reversed list ends at the original start', () {
    final pts = line(11).reversed.toList();
    final s = follow(pts, const GeoPoint(12.97, 77.64));
    expect(s.done, isTrue);
  });

  test('follow keeps progress on a route that comes back the same way', () {
    // Out 10 points and back 10 points on the same street.
    final out = line(11);
    final pts = [...out, ...out.reversed.skip(1)];
    // Standing at point 5 after having walked to the far end (progress 12).
    final s = follow(pts, out[5].point, progress: 12);
    expect(s.nearest, greaterThan(10)); // matched on the way back, not the way out
  });

  test('Google Maps waypoints: at most 8, evenly spaced, URL format', () {
    final pts = line(200);
    final w = sampleWaypoints(pts);
    expect(w.length, lessThanOrEqualTo(8));
    expect(w.length, greaterThan(5));
    final url = googleMapsRouteUrl(pts);
    expect(url, startsWith('https://www.google.com/maps/dir/?api=1&origin=12.970000,77.640000'));
    expect(url, contains('destination=12.989900,77.640000'));
    expect(url, contains('waypoints='));
    expect(url, contains('travelmode=walking'));
    final back = googleMapsRouteUrl(pts, reverse: true);
    expect(back, contains('destination=12.970000,77.640000'));
    expect(sampleWaypoints(line(2)), isEmpty);
  });

  test('GPX export', () {
    final gpx = toGpx('Beat 7 <run>', line(3));
    expect(gpx, contains('<gpx version="1.1"'));
    expect(gpx, contains('<name>Beat 7 &lt;run&gt;</name>'));
    expect('<trkpt'.allMatches(gpx).length, 3);
  });

  test('projection', () {
    final m = projectMeters(const GeoPoint(12.97, 77.64), const GeoPoint(12.9709, 77.64));
    expect(m.y, closeTo(100, 1));
    expect(m.x, closeTo(0, 0.01));
  });
}
