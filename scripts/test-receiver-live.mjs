// Real browser + local APIs, with explicitly synthetic Google identity fixtures.
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {readFileSync,mkdirSync} from 'node:fs';
import {randomUUID,randomBytes,createHash} from 'node:crypto';
import {chromium} from 'playwright-core';
import {createClient} from '@supabase/supabase-js';

let phase='setup';
const cfg=JSON.parse(execFileSync('./node_modules/.bin/supabase',['status','-o','json'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}));
assert(['127.0.0.1','localhost'].includes(new URL(cfg.API_URL).hostname),'Browser fixtures refuse remote databases');
const origin=process.env.KIN_RECEIVER_ORIGIN ?? 'http://127.0.0.1:5173';
const admin=createClient(cfg.API_URL,cfg.SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
const clients=[];const ids=[];let objectPath;let browser;
const checked=(r,label)=>{assert.equal(r.error,null,label);return r.data;};
const hash=token=>createHash('sha256').update(token).digest('hex');
const token=()=>randomBytes(32).toString('base64url');
async function contextFor(account){
  const context=await browser.newContext({viewport:{width:390,height:844}});
  if(account){
    const key=`sb-${new URL(origin).hostname.split('.')[0]}-auth-token`;
    await context.addInitScript(({key,session})=>sessionStorage.setItem(key,JSON.stringify(session)),{key,session:account.session});
  }
  return context;
}
try{
  for(const role of ['owner','recipient','stranger']){
    const email=`kin-receiver-${role}-${randomUUID()}@example.test`,password=randomBytes(24).toString('base64url');
    const user=checked(await admin.auth.admin.createUser({email,password,email_confirm:true}),'Create browser fixture');ids.push(user.user.id);
    const client=createClient(cfg.API_URL,cfg.ANON_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
    const login=checked(await client.auth.signInWithPassword({email,password}),'Authenticate local fixture');
    clients.push({client,email,id:user.user.id,session:login.session});
    if(role!=='owner'){
      assert.match(email,/^[a-z0-9-]+@example\.test$/);assert.match(user.user.id,/^[0-9a-f-]{36}$/);
      execFileSync('docker',['exec','supabase_db_kin','psql','-U','postgres','-c',
        `insert into auth.identities(id,user_id,provider_id,provider,identity_data,created_at,updated_at,last_sign_in_at) values ('${randomUUID()}','${user.user.id}','${user.user.id}','google','{"email":"${email}","email_verified":true,"sub":"${user.user.id}"}',now(),now(),now())`],{stdio:'ignore'});
      checked(await client.auth.getUser(),'Fixture identity readable by Auth');
    }
  }
  const [owner,recipient,stranger]=clients;
  const documentId=randomUUID();objectPath=`${owner.id}/${documentId}.png`;
  checked(await owner.client.storage.from('prescriptions').upload(objectPath,readFileSync('fixtures/prescriptions/typed-example.png'),{contentType:'image/png'}),'Upload fictional original');
  checked(await owner.client.from('documents').insert({id:documentId,object_path:objectPath,mime_type:'image/png'}),'Store original metadata');
  checked(await owner.client.rpc('review_document',{p_document_id:documentId,p_date:'2026-09-03',p_clinic:'FICTIONAL Clinic',p_medications:[{
    name:'Paracetamol',dosage:'500 mg',frequency:null,duration:'4 weeks',source_excerpt:'PRIVATE FICTIONAL SOURCE',taking_status:'unknown',
  }]}),'Review fictional entry');
  const history=checked(await owner.client.rpc('search_prescriptions'),'Read owner history');
  const notes='<img src=x onerror="window.kinUnsafe=true">';
  checked(await owner.client.rpc('publish_summary',{p_name:'FICTIONAL Demo Owner',p_allergies:[],p_notes:notes,p_medication_ids:[history.matches[0].id]}),'Publish selected fields');
  const shareToken=token();
  const share=checked(await owner.client.rpc('create_share',{p_email:recipient.email,p_token_hash:hash(shareToken)}),'Create recipient invitation');
  browser=await chromium.launch({executablePath:process.env.KIN_BROWSER_EXECUTABLE ?? '/usr/bin/brave-browser',headless:true,
    args:['--disable-dev-shm-usage','--disable-background-networking']});
  mkdirSync('test-results',{recursive:true});
  phase='authorized medical rendering';
  const context=await contextFor(recipient),page=await context.newPage();
  await page.goto(`${origin}/s#${shareToken}`);
  await page.getByRole('heading',{name:'FICTIONAL Demo Owner’s summary'}).waitFor();
  assert(await page.getByText('500 mg',{exact:true}).isVisible(),'Selected literal dosage rendered');
  assert.equal(await page.locator('img').count(),0,'Notes render as text');
  assert.equal(await page.evaluate(()=>window.kinUnsafe),undefined,'No injected script executes');
  assert(!new URL(page.url()).hash,'Token stripped from browser URL');
  const body=await page.locator('body').innerText();
  assert(!body.includes('PRIVATE FICTIONAL SOURCE') && !body.includes(objectPath),'Original path and private source stay hidden');
  const persisted=await page.evaluate(()=>JSON.stringify({...sessionStorage,...localStorage}));
  assert(!persisted.includes('500 mg') && !persisted.includes('FICTIONAL Demo Owner'),'Medical data is not persisted');
  await page.screenshot({path:'test-results/receiver-summary-mobile.png',fullPage:true});
  phase='wrong-account denial';
  const wrong=await contextFor(stranger),wrongPage=await wrong.newPage();
  await wrongPage.goto(`${origin}/s#${shareToken}`);
  await wrongPage.getByRole('heading',{name:'This share is unavailable'}).waitFor();
  assert(!((await wrongPage.locator('body').innerText()).includes('500 mg')),'Forwarded account gets no medical details');
  phase='medical revocation polling';
  checked(await owner.client.rpc('revoke_share',{p_share_id:share.id}),'Revoke medical access');
  await page.getByRole('heading',{name:'Access has ended'}).waitFor({timeout:25000});
  assert(!((await page.locator('body').innerText()).includes('500 mg')),'Polling clears revoked display');
  phase='signed-out contact rendering';
  const contactToken=token();
  checked(await owner.client.rpc('save_contacts',{p_name:'FICTIONAL Demo Owner',p_entries:[{name:'FICTIONAL Contact',relationship:'Example only',phone:'+91 99999 00000'}],p_token_hash:hash(contactToken)}),'Publish fictional contacts');
  const publicContext=await contextFor(),contactPage=await publicContext.newPage();
  await contactPage.goto(`${origin}/e#${contactToken}`);
  await contactPage.getByRole('heading',{name:'Contacts for FICTIONAL Demo Owner'}).waitFor();
  assert.equal(await contactPage.getByRole('link',{name:'Call +91 99999 00000'}).getAttribute('href'),'tel:+919999900000');
  assert(!((await contactPage.locator('body').innerText()).includes('500 mg')),'Public contact card has no medicine fields');
  await contactPage.screenshot({path:'test-results/receiver-contacts-mobile.png',fullPage:true});
  phase='contact revocation';
  checked(await owner.client.rpc('save_contacts',{p_name:'FICTIONAL Demo Owner',p_entries:[],p_token_hash:null}),'Revoke contact card');
  await contactPage.reload();
  await contactPage.getByRole('heading',{name:'Contact card unavailable'}).waitFor();
  console.log('Real browser checks passed: authorized projection, escaping, no record persistence, wrong-account denial, medical polling revocation, signed-out contacts and contact revocation.');
  console.log('Google identities are synthetic test fixtures. This does not demonstrate Google OAuth or live AI.');
}catch{
  console.error(`Receiver browser check failed during ${phase}. No credentials, tokens or medical payloads are logged.`);
  process.exitCode=1;
}finally{
  await browser?.close();
  if(objectPath && clients[0])await clients[0].client.storage.from('prescriptions').remove([objectPath]);
  for(const id of ids)await admin.auth.admin.deleteUser(id);
}
