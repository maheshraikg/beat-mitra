import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/geo.dart';
import '../../core/track.dart';
import '../../data/repos/track_repo.dart';
import '../common/widgets.dart';
import '../settings/map_screen.dart';
import 'follow_track_screen.dart';
import 'track_actions.dart';
import 'track_view.dart';

/// One saved route: drawing, follow (forwards / back), Google Maps, GPX.
class TrackDetailScreen extends StatefulWidget {
  const TrackDetailScreen({super.key, required this.trackId});
  final int trackId;

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen> {
  Track? _track;
  List<TrackPoint> _pts = [];
  List<GeoPoint> _places = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = context.services;
    final tr = await s.tracks.track(widget.trackId);
    final pts = await s.tracks.points(widget.trackId);
    final places = tr?.beatId == null ? [] : await s.places.allDetails(beatId: tr!.beatId);
    if (!mounted) return;
    setState(() {
      _track = tr;
      _pts = pts;
      _places = [for (final d in places) ?d.place.point];
    });
  }

  Future<void> _rename() async {
    final l = context.l;
    final name = await askText(context, l.renameRoute, initial: _track?.name ?? '', label: l.name);
    if (name == null || name.trim().isEmpty || !mounted) return;
    await context.services.tracks.rename(widget.trackId, name.trim());
    _load();
  }

  Future<void> _delete() async {
    final l = context.l;
    if (!await confirm(context, l.deleteRoute, l.deleteRouteConfirm, danger: true, ok: l.delete)) return;
    if (!mounted) return;
    await context.services.tracks.delete(widget.trackId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _shareGpx() async {
    final tr = _track!;
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'exports'))..createSync(recursive: true);
    final safe = tr.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final f = File(p.join(dir.path, '$safe.gpx'));
    await f.writeAsString(toGpx(tr.name, _pts));
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/gpx+xml')]));
  }

  void _follow({required bool reverse}) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FollowTrackScreen(trackId: widget.trackId, reverse: reverse),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final tr = _track;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr?.name ?? ''),
        actions: [
          if (tr != null)
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'rename' => _rename(),
                'gpx' => _shareGpx(),
                'delete' => _delete(),
                _ => null,
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: Text(l.renameRoute)),
                PopupMenuItem(value: 'gpx', child: Text(l.shareGpx)),
                PopupMenuItem(value: 'delete', child: Text(l.deleteRoute)),
              ],
            ),
        ],
      ),
      body: tr == null
          ? const Center(child: CircularProgressIndicator())
          : _pts.length < 2
          ? EmptyState(icon: Icons.route, text: l.routeTooShort)
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TrackView(points: _pts, places: _places, height: 320),
                const SizedBox(height: 8),
                Text('${formatDistance(trackLength(_pts))} · ${formatDuration(tr.duration)}', style: t.titleLarge),
                Text(l.routeLegend, style: t.bodyMedium),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _follow(reverse: false),
                  icon: const Icon(Icons.directions_walk),
                  label: Text(l.followRoute),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _follow(reverse: true),
                  icon: const Icon(Icons.u_turn_left),
                  label: Text(l.followRouteBack),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => openBackTo(context, _pts.first.point, l.backToRouteStart),
                  icon: const Icon(Icons.explore),
                  label: Text(l.backToRouteStart),
                ),
                const Divider(height: 28),
                Text(l.googleMaps, style: t.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openGoogleMaps(googleMapsRouteUrl(_pts)),
                        icon: const Icon(Icons.map),
                        label: Text(l.gmapsRoute),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => googleMapsTo(_pts.first.point),
                        icon: const Icon(Icons.home_work_outlined),
                        label: Text(l.gmapsToStart),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(l.gmapsNote, style: t.bodySmall),
                ),
                if (mapAvailableInBuild && context.services.settings.onlineMap) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(trackId: widget.trackId))),
                    icon: const Icon(Icons.public),
                    label: Text(l.showOnMap),
                  ),
                ],
              ],
            ),
    );
  }
}
