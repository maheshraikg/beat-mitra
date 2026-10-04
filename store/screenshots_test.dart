// Generates Play Store screenshots (1080 x 1920) of real app screens with
// sample data, in English, Kannada and Hindi.
//
//   flutter test store/screenshots_test.dart
//
// Output: store/screenshots/<lang>/<n>_<name>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:beat_mitra/app.dart';
import 'package:beat_mitra/app_state.dart';
import 'package:beat_mitra/core/article_number.dart';
import 'package:beat_mitra/core/geo.dart';
import 'package:beat_mitra/core/track.dart';
import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/features/home/home_screen.dart';
import 'package:beat_mitra/features/learn/learn_screen.dart';
import 'package:beat_mitra/features/learn/quiz.dart';
import 'package:beat_mitra/features/run/run_screen.dart';
import 'package:beat_mitra/features/search/search_screen.dart';
import 'package:beat_mitra/features/summary/summary_screen.dart';
import 'package:beat_mitra/features/today/today_screen.dart';
import 'package:beat_mitra/features/tracks/follow_track_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/widget/harness.dart';

const _sdkFonts = 'bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-sdk/flutter';
  Future<ByteData> f(String path) async => ByteData.sublistView(await File(path).readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(f('$flutterRoot/$_sdkFonts/Roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(f('$flutterRoot/$_sdkFonts/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('NotoSansKannada')..addFont(f('store/fonts/NotoSansKannada.ttf'))).load();
  await (FontLoader('NotoSansDevanagari')..addFont(f('store/fonts/NotoSansDevanagari.ttf'))).load();
}

void main() {
  setUpAll(_loadFonts);

  final today = dayKey(DateTime.now());
  const base = GeoPoint(12.9716, 77.6412);

  Future<(AppState, Map<String, int>)> seed(String lang) async {
    final s = await testServices(here: const GeoPoint(12.97175, 77.64125));
    s.settings.localeCode = lang;
    s.settings.lastBackupAt = DateTime.now().millisecondsSinceEpoch;
    final names = switch (lang) {
      'kn' => ['ರಮೇಶ್ ಕುಮಾರ್', 'ಲಕ್ಷ್ಮಿ ದೇವಿ', 'ಸುರೇಶ್ ರಾವ್', 'ಕಾವ್ಯ ಹೆಗ್ಡೆ', 'ಮಂಜುನಾಥ್ ಗೌಡ', 'ಅನಿಲ್ ಶೆಟ್ಟಿ'],
      'hi' => ['रमेश कुमार', 'लक्ष्मी देवी', 'सुरेश राव', 'काव्या शर्मा', 'मंजुनाथ गौड़ा', 'अनिल वर्मा'],
      _ => ['Ramesh Kumar', 'Lakshmi Devi', 'Suresh Rao', 'Kavya Hegde', 'Manjunath Gowda', 'Anil Shetty'],
    };
    final landmarks = switch (lang) {
      'kn' => ['ಗಣೇಶ ದೇವಸ್ಥಾನದ ಎದುರು', 'ಹಾಲಿನ ಡೈರಿ ಪಕ್ಕ', 'ಶಾಲೆಯ ಹಿಂದೆ'],
      'hi' => ['गणेश मंदिर के सामने', 'दूध डेरी के पास', 'स्कूल के पीछे'],
      _ => ['Opp. Ganesha temple', 'Next to milk dairy', 'Behind the school'],
    };
    final beat = await s.beats.saveBeat(Beat(name: 'Beat 7 – HAL 2nd Stage', office: 'HAL II Stage S.O.'));
    final st1 = await s.beats.saveStreet(Street(beatId: beat, name: '4th Cross, 2nd Main'));
    final st2 = await s.beats.saveStreet(Street(beatId: beat, name: '5th Cross, 2nd Main'));
    final ids = <String, int>{};
    final photos = [for (var i = 0; i < 3; i++) await File('store/photos/house$i.jpg').readAsBytes()];
    for (var i = 0; i < 6; i++) {
      final id = await s.places.savePlace(
        Place(
          beatId: beat,
          streetId: i < 3 ? st1 : st2,
          doorNo: ['12/3', '14', '16/1', '21', '23A', '25'][i],
          landmark: landmarks[i % 3],
          lat: base.lat + 0.0003 * (i + 1),
          lng: base.lng + (i < 3 ? 0 : 0.0005),
          type: i == 4 ? PlaceType.shop : PlaceType.house,
          notes: i == 0
              ? (lang == 'kn'
                    ? 'ನಾಯಿ ಇದೆ'
                    : lang == 'hi'
                    ? 'कुत्ता है'
                    : 'Dog at gate')
              : '',
          pin: '560008',
        ),
      );
      ids['p$i'] = id;
      await s.places.setAddressees(id, [Addressee(placeId: id, name: names[i])]);
      if (i < 3) {
        final f = await s.photos.saveBytes(Uint8List.fromList(photos[i]));
        await s.places.addPhoto(PlacePhoto(placeId: id, filePath: f));
      }
    }
    final types = [
      ArticleType.speedPost,
      ArticleType.registered,
      ArticleType.letter,
      ArticleType.letter,
      ArticleType.parcel,
      ArticleType.letter,
    ];
    for (var i = 0; i < 6; i++) {
      await s.articles.save(
        Article(
          date: today,
          articleNo: types[i] == ArticleType.letter ? '' : 'EK12345678${i}IN',
          type: types[i],
          placeId: ids['p$i'],
          status: i < 2 ? ArticleStatus.delivered : (i == 2 ? ArticleStatus.notDelivered : ArticleStatus.pending),
          reason: i == 2 ? 'doorLocked' : null,
          lat: i < 3 ? base.lat + 0.0003 * (i + 1) : null,
          lng: i < 3 ? base.lng : null,
          deliveredAt: i < 3 ? 1000 * i : null,
        ),
      );
    }
    await s.articles.save(Article(date: today, rawAddress: 'Kavya Rao\n40 1st Main', type: ArticleType.letter));
    // A recorded walk: up 4th Cross, across, down 5th Cross.
    final tr = await s.tracks.start(
      lang == 'kn'
          ? 'ವಿತರಣೆ $today'
          : lang == 'hi'
          ? 'वितरण $today'
          : 'Delivery $today',
      beatId: beat,
    );
    var seq = 0;
    for (var i = 0; i <= 12; i++) {
      await s.tracks.addPoint(tr, seq++, TrackPoint(base.lat + i * 0.00018, base.lng), 0);
    }
    for (var i = 1; i <= 5; i++) {
      await s.tracks.addPoint(tr, seq++, TrackPoint(base.lat + 12 * 0.00018, base.lng + i * 0.0001), 0);
    }
    for (var i = 11; i >= 0; i--) {
      await s.tracks.addPoint(tr, seq++, TrackPoint(base.lat + i * 0.00018, base.lng + 0.0005), 0);
    }
    await s.tracks.finish(tr);
    ids['track'] = tr;
    for (final p in [ids['p0']!, ids['p1']!]) {
      await s.learn.record(p, true);
      await s.learn.record(p, true);
    }
    final state = AppState(s);
    await state.init();
    return (state, ids);
  }

  Future<void> shoot(
    WidgetTester tester,
    AppState state,
    Widget screen,
    String file, {
    Future<void> Function()? act,
  }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        child: BeatMitraApp(services: state.s, state: state, home: screen),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (act != null) await act();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2.625);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      final f = File(file)..createSync(recursive: true);
      f.writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  for (final lang in ['en', 'kn', 'hi']) {
    testWidgets('screenshots $lang', (tester) async {
      late AppState state;
      late Map<String, int> ids;
      await tester.runAsync(() async => (state, ids) = await seed(lang));
      final dir = 'store/screenshots/$lang';
      await shoot(tester, state, const HomeScreen(), '$dir/1_home.png');
      await shoot(tester, state, SearchScreen(initialQuery: lang == 'en' ? 'ರಮೇಶ್' : 'Ramesh'), '$dir/2_search.png');
      await shoot(tester, state, RunScreen(order: [ids['p3']!, ids['p4']!, ids['p5']!]), '$dir/3_run.png');
      await shoot(tester, state, FollowTrackScreen(trackId: ids['track']!), '$dir/4_follow_route.png');
      await shoot(tester, state, const TodayScreen(), '$dir/5_today.png');
      await shoot(tester, state, const SummaryScreen(), '$dir/6_summary.png');
      await shoot(tester, state, const FlashcardScreen(mode: QuizMode.photoToPlace), '$dir/7_learn.png');
      await shoot(tester, state, const LearnScreen(), '$dir/8_progress.png');
    });
  }
}
