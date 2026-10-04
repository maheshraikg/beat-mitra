import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/geo.dart';
import '../../core/track_recorder.dart';
import '../../data/repos/track_repo.dart';
import '../common/widgets.dart';
import 'track_actions.dart';
import 'track_detail_screen.dart';

/// "My routes": record the walk, list saved routes, go back to the start.
class TracksScreen extends StatefulWidget {
  const TracksScreen({super.key});

  @override
  State<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> {
  List<Track> _tracks = [];
  int _version = -1;
  bool _wasRecording = false;

  Future<void> _load() async {
    final list = await context.services.tracks.tracks(beatId: context.app.activeBeat?.id);
    if (mounted) setState(() => _tracks = list);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final v = context.watch<AppState>().version;
    final rec = context.watch<TrackRecorder>();
    if (v != _version || rec.recording != _wasRecording) {
      _version = v;
      _wasRecording = rec.recording;
      _load();
    }
    final settings = context.services.settings;
    final office = settings.officeLat != null && settings.officeLng != null
        ? GeoPoint(settings.officeLat!, settings.officeLng!)
        : null;
    final lastStart = rec.firstPoint?.point;
    final gpsStatus = rec.recording ? recordingGpsStatus(context, rec.gpsAccuracyM, rec.distanceM) : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.myRoutes)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
        children: [
          Card(
            color: rec.recording ? Theme.of(context).colorScheme.errorContainer : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        rec.recording ? Icons.fiber_manual_record : Icons.route,
                        color: rec.recording ? Colors.red : null,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec.recording ? l.recordingNow(formatDistance(rec.distanceM)) : l.recordHelp,
                          style: t.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  if (gpsStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(gpsStatus, style: t.bodyMedium),
                    ),
                  const SizedBox(height: 10),
                  rec.recording
                      ? FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => stopRecording(context),
                          icon: const Icon(Icons.stop),
                          label: Text(l.stopAndSave),
                        )
                      : FilledButton.icon(
                          onPressed: () => startRecording(context),
                          icon: const Icon(Icons.fiber_manual_record),
                          label: Text(l.startRecording),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(l.backToStart, style: t.titleLarge),
          const SizedBox(height: 4),
          if (lastStart != null) _BackRow(label: l.backToRouteStart, target: lastStart),
          if (office != null) _BackRow(label: l.backToOffice, target: office),
          if (lastStart == null && office == null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l.setOfficeHint, style: t.bodyMedium),
            ),
          const SizedBox(height: 12),
          Text(l.savedRoutes, style: t.titleLarge),
          if (_tracks.where((x) => !x.recording).isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.noRoutesYet, style: t.bodyLarge),
            ),
          for (final tr in _tracks.where((x) => !x.recording))
            Card(
              child: ListTile(
                leading: const Icon(Icons.route, size: 32),
                title: Text(tr.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                subtitle: Text('${formatDistance(tr.distanceM)} · ${formatDuration(tr.duration)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TrackDetailScreen(trackId: tr.id!))),
              ),
            ),
        ],
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.label, required this.target});
  final String label;
  final GeoPoint target;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => openBackTo(context, target, label),
                    icon: const Icon(Icons.explore),
                    label: Text(l.arrowOffline),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => googleMapsTo(target),
                    icon: const Icon(Icons.map),
                    label: Text(l.googleMaps),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
