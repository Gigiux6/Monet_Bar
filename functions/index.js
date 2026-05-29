const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// Usiamo la sintassi Gen 2 che supporta nativamente i database eur3 senza conflitti
exports.sendNewsNotification = onDocumentCreated(
  {
    document: "news/{newsId}"
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return null;
    }

    const data = snapshot.data();

    // Se is_active è false fin dall'inizio, saltiamo l'invio
    if (data.is_active === false) {
      console.log("News is not active, skipping notification.");
      return null;
    }

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
      console.log("Successfully sent notification to all_users:", response);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
    return null;
  }
);