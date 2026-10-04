import 'package:sqflite_common/sqlite_api.dart';

import '../../core/track.dart';

class Track {
  Track({
    this.id,
    this.beatId,
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.distanceM = 0,
    this.note = '',
  });
  final int? id;
  final int? beatId;
  final String name;
  final int startedAt;
  final int? endedAt;
  final double distanceM;
  final String note;

  bool get recording => endedAt == null;
  Duration get duration => Duration(milliseconds: (endedAt ?? DateTime.now().millisecondsSinceEpoch) - startedAt);

  Map<String, Object?> toMap() => {
    'id': id,
    'beat_id': beatId,
    'name': name,
    'started_at': startedAt,
    'ended_at': endedAt,
    'distance_m': distanceM,
    'note': note,
  };

  factory Track.fromMap(Map<String, Object?> m) => Track(
    id: m['id'] as int?,
    beatId: m['beat_id'] as int?,
    name: m['name'] as String? ?? '',
    startedAt: m['started_at'] as int? ?? 0,
    endedAt: m['ended_at'] as int?,
    distanceM: (m['distance_m'] as num?)?.toDouble() ?? 0,
    note: m['note'] as String? ?? '',
  );
}

/// Recorded routes and their GPS points (on device only).
class TrackRepo {
  TrackRepo(this.db);
  final Database db;

  Future<int> start(String name, {int? beatId}) => db.insert(
    'tracks',
    Track(name: name, beatId: beatId, startedAt: DateTime.now().millisecondsSinceEpoch).toMap()..remove('id'),
  );

  Future<void> addPoint(int trackId, int seq, TrackPoint p, double distanceM) async {
    await db.insert('track_points', {
      'track_id': trackId,
      'seq': seq,
      'lat': p.lat,
      'lng': p.lng,
      'acc': p.accuracyM,
      't': p.time,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.update('tracks', {'distance_m': distanceM}, where: 'id = ?', whereArgs: [trackId]);
  }

  Future<void> finish(int trackId) async {
    final pts = await points(trackId);
    await db.update(
      'tracks',
      {'ended_at': DateTime.now().millisecondsSinceEpoch, 'distance_m': trackLength(pts)},
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  Future<void> rename(int trackId, String name) =>
      db.update('tracks', {'name': name}, where: 'id = ?', whereArgs: [trackId]);

  Future<void> delete(int trackId) => db.delete('tracks', where: 'id = ?', whereArgs: [trackId]);

  Future<Track?> track(int id) async {
    final r = await db.query('tracks', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Track.fromMap(r.first);
  }

  /// Newest first; [beatId] null = all beats.
  Future<List<Track>> tracks({int? beatId}) async => (await db.query(
    'tracks',
    where: beatId == null ? null : 'beat_id = ? OR beat_id IS NULL',
    whereArgs: beatId == null ? null : [beatId],
    orderBy: 'started_at DESC',
  )).map(Track.fromMap).toList();

  /// A route left "recording" by a crash / force-stop.
  Future<Track?> unfinished() async {
    final r = await db.query('tracks', where: 'ended_at IS NULL', orderBy: 'started_at DESC', limit: 1);
    return r.isEmpty ? null : Track.fromMap(r.first);
  }

  Future<List<TrackPoint>> points(int trackId) async =>
      (await db.query('track_points', where: 'track_id = ?', whereArgs: [trackId], orderBy: 'seq'))
          .map(
            (r) => TrackPoint(
              (r['lat'] as num).toDouble(),
              (r['lng'] as num).toDouble(),
              accuracyM: (r['acc'] as num?)?.toDouble() ?? 0,
              time: r['t'] as int? ?? 0,
            ),
          )
          .toList();

  Future<int> pointCount(int trackId) async =>
      (await db.rawQuery('SELECT COUNT(*) AS c FROM track_points WHERE track_id = ?', [trackId])).first['c'] as int;
}
