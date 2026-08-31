// 더미 출결 데이터 생성 스크립트 (개발·테스트용)
//
// 등록된 모든 학생에 대해 최근 N주간, 각 학생의 스케줄 요일에 맞춰
// 등원/하원 기록을 만든다. 오늘·미래는 건드리지 않고, 이미 있는 기록은 덮어쓰지 않는다.
//
// 사용법 (프로젝트 루트에서):
//   GOOGLE_APPLICATION_CREDENTIALS=~/.config/jigeum/serviceAccount.json \
//     node functions/scripts/seed_attendance.js            # 실제 기록
//   node functions/scripts/seed_attendance.js --dry-run     # 쓰지 않고 계획만 출력
//   node functions/scripts/seed_attendance.js --weeks=4     # 기간 변경(기본 3주)
//
// 주의: attendance 생성은 onAttendanceWrite 트리거를 깨워 학부모 푸시를 보낸다.
// 그래서 기록 전에 학부모의 알림 설정(notifyCheckIn/notifyCheckOut)을 잠시 끄고,
// 기록이 끝난 뒤 원래 값으로 되돌린다. (기본값 true인 필드라 없으면 삭제로 복구)

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore, Timestamp, FieldValue} = require("firebase-admin/firestore");

const args = process.argv.slice(2);
const DRY = args.includes("--dry-run");
const WEEKS = Number((args.find((a) => a.startsWith("--weeks=")) || "--weeks=3").split("=")[1]);
const PROJECT = "jigeum-yeogi-25737";

initializeApp({credential: applicationDefault(), projectId: PROJECT});
const db = getFirestore();

const WEEKDAY = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];

// 고정 시드 난수 — 다시 돌려도 같은 결과.
let seed = 20260831;
function rnd() {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return seed / 0x7fffffff;
}

function dateKey(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function at(d, hhmm, minuteOffset) {
  const [h, m] = hhmm.split(":").map(Number);
  const t = new Date(d);
  t.setHours(h, m + minuteOffset, Math.floor(rnd() * 60), 0);
  return t;
}

async function main() {
  const students = (await db.collection("students").get()).docs
    .map((d) => ({id: d.id, ...d.data()}));
  if (students.length === 0) {
    console.log("students 컬렉션이 비어 있어요.");
    return;
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const start = new Date(today);
  start.setDate(start.getDate() - WEEKS * 7);

  // 1) 계획 세우기
  const plans = [];
  for (const s of students) {
    const schedule = s.schedule || {};
    const days = Object.keys(schedule).length > 0 ? schedule
      // 스케줄이 없으면 월·수·금 15:00 로 가정
      : {mon: {time: "15:00"}, wed: {time: "15:00"}, fri: {time: "15:00"}};

    for (let d = new Date(start); d < today; d.setDate(d.getDate() + 1)) {
      const code = WEEKDAY[d.getDay()];
      const entry = days[code];
      if (!entry) continue;
      if (rnd() < 0.12) continue; // 가끔 결석

      const time = (typeof entry === "string" ? entry : entry.time) || "15:00";
      const checkIn = at(d, time, Math.round(rnd() * 16 - 6)); // -6 ~ +10분
      const stay = 80 + Math.round(rnd() * 70); // 80 ~ 150분 체류
      const checkOut = new Date(checkIn.getTime() + stay * 60 * 1000);
      // 아주 가끔 하원 미체크
      const hasOut = rnd() > 0.06;

      plans.push({
        id: `${s.id}_${dateKey(d)}`,
        data: {
          studentId: s.id,
          teacherCode: s.teacherCode,
          parentUid: s.parentUid || null,
          date: dateKey(d),
          checkInAt: Timestamp.fromDate(checkIn),
          ...(hasOut ? {checkOutAt: Timestamp.fromDate(checkOut)} : {}),
          status: "present",
          updatedAt: FieldValue.serverTimestamp(),
          seeded: true, // 나중에 한 번에 지울 수 있게 표시
        },
        label: `${s.name} ${dateKey(d)} ${time}→${hasOut ? "+" + stay + "분" : "하원 미체크"}`,
      });
    }
  }

  // 2) 이미 있는 기록 제외
  const existing = new Set();
  for (let i = 0; i < plans.length; i += 100) {
    const refs = plans.slice(i, i + 100).map((p) => db.collection("attendance").doc(p.id));
    const snaps = await db.getAll(...refs);
    snaps.forEach((s) => s.exists && existing.add(s.id));
  }
  const toWrite = plans.filter((p) => !existing.has(p.id));

  console.log(`학생 ${students.length}명 / 기간 ${dateKey(start)} ~ 어제`);
  console.log(`계획 ${plans.length}건, 이미 있음 ${existing.size}건, 새로 기록 ${toWrite.length}건`);
  for (const p of toWrite.slice(0, 12)) console.log("  ·", p.label);
  if (toWrite.length > 12) console.log(`  · … 외 ${toWrite.length - 12}건`);
  if (DRY || toWrite.length === 0) return;

  // 3) 학부모 알림 잠시 끄기 (푸시 폭주 방지)
  const parentUids = [...new Set(students.map((s) => s.parentUid).filter(Boolean))];
  const restore = [];
  for (const uid of parentUids) {
    const ref = db.collection("users").doc(uid);
    const snap = await ref.get();
    if (!snap.exists) continue;
    const u = snap.data();
    restore.push({ref, notifyCheckIn: u.notifyCheckIn, notifyCheckOut: u.notifyCheckOut});
    await ref.set({notifyCheckIn: false, notifyCheckOut: false}, {merge: true});
  }
  console.log(`학부모 ${restore.length}명 알림 임시 OFF`);

  // 4) 기록 (배치 400건 단위)
  for (let i = 0; i < toWrite.length; i += 400) {
    const batch = db.batch();
    for (const p of toWrite.slice(i, i + 400)) {
      batch.set(db.collection("attendance").doc(p.id), p.data);
    }
    await batch.commit();
    console.log(`  기록 ${Math.min(i + 400, toWrite.length)}/${toWrite.length}`);
  }

  // 5) 트리거가 지나가길 기다렸다가 알림 설정 복구
  console.log("트리거 처리 대기 20초…");
  await new Promise((r) => setTimeout(r, 20000));
  for (const r of restore) {
    await r.ref.set({
      notifyCheckIn: r.notifyCheckIn === undefined ? FieldValue.delete() : r.notifyCheckIn,
      notifyCheckOut: r.notifyCheckOut === undefined ? FieldValue.delete() : r.notifyCheckOut,
    }, {merge: true});
  }
  console.log("알림 설정 복구 완료. 끝.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
