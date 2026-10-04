import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/geo.dart';
import '../../core/services/location_service.dart';
import '../../core/services/platform.dart';
import '../../core/track.dart';
import '../../data/models.dart' show dayKey;
import '../common/widgets.dart';
import 'back_to_start_screen.dart';

/// Starts recording the walk (no-op if already recording). Checks location
/// first, so recording never starts silently without GPS.
Future<void> startRecording(BuildContext context, {String? name}) async {
  final l = context.l;
  final s = context.services;
  final problem = await s.location.ensurePermission();
  if (problem != LocationProblem.none) {
    if (context.mounted) context.toast(problem == LocationProblem.serviceOff ? l.gpsOff : l.gpsDenied);
    if (problem != LocationProblem.denied) await s.location.openSettings();
    return;
  }
  if (!await s.location.ensurePrecise()) {
    if (context.mounted && await confirm(context, l.preciseOffTitle, l.preciseOffBody, ok: l.openSettings)) {
      await s.location.openSettings();
    }
    return;
  }
  await PlatformBridge.requestNotificationPermission();
  if (!context.mounted) return;
  final now = DateTime.now();
  final hh = now.hour.toString().padLeft(2, '0'), mm = now.minute.toString().padLeft(2, '0');
  await s.recorder.start(
    name ?? l.routeNameDefault('${dayKey(now)} $hh:$mm'),
    beatId: context.app.activeBeat?.id,
    notificationTitle: l.recordingNotifTitle,
    notificationText: l.recordingNotifText,
  );
}

/// Stops recording; returns the saved track id.
Future<int?> stopRecording(BuildContext context) async {
  final l = context.l;
  final id = await context.services.recorder.stop();
  if (context.mounted) context.toast(id == null ? l.routeTooShort : l.routeSaved);
  return id;
}

Future<void> openGoogleMaps(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Opens Google Maps walking directions from here to [p].
Future<void> googleMapsTo(GeoPoint p) => openGoogleMaps(googleMapsDirectionsUrl(destination: p));

void openBackTo(BuildContext context, GeoPoint target, String label) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BackToStartScreen(target: target, label: label),
  ),
);

String formatDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${d.inMinutes} min';
}

/// One line under "Recording route": waiting for GPS, GPS too weak (with the
/// accuracy), or "GPS OK, start walking" until the first metres are counted.
String recordingGpsStatus(BuildContext context, double? accuracyM, double distanceM) {
  final l = context.l;
  if (accuracyM == null) return l.gpsWaiting;
  if (accuracyM > recordMaxAccuracyM) {
    return '${l.gpsAccuracy(accuracyM.round(), recordMaxAccuracyM.round())}\n'
        '${l.recordGpsWeak(recordMaxAccuracyM.round())}\n${l.recordGpsTip}';
  }
  return distanceM < 1
      ? '${l.gpsAccuracyShort(accuracyM.round())} · ${l.recordGpsOk}'
      : l.gpsAccuracyShort(accuracyM.round());
}
