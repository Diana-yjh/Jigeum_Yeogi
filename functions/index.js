// 지금여기 — 등하원 시 학부모에게 FCM 푸시 발송.
// attendance/{studentId}_{date} 문서의 checkInAt/checkOutAt 변화를 감지해
// 해당 학생의 학부모(users.fcmToken)에게 알림을 보낸다.

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

exports.onAttendanceWrite = onDocumentWritten(
  {document: "attendance/{docId}", region: "asia-northeast3"},
  async (event) => {
    const after = event.data && event.data.after && event.data.after.data();
    if (!after) return; // 삭제된 경우
    const before =
      (event.data && event.data.before && event.data.before.data()) || {};

    // 등원/하원 '새로 생김'만 알림 (초기화·수정은 제외).
    let type = null;
    if (!before.checkInAt && after.checkInAt) type = "checkin";
    else if (!before.checkOutAt && after.checkOutAt) type = "checkout";
    if (!type) return;

    const parentUid = after.parentUid;
    if (!parentUid) return;

    const db = getFirestore();
    const userSnap = await db.collection("users").doc(parentUid).get();
    const user = userSnap.data();
    if (!user || !user.fcmToken) return;

    // 학부모 알림 설정 존중(기본 on).
    if (type === "checkin" && user.notifyCheckIn === false) return;
    if (type === "checkout" && user.notifyCheckOut === false) return;

    const studentSnap = await db
      .collection("students")
      .doc(after.studentId)
      .get();
    const name = (studentSnap.data() && studentSnap.data().name) || "우리 아이";

    const title = type === "checkin" ? "등원 알림" : "하원 알림";
    const body =
      type === "checkin"
        ? `${name} 학생이 등원했어요.`
        : `${name} 학생이 하원했어요.`;

    await getMessaging().send({
      token: user.fcmToken,
      notification: {title, body},
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    });
  }
);
