import { z } from "zod";
import { idSchema, nameSchema, normalizeNumber, validationError } from "./validation";

const reason = z.string().trim().min(1, "اكتب السبب").max(2000, "السبب أطول من اللازم");
const text = z.string().trim().max(4000, "النص أطول من اللازم");
const optionalId = z.union([idSchema, z.literal("")]).optional();
const bool = z.enum(["true", "false"], { error: "اختار حالة صحيحة" });
const amount = z.preprocess(v => v === "" || v == null ? NaN : Number(normalizeNumber(String(v))), z.number().finite().min(0, "المبلغ لازم يكون صفر أو أكتر").max(1000000, "راجع المبلغ").refine(value => Math.abs(value*100-Math.round(value*100))<0.000001,"المبلغ فيه أكتر من رقمين بعد العلامة"));
const capacity = z.preprocess(v => v == null ? 30 : v === "" ? NaN : Number(normalizeNumber(String(v))), z.number().int("اكتب عددًا صحيحًا").min(1, "الحد الأدنى طالب واحد").max(1000, "راجع الحد الأقصى"));
const gender = z.enum(["male", "female"], { error: "اختار النوع" });
const roles = z.enum(["super_admin", "admin", "supervisor", "teacher", "parent"]);
const circleStatus = z.enum(["forming", "active", "graduated"]);
const enrollmentStatus = z.enum(["active", "paused", "graduated", "dropped", "transferred"]);
const ids = z.object({ id: idSchema });
const operator = { target_person_id: idSchema };
const table = z.string().regex(/^[a-z][a-z0-9_]*$/, "اختار جدولًا صحيحًا").max(63);
const jsonObject = z.string().max(100000, "البيانات أكبر من اللازم").refine(value => {
  if (!value.trim()) return true;
  try { const parsed = JSON.parse(value); return parsed !== null && typeof parsed === "object" && !Array.isArray(parsed); } catch { return false; }
}, "اكتب كائن JSON صحيحًا");

