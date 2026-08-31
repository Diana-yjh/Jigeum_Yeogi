// seed_attendance.js 가 만든 더미 출결(seeded: true)만 삭제한다.
//
//   GOOGLE_APPLICATION_CREDENTIALS=~/.config/jigeum/serviceAccount.json \
//     node functions/scripts/unseed_attendance.js

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp({credential: applicationDefault(), projectId: "jigeum-yeogi-25737"});
const db = getFirestore();

async function main() {
  const snap = await db.collection("attendance").where("seeded", "==", true).get();
  console.log(`더미 출결 ${snap.size}건`);
  for (let i = 0; i < snap.docs.length; i += 400) {
    const batch = db.batch();
    snap.docs.slice(i, i + 400).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
  console.log("삭제 완료.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
