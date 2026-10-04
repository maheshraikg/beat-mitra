import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/geo.dart';
import '../../core/services/location_service.dart';
import '../../core/track.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';
import 'track_actions.dart';
import 'track_view.dart';

/// Walks a saved route step by step (forwards, or backwards to return to
/// where it started): big arrow to a point ~25 m ahead on the line, distance
/// left, "off route" warning. Fully offline.
class FollowTrackScreen extends StatefulWidget {
  const FollowTrackScreen({super.key, required this.trackId, this.reverse = false});
  final int trackId;
  final bool reverse;

  @override
  State<FollowTrackScreen> createState() => _FollowTrackScreenState();
}

class _FollowTrackScreenState extends State<FollowTrackScreen> with LiveLocation {
  List<TrackPoint> _pts = [];
  FollowState? _state;
  int _progress = 0;
  bool _offWarned = false;
  bool _doneBuzzed = false;

  @override
  void initState() {
    super.initState();
    context.services.tracks.points(widget.trackId).then((pts) {
      if (!mounted) return;
      setState(() => _pts = widget.reverse ? pts.reversed.toList() : pts);
      if (fix != null) onFix(fix!);
    });
    startLocation();
  }

  @override
  void onFix(GpsFix f) {
    if (_pts.length < 2) return;
    final st = follow(_pts, f.point, progress: _progress);
    _progress = math.max(_progress, st.nearest);
    final vibrate = context.services.settings.vibrateNear;
    if (st.offRouteM > 50 && !_offWarned) {
      _offWarned = true;
      if (vibrate) HapticFeedback.heavyImpact();
    } else if (st.offRouteM < 30) {
      _offWarned = false;
    }
    if (st.done && !_doneBuzzed) {
      _doneBuzzed = true;
      if (vibrate) HapticFeedback.heavyImpact();
    }
    setState(() => _state = st);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final st = _state;
    final target = st == null ? null : _pts[st.target].point;
    final rel = (here == null || target == null) ? null : relativeBearing(bearingDegrees(here!, target), heading ?? 0);
    return Scaffold(
      appBar: AppBar(title: Text(widget.reverse ? l.followRouteBack : l.followRoute)),
      body: _pts.length < 2
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: st == null || rel == null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(l.gpsWaiting, style: t.titleLarge),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                st.done
                                    ? Icon(Icons.where_to_vote, size: 170, color: Colors.green.shade600)
                                    : Transform.rotate(
                                        angle: rel * math.pi / 180,
                                        child: Icon(Icons.navigation, size: 190, color: scheme.primary),
                                      ),
                                Text(
                                  st.done ? l.arrived : l.remainingOnRoute(formatDistance(st.remainingM)),
                                  style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                if (!st.done && st.offRouteM > 40)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    color: scheme.errorContainer,
                                    child: Text(
                                      l.offRoute(formatDistance(st.offRouteM)),
                                      style: t.titleMedium?.copyWith(color: scheme.onErrorContainer),
                                    ),
                                  ),
                                if (heading == null) Text(l.noCompass, style: t.bodyMedium),
                              ],
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TrackView(points: _pts, here: here, target: target, progress: st?.nearest, height: 200),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          openGoogleMaps(googleMapsRouteUrl(_pts.sublist(math.min(_progress, _pts.length - 2)))),
                      icon: const Icon(Icons.map),
                      label: Text(l.openInGoogleMaps),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
