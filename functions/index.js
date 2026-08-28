// 지금여기 — 등하원 시 학부모에게 FCM 푸시 발송.
// attendance/{studentId}_{date} 문서의 checkInAt/checkOutAt 변화를 감지해
// 해당 학생의 학부모(users.fcmToken)에게 알림을 보낸다.

const {onDocumentWritten, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const functionsV1 = require("firebase-functions/v1");
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

// 회원탈퇴(Auth 계정 삭제) 시 Firestore 데이터 정리.
exports.onUserDelete = functionsV1.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const db = getFirestore();

  const userSnap = await db.collection("users").doc(uid).get();
  const data = userSnap.data() || {};
  const batch = db.batch();

  // 학부모: 자녀 학생 + 그 출석 기록 삭제.
  if (data.role === "parent") {
    const students = await db
      .collection("students")
      .where("parentUid", "==", uid)
      .get();
    students.forEach((d) => batch.delete(d.ref));
    const att = await db
      .collection("attendance")
      .where("parentUid", "==", uid)
      .get();
    att.forEach((d) => batch.delete(d.ref));
  }

  // 선생님: 반 코드 + 소속 학생 + 출석 기록 삭제.
  if (data.role === "teacher" && data.teacherCode) {
    batch.delete(db.collection("teachers").doc(data.teacherCode));
    const students = await db
      .collection("students")
      .where("teacherCode", "==", data.teacherCode)
      .get();
    students.forEach((d) => batch.delete(d.ref));
    const att = await db
      .collection("attendance")
      .where("teacherCode", "==", data.teacherCode)
      .get();
    att.forEach((d) => batch.delete(d.ref));
  }

  batch.delete(db.collection("users").doc(uid));
  await batch.commit();
});

// 학생 삭제 시 그 학생의 출결 기록 정리.
exports.onStudentDelete = onDocumentDeleted(
  {document: "students/{studentId}", region: "asia-northeast3"},
  async (event) => {
    const studentId = event.params.studentId;
    const db = getFirestore();
    const att = await db
      .collection("attendance")
      .where("studentId", "==", studentId)
      .get();
    if (att.empty) return;
    const batch = db.batch();
    att.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
);
