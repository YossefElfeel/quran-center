import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import ts from 'typescript';

// Same pattern as verify-forms: transpile the client-safe lib modules and assert on their pure helpers.
await fs.mkdir('.next/qa',{recursive:true});
for(const file of ['format','action-labels']) {
  const source=await fs.readFile(`lib/${file}.ts`,'utf8');
  const output=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;
  await fs.writeFile(`.next/qa/${file}.mjs`,output);
}
const {pluralAr,referenceNumber,shortRef,formatPhone,personTag,personOptionLabel}=await import('../.next/qa/format.mjs');
const {tableLabel,roleLabel}=await import('../.next/qa/action-labels.mjs');

const users={zero:'مفيش مستخدمين',one:'مستخدم واحد',two:'مستخدمين اتنين',few:'{n} مستخدمين',many:'{n} مستخدم'};
assert.equal(pluralAr(0,users),'مفيش مستخدمين');
assert.equal(pluralAr(1,users),'مستخدم واحد');
assert.equal(pluralAr(2,users),'مستخدمين اتنين');
assert.equal(pluralAr(3,users),'٣ مستخدمين');
assert.equal(pluralAr(10,users),'١٠ مستخدمين');
assert.equal(pluralAr(11,users),'١١ مستخدم');
assert.equal(pluralAr(99,users),'٩٩ مستخدم');
assert.equal(pluralAr(100,users),'١٠٠ مستخدم'); // CLDR "other" falls back to many
assert.equal(pluralAr(103,users),'١٠٣ مستخدمين');
assert.equal(pluralAr(null,users),'مفيش مستخدمين');
const noZero={...users,zero:undefined};
assert.equal(pluralAr(0,noZero),'٠ مستخدم');

// Same algorithm as the mobile app (complaintReferenceNumber / complaintShortReference).
const id='a17d3489-4042-425e-99d3-f811da2edabf';
assert.equal(referenceNumber(id),'A17D3489');
assert.equal(shortRef(id),'#3489');
assert.equal(shortRef('ab-c'),'#ABC');

assert.equal(formatPhone('+201012345678'),'01012345678');
assert.equal(formatPhone('٠١٠ ١٢٣٤ ٥٦٧٨'),'01012345678');
assert.equal(formatPhone(''),null);
assert.equal(personTag({id,phone:null}),'#3489');
assert.equal(personTag({id,phone:'01012345678'}),'01012345678');
assert.equal(personOptionLabel({id,full_name:'حسن يوسف',phone:null},'ولي أمر'),'حسن يوسف — ⁦#3489⁩ (ولي أمر)');

assert.equal(tableLabel('public_registration'),'طلبات التسجيل العام');
assert.equal(tableLabel('certificate_nomination'),'ترشيحات الشهادات');
assert.equal(tableLabel('media'),'الوسائط');
assert.equal(tableLabel('some_new_table'),'some_new_table');
assert.equal(tableLabel(null),'—');
assert.equal(roleLabel('parent'),'ولي أمر');
assert.equal(roleLabel('unknown_role'),'unknown_role');
console.log('Label regressions passed: Arabic plurals (0/1/2/3–10/11–99/100+), mobile-compatible complaint refs, phone tags, table/role label fallbacks.');
