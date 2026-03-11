# Noorify Firebase Admin + Notification Guide

Last updated: 11 March 2026

## 1) What we set up now

- Firebase Auth is connected.
- User profile auto-creates in Firestore on sign in:
  - `users/{uid}`
  - default role: `user`
- Admin announcement backend is added:
  - `announcements` collection
- In-app Admin Panel is added in app (Profile -> Admin Panel) for admin users.
- Home screen can show a modal announcement (title + message + poster URL) from Firestore.

## 2) Notification types in Noorify

### A) Local scheduled notification (already in app)

- Prayer/sehri/iftar alerts from phone schedule.
- Works without backend.

### B) In-app modal announcement (newly added)

- Admin creates announcement in Firestore.
- User opens app -> Home checks latest active modal announcement.
- If active and time window is valid, popup shows.

### C) Push notification (future step)

- Requires Firebase Cloud Messaging (FCM).
- Needed when you want users to get alert without opening app.

## 3) “Admin account” means what?

Admin account = normal Firebase user account, but Firestore role is admin.

Set this in Firestore:

- Collection: `users`
- Document: `{uid}`
- Field: `role = "admin"`

If role is not admin, user cannot use in-app Admin Panel.

## 4) Firestore schema used

### `users/{uid}`

```json
{
  "uid": "user uid",
  "email": "user@email.com",
  "display_name": "Name",
  "photo_url": "https://...",
  "role": "user",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "last_sign_in_at": "timestamp"
}
```

### `announcements/{docId}`

```json
{
  "title_bn": "বাংলা শিরোনাম",
  "message_bn": "বাংলা মেসেজ",
  "title_en": "English title",
  "message_en": "English message",
  "poster_url": "https://...",
  "active": true,
  "show_modal": true,
  "start_at": "timestamp or null",
  "end_at": "timestamp or null",
  "created_by_uid": "admin uid",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## 5) How to publish a special day alert (example: 10 Dhul Hijjah / Hajj)

1. Sign in with admin account.
2. Open `Profile -> Admin Panel`.
3. Click `Add Announcement`.
4. Add:
   - Bangla title + message
   - optional English title + message
   - poster URL
   - `active = true`
   - `show modal = true`
   - start/end time window
5. Save.

Users will see this modal when they open Home during active window.

## 6) Recommended Firestore rules (minimum)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /announcements/{docId} {
      allow read: if true;
      allow write: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }
  }
}
```

## 7) Push from outside (future)

To send push from outside app:

1. Add FCM in Flutter app.
2. Save device FCM token in Firestore (per user/device).
3. Use Firebase Cloud Function or admin server endpoint.
4. Admin panel form -> writes campaign doc.
5. Cloud Function reads campaign and sends push to tokens.

This is for “app closed” notification delivery.

