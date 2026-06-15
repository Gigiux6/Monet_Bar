const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json'); // if needed, or default
admin.initializeApp();
const db = admin.firestore();

async function check() {
  const snapshot = await db.collection('rewards').where('isSpecial', '==', true).get();
  snapshot.forEach(doc => {
    console.log(doc.id, '=>', doc.data().terms);
  });
}
check();
