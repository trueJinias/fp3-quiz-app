const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendDailyReminder = onRequest(async (req, res) => {
  const secret = req.query.key || req.headers["x-secret-key"];
  if (!secret || secret !== process.env.NOTIFICATION_SECRET) {
    res.status(403).json({ error: "Forbidden" });
    return;
  }

  try {
    const result = await admin.messaging().send({
      topic: "fp3_daily_reminder",
      data: { type: "daily_reminder" },
      android: { priority: "high" },
    });
    res.json({ success: true, messageId: result, timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
