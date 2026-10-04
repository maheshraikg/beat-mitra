import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/geo.dart';
import '../../core/services/location_service.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';
import 'track_actions.dart';

/// Big offline arrow back to a point (post office / where the route started),
/// with a button to open the same destination in Google Maps.
class BackToStartScreen extends StatefulWidget {
  const BackToStartScreen({super.key, required this.target, required this.label});
  final GeoPoint target;
  final String label;

  @override
  State<BackToStartScreen> createState() => _BackToStartScreenState();
}

class _BackToStartScreenState extends State<BackToStartScreen> with LiveLocation {
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    startLocation();
  }

  @override
  void onFix(GpsFix f) {
    final d = haversineMeters(f.point, widget.target);
    if (d <= 25 && !_arrived) {
      _arrived = true;
      if (context.services.settings.vibrateNear) HapticFeedback.heavyImpact();
    } else if (d > 40) {
      _arrived = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final dist = here == null ? null : haversineMeters(here!, widget.target);
    final rel = here == null ? null : relativeBearing(bearingDegrees(here!, widget.target), heading ?? 0);
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: dist == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(l.gpsWaiting, style: t.titleLarge),
                        ],
                      )
                    : Semantics(
                        label: l.distanceAway(formatDistance(dist)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _arrived
                                ? Icon(Icons.where_to_vote, size: 200, color: Colors.green.shade600)
                                : Transform.rotate(
                                    angle: rel! * math.pi / 180,
                                    child: Icon(
                                      Icons.navigation,
                                      size: 220,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                            Text(
                              _arrived ? l.arrived : formatDistance(dist),
                              style: t.displayMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            if (heading == null) Text(l.noCompass, style: t.bodyMedium),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () => googleMapsTo(widget.target),
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
