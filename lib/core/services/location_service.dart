import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../geo.dart';

class GpsFix {
  const GpsFix(this.point, this.accuracyM, this.time);
  final GeoPoint point;
  final double accuracyM;
  final DateTime time;
}

enum LocationProblem { none, serviceOff, denied, deniedForever }

/// GPS + compass, kept behind an interface so screens can be tested.
abstract class LocationService {
  Future<LocationProblem> ensurePermission();
  Future<GpsFix?> current();

  /// Live fixes. With [background], Android keeps a foreground service (with
  /// a small notification) so recording continues with the screen off.
  Stream<GpsFix> fixes({String? backgroundTitle, String? backgroundText});

  /// Compass heading in degrees (0 = north) or null if no sensor.
  Stream<double?> heading();
  Future<void> openSettings();
}

class DeviceLocationService implements LocationService {
  GpsFix? _last;

  GpsFix _toFix(Position p) => GpsFix(GeoPoint(p.latitude, p.longitude), p.accuracy, p.timestamp);

  @override
  Future<LocationProblem> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationProblem.serviceOff;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return LocationProblem.deniedForever;
    if (perm == LocationPermission.denied) return LocationProblem.denied;
    return LocationProblem.none;
  }

  @override
  Future<GpsFix?> current() async {
    if (await ensurePermission() != LocationProblem.none) return _last;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 20)),
      );
      return _last = _toFix(p);
    } on TimeoutException {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? _last : _last = _toFix(p);
    } catch (_) {
      return _last;
    }
  }

  @override
  Stream<GpsFix> fixes({String? backgroundTitle, String? backgroundText}) async* {
    if (await ensurePermission() != LocationProblem.none) return;
    yield* Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: backgroundTitle == null ? 1 : 3),
        foregroundNotificationConfig: backgroundTitle == null
            ? null
            : ForegroundNotificationConfig(
                notificationTitle: backgroundTitle,
                notificationText: backgroundText ?? '',
                notificationChannelName: 'Route recording',
                setOngoing: true,
                enableWakeLock: true,
              ),
      ),
    ).map((p) => _last = _toFix(p)).handleError((_) {});
  }

  @override
  Stream<double?> heading() => (FlutterCompass.events ?? const Stream<CompassEvent>.empty()).map((e) => e.heading);

  @override
  Future<void> openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
