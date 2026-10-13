import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { transform,loadBindings } from 'next/dist/build/swc/index.js';

const directory=path.join(process.cwd(),'.next','qa');
await fs.mkdir(directory,{recursive:true});
const source=(await fs.readFile('lib/certificate-pdf.tsx','utf8')).replace('import "server-only";','');
await loadBindings();
const {code}=await transform(source,{filename:'certificate-pdf.tsx',jsc:{parser:{syntax:'typescript',tsx:true},transform:{react:{runtime:'automatic'}},target:'es2022'},module:{type:'es6'}});
const modulePath=path.join(directory,'certificate-module.mjs');
await fs.writeFile(modulePath,code);
const {certificatePdf}=await import(pathToFileURL(modulePath));
const bytes=await certificatePdf({name:'محمد عبد الرحمن أحمد مصطفى',kind:'إتمام القرآن الكريم',date:'١٣ أكتوبر ٢٠٢٦',center:'دار تحفيظ القرآن',id:'00000000-0000-4000-8000-000000000001'});
if(bytes.subarray(0,4).toString()!=='%PDF'||bytes.length<1000)throw Error('Invalid PDF');
const output=path.join(directory,'certificate.pdf');
await fs.writeFile(output,bytes);
console.log(`Certificate rendered: ${bytes.length} bytes; ${output}`);
