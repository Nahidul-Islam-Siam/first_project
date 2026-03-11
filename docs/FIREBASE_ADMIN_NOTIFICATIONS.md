# Noorify Firebase Admin + Notification Guide

Last updated: March 11, 2026

## 1) Current Setup

- Firebase Auth is connected.
- User profile is auto-created in Firestore on sign-in:
  - `users/{uid}`
  - default role: `user`
- Admin announcement backend is added:
  - `announcements` collection
- In-app Admin Panel is available for admin users.
- Home screen reads active announcement and can show modal.
- Firebase Cloud Messaging (FCM) client is connected in app.
- App subscribes devices to topic: `noorify_all`.
- Foreground push is shown via local notification banner.
- Admin panel now includes `Send push notification` toggle.

## 2) Notification Types

### A) Local scheduled notifications

- Prayer/sehri/iftar alerts from device schedule.
- Works without backend.

### B) In-app modal announcements

- Admin creates announcement in Firestore.
- User opens app -> Home checks active modal announcement.
- If active and within time window, modal appears.

### C) Push notification (FCM)

- For app closed/background delivery.
- Uses FCM topic broadcast (`noorify_all`).

## 3) Admin Account Meaning

Admin is a normal Firebase user with Firestore role set to admin.

- Collection: `users`
- Document: `{uid}`
- Field: `role = "admin"`

If role is not admin, user cannot access Admin Panel.

## 4) Firestore Schema

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
  "title_bn": "Bangla title",
  "message_bn": "Bangla message",
  "title_en": "English title",
  "message_en": "English message",
  "poster_url": "https://...",
  "active": true,
  "show_modal": true,
  "send_push": false,
  "push_topic": "noorify_all",
  "push_status": "pending | processing | sent | failed",
  "push_requested_at": "timestamp or null",
  "push_sent_at": "timestamp or null",
  "push_error": "string or null",
  "start_at": "timestamp or null",
  "end_at": "timestamp or null",
  "created_by_uid": "admin uid",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## 5) Special Day Campaign Example (Dhul Hijjah / Hajj)

1. Sign in with admin account.
2. Open `Profile -> Admin Panel`.
3. Click `Add Announcement`.
4. Fill title + message.
5. Turn on:
   - `active`
   - `show modal`
   - `send push notification` (if push also needed)
6. Set optional start/end window.
7. Save.

Result:
- Modal will show on app open.
- Push will be queued for backend trigger send.

## 6) Recommended Firestore Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() {
      return request.auth != null;
    }

    function isFixedAdmin() {
      return signedIn() &&
        request.auth.uid in [
          "W3lIUYSpuoTkRe3seRLNfQ8we1o1",
          "zgegjJnv0PZL8db3b08OQPug3393"
        ];
    }

    function isOwner(uid) {
      return signedIn() && request.auth.uid == uid;
    }

    match /users/{uid} {
      allow read: if isOwner(uid) || isFixedAdmin();
      allow create: if isOwner(uid)
        && request.resource.data.uid == request.auth.uid
        && request.resource.data.role == "user";
      allow update: if (
          isOwner(uid)
          && request.resource.data.uid == resource.data.uid
          && request.resource.data.role == resource.data.role
        ) || isFixedAdmin();
      allow delete: if isFixedAdmin();
    }

    match /announcements/{docId} {
      allow read: if true;
      allow create, update, delete: if isFixedAdmin();
    }
  }
}
```

## 7) Push from Firebase Console (Manual Broadcast)

1. Firebase Console -> Messaging
2. Create notification campaign
3. Target = Topic
4. Topic = `noorify_all`
5. Publish

Result:
- Background/closed app receives push.
- Foreground app shows local banner.

## 8) Campaign-Driven Push from Admin Panel

Cloud Function scaffold is added in repo:

- `functions/index.js`
- `functions/package.json`

### Flow

1. Admin panel save with `send_push = true`.
2. Firestore trigger sees pending announcement.
3. Function sends FCM topic push.
4. Function updates:
   - `push_status: sent` on success
   - `push_status: failed` + `push_error` on failure

## 9) Deploy Functions (One-time Setup)

From project root:

1. `cd functions`
2. `npm install`
3. `cd ..`
4. `firebase deploy --only functions`

After this, admin panel `send_push` toggle will trigger actual push delivery.
