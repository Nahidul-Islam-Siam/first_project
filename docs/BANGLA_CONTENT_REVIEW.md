# Bangla Content Review Checklist

This checklist tracks editorial QA for Bangla Islamic text in Noorify.

## Scope

- `assets/data/duas.json`
- `assets/data/hadith_bukhari_50.json`
- UI labels in Profile / Qibla / Hadith screens

## Review Rules

1. Keep Arabic text unchanged.
2. Keep English source meaning unchanged.
3. Improve Bangla wording for natural Bangladesh usage.
4. Prefer consistent terms:
- `namaz` over `namay`
- `azan` over `athan`
- Keep `rasul` spelling consistent
- Keep `quran` spelling consistent
5. Keep respectful phrasing for Islamic honorifics.

## Current Status

- Bangla-first defaults: implemented.
- Bangla UI labels for core screens: implemented.
- Dua/Hadith Bangla title wording pass: implemented.
- Full scholar/editor review of all Bangla body text: pending.

## Final Pre-Release Gate

- One qualified reviewer validates top 100 most viewed entries.
- One Islamic reviewer validates theological wording for hadith/dua meanings.
- Run `flutter analyze` and `flutter test` after any content edits.
