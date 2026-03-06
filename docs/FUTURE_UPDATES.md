# Noorify Future Updates

This document tracks planned improvements for Noorify.

## Product Goals

- Help users build a consistent daily Islamic routine.
- Improve Quran learning, memorization, and reflection.
- Keep core features reliable in low-network conditions.

## Priority Roadmap

## App Completion Roadmap (High Priority)

Use this sequence to move Noorify from a strong prototype to a complete
production app.

1. Real Sign In / Sign Up Backend
- Add Firebase/Auth backend for email, Google, and phone login.
- Keep user session and secure token handling.

2. First-Time Onboarding
- Ask for language, location, notification permission, and prayer settings.
- Save onboarding choices to user profile.

3. Prayer Tracking Module
- Let users mark each prayer as done/missed.
- Show daily streaks and monthly progress.

4. Final Qibla Experience
- Add calibration guidance and compass accuracy status.
- Use location-based qibla with reliable offline fallback.

5. Quran Productivity Features
- Add bookmarks, highlights, notes, and synced last-read position.
- Improve resume-reading flow.

6. Audio Experience Upgrade
- Support background play and lock screen controls.
- Add repeat modes and stronger download manager controls.

7. Dua and Dhikr Section
- Add morning/evening adhkar, favorites, and reminder scheduling.
- Include tasbeeh counter with daily targets.

8. Ramadan Toolkit
- Add fasting tracker, sehri/iftar tools, zakat calculator, and goals.

9. Complete Profile and Account Controls
- Add profile photo upload and account management options.
- Add account delete and data export controls.

10. Release Readiness
- Add crash reporting, analytics, privacy/legal screens, and store QA checklist.

## Delivery Phases

Phase 1:
- 1, 2, 3

Phase 2:
- 4, 5, 6

Phase 3:
- 7, 8, 9, 10

## Current Execution Plan (No Backend, One by One)

We are currently in a local-first build phase (no backend yet).  
Implementation will happen feature-by-feature in this exact order:

1. Onboarding flow
- Language
- Location permission
- Notification permission
- Prayer calculation preference

2. Prayer tracker (local)
- Mark prayer done/missed
- Daily streak
- Weekly/monthly summary

3. Quran bookmarks and notes (local) [Done]
- Bookmark ayah
- Highlight and short personal note
- Resume from bookmark

4. Hifz mode (local)
- Repeat ayah N times
- A-B repeat
- Optional hide Bangla meaning mode

5. Dua and Dhikr section (local)
- Morning/evening adhkar
- Favorite list
- Tasbeeh counter

6. Offline download manager improvements
- Download status
- Retry/delete controls
- Offline-ready indicator

7. Reminder center
- Custom reminder times
- Prayer-related reminders
- Quiet-hours support

8. Qibla polish
- Calibration guidance
- Accuracy indicator
- Better fallback messaging

9. Profile polish (local)
- Profile picture placeholder support
- Better profile edit fields
- Preferences grouping cleanup

10. Local backup/restore
- Export local data file
- Import/restore local data file

### Work Rule

- We pick only one feature at a time.
- Finish implementation + test + docs update for that feature.
- Then move to the next feature.

## Progress Status

Completed (out of order by priority request):
- Full profile editing locally (photo, name, preferences)
  - Implemented Figma-style profile settings layout
  - Local photo picking and storage
  - Local theme/font/preference persistence
- Quran bookmarks and notes (local)
  - Ayah bookmark add/update/remove in Surah detail
  - Local note per bookmarked ayah
  - Surah-level bookmark list with jump-to-ayah
  - Quran home quick action for bookmark resume

Next up:
- Hifz Mode (local)

## 1) Hifz Mode (Memorization Mode) - Next Major Feature

Why:
- High-value recurring use case for Quran users.
- Works well with existing ayah-level playback and tafsir support.

MVP scope:
- Select ayah range (single ayah or multiple ayahs).
- Repeat each ayah N times (3 / 5 / 10).
- Pause between repeats (configurable short delay).
- "Hide Bangla text" practice mode for self-testing.
- Mark memorization progress per surah/ayah.

Technical notes:
- Reuse `SurahDetailScreen` playback pipeline.
- Persist progress with cache/local storage service.
- Keep logic compatible with both timed and fallback single-ayah audio.

Success metric:
- Users complete at least one memorization session daily.

## 2) Advanced Single-Ayah Player Controls

Scope:
- A-B repeat for one ayah.
- Auto-next mode (play ayah 1 -> 2 -> 3).
- Playback speed controls (0.75x / 1.0x / 1.25x).
- Optional "continue from last ayah" setting.

## 3) Quran Bookmarks and Collections

Scope:
- Local ayah bookmark + note is already implemented.
- Group bookmarks into named collections (e.g., "Morning", "Dua Ayahs").
- Quick access from home screen.

## 4) Better Offline Quran Experience

Scope:
- Bulk download manager (audio + tafsir by surah).
- Download status page with progress and file size.
- "Offline ready" badge for cached surahs.

## 5) Daily Reflection Experience

Scope:
- Ayah of the day widget on home screen.
- Optional short tafsir summary card.
- Streak and reminder nudges.

## Implementation Order

1. Hifz Mode MVP
2. Advanced single-ayah controls
3. Bookmarks and collections
4. Offline manager
5. Daily reflection

## Release Checklist Template

Use this checklist for each feature:

- Product behavior defined
- UX states covered (loading/empty/error/offline)
- Local cache behavior validated
- `flutter analyze` passes
- `flutter test` passes
- Docs updated (`README.md` + this file)
