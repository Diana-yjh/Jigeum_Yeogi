// 스토어 심사용 테스트 계정 생성 (선생님 1 + 학부모 1 + 자녀 "김테스트").
// 앱의 회원가입이 쓰는 문서 구조와 동일하게 만든다(auth_repository.dart 참고).
// 다시 실행해도 안전하다: 이미 있으면 비밀번호만 초기화하고 문서는 보강한다.
//
//   GOOGLE_APPLICATION_CREDENTIALS=~/.config/jigeum/serviceAccount.json \
//     node functions/scripts/create_review_accounts.js

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");

const PROJECT = "jigeum-yeogi-25737";
const DOMAIN = "jigeumyeogi.test";
const TEACHER = {email: `review.teacher@${DOMAIN}`, password: "Review-Teacher-2026", name: "김선생"};
const PARENT = {email: `review.parent@${DOMAIN}`, password: "Review-Parent-2026", name: "홍학부모"};
const CHILD = {name: "김테스트", schedule: {mon: "15:00", wed: "15:00", fri: "15:00"}};

initializeApp({credential: applicationDefault(), projectId: PROJECT});
const auth = getAuth();
const db = getFirestore();

async function upsertUser({email, password, name}) {
  try {
    const u = await auth.getUserByEmail(email);
    await auth.updateUser(u.uid, {password, displayName: name, emailVerified: true});
    return {uid: u.uid, created: false};
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    const u = await auth.createUser({email, password, displayName: name, emailVerified: true});
    return {uid: u.uid, created: true};
  }
}

async function issueTeacherCode(uid) {
  // 이미 발급된 코드가 있으면 재사용.
  const existing = await db.collection("teachers").where("uid", "==", uid).limit(1).get();
  if (!existing.empty) return existing.docs[0].id;
  for (let i = 0; i < 8; i++) {
    const code = String(Math.floor(Math.random() * 900000) + 100000);
    const ref = db.collection("teachers").doc(code);
    const ok = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return false;
      tx.set(ref, {uid, academyName: null, classes: [], createdAt: FieldValue.serverTimestamp()});
      return true;
    });
    if (ok) return code;
  }
  throw new Error("코드 발급 실패");
}

function dateKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

async function main() {
  // 1) 선생님
  const t = await upsertUser(TEACHER);
  const code = await issueTeacherCode(t.uid);
  await db.collection("users").doc(t.uid).set({
    role: "teacher", name: TEACHER.name, email: TEACHER.email, teacherCode: code,
    createdAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  // 2) 학부모
  const p = await upsertUser(PARENT);
  await db.collection("users").doc(p.uid).set({
    role: "parent", name: PARENT.name, email: PARENT.email, teacherCode: code,
    createdAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  // 3) 자녀 (같은 이름이 이미 연결돼 있으면 재사용)
  const kids = await db.collection("students")
    .where("parentUid", "==", p.uid).where("name", "==", CHILD.name).limit(1).get();
  const childRef = kids.empty ? db.collection("students").doc() : kids.docs[0].ref;
  const schedule = Object.fromEntries(
    Object.entries(CHILD.schedule).map(([d, time]) => [d, {time, type: "regular"}]));
  await childRef.set({
    name: CHILD.name, teacherCode: code, parentUid: p.uid, classId: null,
    schedule, scheduledDays: Object.keys(CHILD.schedule),
    createdAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  // 4) 지난 2주 수업일에 출결 기록 몇 건 (달력·주간 카드가 비어 보이지 않게). 오늘은 비워 둔다.
  const WEEKDAY = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
  const today = new Date(); today.setHours(0, 0, 0, 0);
  const batch = db.batch(); let n = 0;
  for (let i = 14; i >= 1; i--) {
    const d = new Date(today); d.setDate(d.getDate() - i);
    const time = CHILD.schedule[WEEKDAY[d.getDay()]];
    if (!time) continue;
    const [h, m] = time.split(":").map(Number);
    const inAt = new Date(d); inAt.setHours(h, m + 3, 0, 0);
    const outAt = new Date(inAt.getTime() + 110 * 60 * 1000);
    batch.set(db.collection("attendance").doc(`${childRef.id}_${dateKey(d)}`), {
      studentId: childRef.id, teacherCode: code, parentUid: p.uid, date: dateKey(d),
      checkInAt: Timestamp.fromDate(inAt), checkOutAt: Timestamp.fromDate(outAt),
      status: "present", updatedAt: FieldValue.serverTimestamp(), seeded: true,
    }, {merge: true});
    n++;
  }
  // 학부모 알림이 심사 계정으로 가진 않지만(토큰 없음) 혹시 몰라 잠시 끈다.
  await db.collection("users").doc(p.uid).set({notifyCheckIn: false, notifyCheckOut: false}, {merge: true});
  await batch.commit();
  await new Promise((r) => setTimeout(r, 5000));
  await db.collection("users").doc(p.uid).set({notifyCheckIn: FieldValue.delete(), notifyCheckOut: FieldValue.delete()}, {merge: true});

  console.log("=== 심사용 계정 ===");
  console.log(`선생님  ${TEACHER.email}  /  ${TEACHER.password}   (${t.created ? "새로 생성" : "기존 계정, 비밀번호 초기화"})`);
  console.log(`학부모  ${PARENT.email}  /  ${PARENT.password}   (${p.created ? "새로 생성" : "기존 계정, 비밀번호 초기화"})`);
  console.log(`선생님 코드  ${code}`);
  console.log(`자녀  ${CHILD.name} (월·수·금 15:00)  지난 출결 ${n}건`);
}

main().catch((e) => { console.error(e); process.exit(1); });
