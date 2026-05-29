const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// Listener per l'invio manuale delle notifiche
exports.sendManualNotification = onDocumentCreated(
  {
    document: "notification_requests/{reqId}"
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return null;
    }

    const data = snapshot.data();

    const payload = {
      notification: {
        title: "Nuova Novità: " + (data.titolo || "Aggiornamento Monet Bar"),
        body: data.contenuto || "Scopri le ultime novità nella nostra app!",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "news",
      },
      topic: "all_users",
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log("Successfully sent manual notification to all_users:", response);
      // Puliamo la richiesta dopo averla evasa
      await snapshot.ref.delete();
    } catch (error) {
      console.error("Error sending notification:", error);
    }
    return null;
  }
);