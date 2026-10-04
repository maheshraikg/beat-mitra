import 'dart:async';

import 'package:beat_mitra/core/geo.dart';
import 'package:beat_mitra/core/services/location_service.dart';
import 'package:beat_mitra/core/track.dart';
import 'package:beat_mitra/core/track_recorder.dart';
import 'package:beat_mitra/data/db.dart';
import 'package:beat_mitra/data/repos/track_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test_db.dart';

class _NoGps implements LocationService {
  @override
  Future<LocationProblem> ensurePermission() async => LocationProblem.none;
  @override
  Future<GpsFix?> current() async => null;
  @override
  Stream<GpsFix> fixes({String? backgroundTitle, String? backgroundText}) => const Stream.empty();
  @override
  Stream<double?> heading() => const Stream.empty();
  @override
  Future<void> openSettings() async {}
}

void main() {
  test('recorder filters fixes, stores points, finishes with distance', () async {
    final db = await openTestDatabase();
    final repo = TrackRepo(db.db);
    final rec = TrackRecorder(repo, _NoGps());
    final id = await rec.start('Delivery', notificationTitle: 't', notificationText: 'x');
    expect(rec.recording, isTrue);
    for (var i = 0; i < 10; i++) {
      await rec.addFix(TrackPoint(12.97 + i * 0.0001, 77.64, accuracyM: 5, time: i));
      await rec.addFix(TrackPoint(12.97 + i * 0.0001 + 0.00001, 77.64, accuracyM: 5, time: i)); // jitter
    }
    await rec.addFix(const TrackPoint(13.5, 77.64, accuracyM: 200)); // bad fix ignored
    expect(rec.pointCount, 10);
    expect(rec.distanceM, closeTo(100, 2));
    expect(await rec.stop(), id);
    final t = (await repo.track(id))!;
    expect(t.recording, isFalse);
    expect(t.distanceM, closeTo(100, 2));
    expect((await repo.points(id)).length, 10);
    expect((await repo.tracks()).single.name, 'Delivery');
  });

  test('a route with fewer than 2 points is discarded', () async {
    final db = await openTestDatabase();
    final repo = TrackRepo(db.db);
    final rec = TrackRecorder(repo, _NoGps());
    await rec.start('x', notificationTitle: 't', notificationText: 'x');
    await rec.addFix(const TrackPoint(12.97, 77.64, accuracyM: 5));
    expect(await rec.stop(), isNull);
    expect(await repo.tracks(), isEmpty);
  });

  test('unfinished route is closed on recovery', () async {
    final db = await openTestDatabase();
    final repo = TrackRepo(db.db);
    final id = await repo.start('crashed');
    await repo.addPoint(id, 0, const TrackPoint(12.97, 77.64), 0);
    await repo.addPoint(id, 1, const TrackPoint(12.971, 77.64), 111);
    await TrackRecorder(repo, _NoGps()).recoverUnfinished();
    final t = (await repo.track(id))!;
    expect(t.recording, isFalse);
    expect(t.distanceM, closeTo(111, 2));
  });

  test('database upgrade from v1 adds the route tables', () async {
    sqfliteFfiInit();
    final path = inMemoryDatabasePath;
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onCreate: (d, v) => d.execute('CREATE TABLE beats(id INTEGER PRIMARY KEY, name TEXT)'),
        onUpgrade: AppDatabase.onUpgrade,
      ),
    );
    await AppDatabase.onUpgrade(v1, 1, 2);
    final repo = TrackRepo(v1);
    final id = await repo.start('after upgrade');
    expect((await repo.track(id))!.name, 'after upgrade');
  });

  test('GeoPoint helper sanity', () {
    expect(haversineMeters(const GeoPoint(0, 0), const GeoPoint(0, 0)), 0);
  });
}
