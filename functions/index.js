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

const { onSchedule } = require("firebase-functions/v2/scheduler");

exports.dailyMarketingAutomation = onSchedule(
  {
    schedule: "30 08 * * *", // 08:30 every day
    timeZone: "Europe/Rome"
  },
  async (event) => {
    try {
      const now = new Date();
      
      const getMmDd = (date) => {
        const formatter = new Intl.DateTimeFormat('en-US', {
          timeZone: 'Europe/Rome',
          month: '2-digit',
          day: '2-digit'
        });
        const formatted = formatter.format(date);
        return `${formatted.split('/')[0]}-${formatted.split('/')[1]}`;
      };

      const todayMmDd = getMmDd(now);
      
      const inThreeDays = new Date(now);
      inThreeDays.setDate(inThreeDays.getDate() + 3);
      const targetMmDd = getMmDd(inThreeDays);

      console.log(`Running marketing automation. Today: ${todayMmDd}, In 3 days: ${targetMmDd}`);

      const usersRef = admin.firestore().collection("users");
      const snapshot = await usersRef.where("recurringDatesMmDd", "array-contains-any", [todayMmDd, targetMmDd]).get();

      if (snapshot.empty) {
        console.log("No users with special dates today or in 3 days.");
        return;
      }

      const messaging = admin.messaging();

      for (const doc of snapshot.docs) {
        const user = doc.data();
        const importantDates = user.importantDates || {};
        
        const checkAndSend = async (dateValue, tagPrefix, titleToday, bodyToday, titleSoon, bodySoon) => {
           if (!dateValue) return;
           if (dateValue.endsWith(todayMmDd)) {
             await messaging.send({
                notification: { title: titleToday, body: bodyToday },
                data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "special_reward" },
                android: { notification: { tag: `${tagPrefix}_today` } },
                topic: `user_${doc.id}`,
             });
             console.log(`Sent TODAY notification to ${doc.id}`);
           } else if (dateValue.endsWith(targetMmDd)) {
             await messaging.send({
                notification: { title: titleSoon, body: bodySoon },
                data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "special_reward" },
                android: { notification: { tag: `${tagPrefix}_soon` } },
                topic: `user_${doc.id}`,
             });
             console.log(`Sent 3-DAYS-BEFORE notification to ${doc.id}`);
           }
        };

        await checkAndSend(
          importantDates.birthday, "birthday",
          "Buon Compleanno! 🎂", "Oggi è il tuo giorno speciale. Abbiamo sbloccato un regalo esclusivo per te nella sezione Premi. Vieni a trovarci!",
          "Manca poco al tuo compleanno! 🎁", "Tra 3 giorni sarà il tuo compleanno! Preparati, abbiamo una sorpresa in serbo per te nell'app."
        );

        await checkAndSend(
          importantDates.nameDay, "nameday",
          "Buon Onomastico! 🎉", "Tanti auguri! Abbiamo un regalo per il tuo onomastico nella sezione Premi. Ti aspettiamo!",
          "L'onomastico si avvicina! 🎈", "Tra 3 giorni sarà il tuo onomastico! Ti aspetta un regalo speciale da Monet."
        );

        await checkAndSend(
          importantDates.anniversary, "anniversary",
          "Felice Anniversario! ❤️", "Festeggia questo giorno speciale con un regalo offerto da Monet. Scoprilo nell'app!",
          "Anniversario in vista! 🥂", "Il tuo anniversario è tra 3 giorni! Abbiamo preparato una sorpresa per celebrare insieme."
        );
      }
    } catch (err) {
      console.error("Error in dailyMarketingAutomation:", err);
    }
  }
);