// Each action validates its own public form contract before requesting a data client.
// The database and Edge functions still enforce the caller's permissions.
export const actionSchemas = {
  createCurriculum: z.object({ name: nameSchema, type: z.enum(["quran", "arabic_foundation"]) }),
  deleteCurriculum: ids,
  createLevel: z.object({ curriculum_id: idSchema, name: nameSchema }),
  deleteLevel: ids.extend({ curriculum_id: idSchema }),
  createCircle: z.object({ level_id: idSchema, curriculum_id: idSchema, name: nameSchema, teacher_id: optionalId, max_size: capacity }),
  updateCircle: ids.extend({ level_id: idSchema, curriculum_id: idSchema, teacher_id: optionalId, status: circleStatus.optional(), max_size: capacity.optional() }),
  deleteCircle: ids.extend({ level_id: idSchema, curriculum_id: idSchema }),
  addApplicant: z.object({ name: nameSchema, gender, level_id: idSchema }),
  recordPlacement: z.object({ waiting_id: idSchema, student_person_id: idSchema, result_level_id: idSchema, notes: text.optional() }),
  enrollFromWaiting: z.object({ waiting_id: idSchema, student_person_id: idSchema, circle_id: idSchema }),
  setWaitingStatus: ids.extend({ status: z.enum(["waiting", "offered", "accepted", "declined", "expired"]) }),
  enrollStudent: z.object({ circle_id: idSchema, name: nameSchema, gender, national_id: z.string().refine(value => !value.trim() || /^\d{14}$/.test(normalizeNumber(value.trim())), "الرقم القومي لازم يكون ١٤ رقم").optional() }),
  updateEnrollment: ids.extend({ circle_id: idSchema.optional(), status: enrollmentStatus.optional() }),
  deleteEnrollment: ids,
  bulkEnroll: z.object({ circle_id: idSchema, rows: z.string().trim().min(1, "اكتب أسماء الطلاب").max(25000, "الحد الأقصى ١٠٠ اسم").refine(value => value.split(/\r?\n/).filter(v => v.trim()).length <= 100, "الحد الأقصى ١٠٠ اسم") }),
  correctLedger: z.object({ student_person_id: idSchema, portion_id: idSchema, circle_id: idSchema, state: z.enum(["assigned", "failed_retry", "passed"]) }),
  addBehavioralNote: z.object({ student_person_id: idSchema, circle_id: idSchema, text: text.min(1, "اكتب الملاحظة"), visibility: z.enum(["parent", "internal"]) }),
  deleteBehavioralNote: ids.extend({ circle_id: idSchema }),
  createHousehold: z.object({ name: nameSchema, monthly_amount: amount }),
  recordPayment: z.object({ household_id: idSchema, amount, period_month: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/, "اختار شهرًا صحيحًا"), method: z.enum(["cash", "instapay", "other"]) }),
  voidPayment: ids.extend({ reason }),
  addMember: z.object({ household_id: idSchema, person_id: idSchema, role: z.enum(["guardian", "student"]) }),
  removeMember: ids.extend({ household_id: idSchema }),
  broadcast: z.object({ audience: z.enum(["all", "super_admin", "admin", "supervisor", "teacher", "parent"]), title: nameSchema, body: text.optional() }),
  retractNotification: ids,
  issueCertificate: z.object({ student_person_id: idSchema, kind: z.enum(["juz_amma", "half", "full", "honor"]) }),
  revokeCertificate: ids,
  approveDevelopment: ids,
  approveMonthlyEval: ids,
  returnEvaluation: ids.extend({ table: z.enum(["teacher_development", "monthly_student_evaluation"]), reason }),
  setRatingHidden: ids.extend({ hidden: bool }),
  decideExcuse: ids.extend({ decision: z.enum(["approved", "rejected"]), enrollment_id: optionalId, session_id: optionalId }),
  setMediaRetained: ids.extend({ retained: bool }),
  deleteMedia: ids,
  deleteCourse: ids,
  deleteCompetition: ids,
  setCompetitionStatus: ids.extend({ status: z.enum(["draft", "open", "judging", "closed"]) }),
  setApplicationStatus: ids.extend({ competition_id: idSchema, status: z.enum(["accepted", "rejected"]) }),
  inviteUser: z.object({ email: z.email({ error: "اكتب إيميلًا صحيحًا" }), full_name: nameSchema, role: z.enum(["teacher", "supervisor", "admin"]) }),
  blockUser: z.object({ ...operator, block: bool, reason: text.optional() }).refine(data => data.block !== "true" || !!data.reason, { path: ["reason"], error: "اكتب سبب الحظر" }),
  deleteUser: z.object({ ...operator, mode: z.enum(["soft", "restore", "hard"]), reason: text.optional(), confirm: text.optional() }).refine(data => data.mode === "restore" || !!data.reason, { path: ["reason"], error: "اكتب السبب" }),
  manageRole: z.object({ ...operator, role: roles, op: z.enum(["grant", "revoke"]) }),
  forceLogout: z.object({ ...operator, reason }),
  resetPassword: z.object({ ...operator, reason }),
  toggleFlag: z.object({ key: table, enabled: bool, reason }),
  setCronActive: z.object({ jobname: z.string().min(1).max(200), active: bool, reason }),
  runCronNow: z.object({ jobname: z.string().min(1).max(200), reason }),
  deleteRow: ids.extend({ table, reason }),
  writeJson: z.object({ table, op: z.enum(["insert", "update", "delete"]), reason, payload: jsonObject.optional(), match: jsonObject.optional() }).refine(data => {
    if(data.op === "insert") return true;
    try { return !!data.match?.trim() && Object.keys(JSON.parse(data.match)).length > 0; } catch { return false; }
  }, { path: ["match"], error: "اكتب شرطًا يحدد الصفوف المطلوبة" }),
} as const;

export function validateAction(name: keyof typeof actionSchemas, data: FormData) {
  return validationError(actionSchemas[name].safeParse(Object.fromEntries(data), {error:()=>"راجع قيمة الحقل"}));
}
