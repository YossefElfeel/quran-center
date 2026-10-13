import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import ts from 'typescript';

await fs.mkdir('.next/qa',{recursive:true});
for(const file of ['validation','action-schemas']) {
  const source=await fs.readFile(`lib/${file}.ts`,'utf8');
  const output=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText.replace('"./validation"','"./validation.mjs"');
  await fs.writeFile(`.next/qa/${file}.mjs`,output);
}
const {validateAction}=await import('../.next/qa/action-schemas.mjs');
const {cairoDateTime}=await import('../.next/qa/validation.mjs');
const id='a17d3489-4042-425e-99d3-f811da2edabf';
const validate=(action,values)=>{const data=new FormData();for(const [key,value] of Object.entries(values))data.set(key,value);return validateAction(action,data)};
const payment={household_id:id,amount:'٢٥٫٥٠',period_month:'2026-10',method:'cash'};
assert.equal(validate('recordPayment',payment),null);
for(const amount of ['', '-1','not-a-number','12.345'])assert.ok(validate('recordPayment',{...payment,amount})?.fieldErrors.amount);
assert.ok(validate('recordPayment',{...payment,period_month:'2026-13'})?.fieldErrors.period_month);
assert.ok(validate('recordPayment',{...payment,household_id:'wrong'})?.fieldErrors.household_id);
assert.ok(validate('blockUser',{target_person_id:id,block:'true',reason:' '})?.fieldErrors.reason);
assert.equal(validate('blockUser',{target_person_id:id,block:'false'}),null);
assert.ok(validate('manageRole',{target_person_id:id,role:'invented',op:'grant'})?.fieldErrors.role);
assert.ok(validate('inviteUser',{email:'bad',full_name:'a',role:'parent'})?.fieldErrors.email);
assert.equal(validate('enrollStudent',{circle_id:id,name:'أحمد محمد',gender:'male',national_id:'٢٩٠٠١٠١٠١٠٠٠١١'}),null);
assert.ok(validate('enrollStudent',{circle_id:id,name:'أحمد محمد',gender:'male',national_id:'123'})?.fieldErrors.national_id);
for(const match of ['','{}','{broken','[]'])assert.ok(validate('writeJson',{table:'person',op:'update',reason:'تصحيح',payload:'{}',match})?.fieldErrors.match);
assert.equal(validate('writeJson',{table:'person',op:'update',reason:'تصحيح',payload:'{}',match:JSON.stringify({id})}),null);
assert.equal(cairoDateTime('2026-01-15T12:00'),'2026-01-15T10:00:00.000Z');
assert.equal(cairoDateTime('2026-07-15T12:00'),'2026-07-15T09:00:00.000Z');
assert.equal(cairoDateTime('not-a-date'),null);
console.log('Form regressions passed: payment precision/digits, identifiers, role and reason guards, national ID, bounded JSON updates, Cairo winter/summer dates.');
