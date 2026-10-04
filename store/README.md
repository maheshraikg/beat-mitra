# Store assets

- `PLAY_STORE_GUIDE.md` – step-by-step Play Console guide with all answers
- `listing/*.txt` – title, short and full description (en, kn, hi)
- `screenshots/<lang>/*.png` – 1080×1920 phone screenshots (regenerate with
  `flutter test store/screenshots_test.dart`)
- `feature-graphic.png` (1024×500), `icon-512.png`: made from `tool/logo-source.png`
  with `python3 tool/make_icon.py` and `python3 tool/make_feature_graphic.py`
- `fonts/` – Noto Sans Kannada / Devanagari (OFL) used only for screenshots
- `photos/` – sample house drawings used only in screenshots
