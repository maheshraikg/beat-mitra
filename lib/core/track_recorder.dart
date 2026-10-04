import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repos/track_repo.dart';
import 'services/location_service.dart';
import 'track.dart';

/// Records the postman's walk while switched on (also with the screen off,
/// via a foreground-service notification). Every accepted point is written to
/// the encrypted database at once, so nothing is lost if the phone restarts.
class TrackRecorder extends ChangeNotifier {
  TrackRecorder(this._repo, this._location);

  final TrackRepo _repo;
  final LocationService _location;

  StreamSubscription<GpsFix>? _sub;
  int? _trackId;
  TrackPoint? _last;
  int _seq = 0;
  double _distance = 0;
  TrackPoint? _first;
  double? _gpsAccuracyM;

  /// Accuracy of the latest GPS fix (accepted or not); null until the first
  /// fix arrives. Shown so the user knows whether GPS is good enough.
  double? get gpsAccuracyM => _gpsAccuracyM;

  bool get recording => _trackId != null;
  int? get trackId => _trackId;
  double get distanceM => _distance;
  int get pointCount => _seq;
  TrackPoint? get firstPoint => _first;

  /// Closes a route left open by a crash or force-stop.
  Future<void> recoverUnfinished() async {
    final t = await _repo.unfinished();
    if (t != null && t.id != _trackId) await _repo.finish(t.id!);
  }

  Future<int> start(
    String name, {
    int? beatId,
    required String notificationTitle,
    required String notificationText,
  }) async {
    if (_trackId != null) return _trackId!;
    final id = await _repo.start(name, beatId: beatId);
    _trackId = id;
    _last = null;
    _first = null;
    _seq = 0;
    _distance = 0;
    _gpsAccuracyM = null;
    notifyListeners();
    _sub = _location.fixes(backgroundTitle: notificationTitle, backgroundText: notificationText).listen(_onFix);
    return id;
  }

  void _onFix(GpsFix f) {
    if (_gpsAccuracyM != f.accuracyM) {
      _gpsAccuracyM = f.accuracyM;
      notifyListeners();
    }
    addFix(TrackPoint(f.point.lat, f.point.lng, accuracyM: f.accuracyM, time: f.time.millisecondsSinceEpoch));
  }

  /// Exposed for tests: filters and stores one GPS fix.
  @visibleForTesting
  Future<void> addFix(TrackPoint p) async {
    final id = _trackId;
    if (id == null || !shouldRecord(_last, p)) return;
    if (_last != null) _distance += _haversine(_last!, p);
    _last = p;
    _first ??= p;
    final seq = _seq++;
    await _repo.addPoint(id, seq, p, _distance);
    notifyListeners();
  }

  double _haversine(TrackPoint a, TrackPoint b) => trackLength([a, b]);

  /// Stops and saves. Returns the track id (null if nothing was recording).
  Future<int?> stop() async {
    final id = _trackId;
    if (id == null) return null;
    await _sub?.cancel();
    _sub = null;
    _trackId = null;
    _gpsAccuracyM = null;
    final count = _seq;
    if (count < 2) {
      await _repo.delete(id); // nothing useful recorded
      notifyListeners();
      return null;
    }
    await _repo.finish(id);
    notifyListeners();
    return id;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
