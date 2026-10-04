import 'package:beat_mitra/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminanceGap(Color a, Color b) => (a.computeLuminance() - b.computeLuminance()).abs();

void main() {
  for (final sunlight in [false, true]) {
    for (final b in Brightness.values) {
      testWidgets('chip labels readable ($b, sunlight $sunlight)', (t) async {
        final theme = buildTheme(b, sunlight: sunlight);
        await t.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Wrap(
                children: [
                  ActionChip(label: const Text('Dog'), onPressed: () {}),
                  ChoiceChip(label: const Text('House'), selected: true, onSelected: (_) {}),
                  ChoiceChip(label: const Text('Shop'), selected: false, onSelected: (_) {}),
                ],
              ),
            ),
          ),
        );
        for (final s in ['Dog', 'House', 'Shop']) {
          final p = t.renderObject<RenderParagraph>(find.text(s));
          expect(p.text.style!.fontSize, 16);
          expect(_luminanceGap(p.text.style!.color!, theme.colorScheme.surface), greaterThan(0.3), reason: s);
        }
      });
    }
  }
}
