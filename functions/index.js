const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

function asDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

exports.sendAnnouncementPush = onDocumentWritten(
  "announcements/{announcementId}",
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap || !afterSnap.exists) return;

    const after = afterSnap.data() || {};
    if (after.active !== true) return;
    if (after.send_push !== true) return;

    const status = (after.push_status || "").toString().toLowerCase().trim();
    if (status === "sent" || status === "processing") return;

    const ref = afterSnap.ref;
    const fieldValue = admin.firestore.FieldValue;

    await ref.set(
      {
        push_status: "processing",
        push_started_at: fieldValue.serverTimestamp(),
        updated_at: fieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    const latestSnap = await ref.get();
    const latest = latestSnap.data() || {};

    if (latest.active !== true || latest.send_push !== true) {
      logger.info("Push skipped: no longer active/send_push", event.params);
      await ref.set(
        {
          push_status: "idle",
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    const now = new Date();
    const startAt = asDate(latest.start_at);
    const endAt = asDate(latest.end_at);

    if (startAt && now < startAt) {
      logger.info("Push deferred: before start_at", {
        id: event.params.announcementId,
      });
      await ref.set(
        {
          push_status: "pending",
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    if (endAt && now > endAt) {
      logger.info("Push failed: after end_at", {
        id: event.params.announcementId,
      });
      await ref.set(
        {
          push_status: "failed",
          push_error: "Announcement window expired before send.",
          push_failed_at: fieldValue.serverTimestamp(),
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    const topic = (latest.push_topic || "noorify_all").toString().trim();
    const title = (
      latest.title_bn ||
      latest.title_en ||
      "Noorify"
    ).toString();
    const body = (
      latest.message_bn ||
      latest.message_en ||
      "You have a new Noorify update."
    ).toString();

    try {
      const messageId = await admin.messaging().send({
        topic,
        notification: {title, body},
        data: {
          announcement_id: event.params.announcementId.toString(),
          source: "announcement",
          push_topic: topic,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "noorify_general",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      });

      logger.info("Announcement push sent", {
        id: event.params.announcementId,
        topic,
        messageId,
      });

      await ref.set(
        {
          send_push: false,
          push_status: "sent",
          push_sent_at: fieldValue.serverTimestamp(),
          push_error: fieldValue.delete(),
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    } catch (error) {
      logger.error("Announcement push send failed", error);
      await ref.set(
        {
          push_status: "failed",
          push_error: String(error),
          push_failed_at: fieldValue.serverTimestamp(),
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }
  },
);
