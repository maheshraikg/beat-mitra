import 'package:flutter/material.dart';

const Color seedRed = Color(0xFFC62828);
const Color accentAmber = Color(0xFFFFB300);

/// Material 3 theme tuned for outdoor, one-handed use: large text, big
/// buttons (min 56 dp), strong contrast. [sunlight] gives a high-contrast
/// black/white/yellow scheme for bright sun.
ThemeData buildTheme(Brightness brightness, {bool sunlight = false}) {
  var scheme = ColorScheme.fromSeed(
    seedColor: seedRed,
    brightness: brightness,
    secondary: accentAmber,
    onSecondary: Colors.black,
  );
  if (sunlight) {
    scheme = brightness == Brightness.light
        ? scheme.copyWith(
            primary: const Color(0xFF8E0000),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            onSurfaceVariant: Colors.black,
            surfaceContainerHighest: const Color(0xFFF0F0F0),
            surfaceContainer: Colors.white,
            surfaceContainerLow: Colors.white,
            outline: Colors.black,
            secondary: const Color(0xFFFFC400),
            onSecondary: Colors.black,
          )
        : scheme.copyWith(
            primary: const Color(0xFFFFD54F),
            onPrimary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
            onSurfaceVariant: Colors.white,
            surfaceContainerHighest: const Color(0xFF1A1A1A),
            surfaceContainer: Colors.black,
            surfaceContainerLow: Colors.black,
            outline: Colors.white,
            secondary: const Color(0xFFFFD54F),
            onSecondary: Colors.black,
          );
  }

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, visualDensity: VisualDensity.standard);
  final text = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
    // Android falls back to system fonts anyway; naming Noto keeps Kannada and
    // Devanagari readable where only bundled fonts exist (store screenshots).
    fontFamilyFallback: const ['NotoSansKannada', 'NotoSansDevanagari'],
  );
  const big = Size(64, 56);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  final btnText = text.labelLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  final side = sunlight ? BorderSide(color: scheme.outline, width: 2) : null;

  return base.copyWith(
    textTheme: text.copyWith(
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 18),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 16),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      // Chips take their label from labelLarge (colour picked per state by
      // the chip itself), so the size is set here and not in chipTheme.
      labelLarge: text.labelLarge?.copyWith(fontSize: 16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      centerTitle: false,
      titleTextStyle: text.titleLarge!.copyWith(fontSize: 21, fontWeight: FontWeight.w700, color: scheme.onPrimary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: big, shape: shape, textStyle: btnText, side: side),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(minimumSize: big, shape: shape, textStyle: btnText, side: side),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: big,
        shape: shape,
        textStyle: btnText,
        side: BorderSide(color: scheme.outline, width: sunlight ? 2 : 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: btnText),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
      extendedTextStyle: btnText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: sunlight
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outline, width: 2),
            )
          : null,
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: sunlight ? BorderSide(color: scheme.outline, width: 2) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // No labelStyle here: a fixed label colour in chipTheme showed light text
    // on light chips on some phones. The chip's own default resolves the
    // colour from the current scheme at build time.
    chipTheme: base.chipTheme.copyWith(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
  );
}
