// Integration test against real local Supabase HTTP endpoints, never a remote project.
// Google identity rows are synthetic permission fixtures, not an OAuth demonstration.
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {readFileSync} from 'node:fs';
import {randomUUID,randomBytes,createHash} from 'node:crypto';
import {createClient} from '@supabase/supabase-js';

const config=JSON.parse(execFileSync('./node_modules/.bin/supabase',['status','-o','json'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}));
const url=config.API_URL;
assert(['127.0.0.1','localhost'].includes(new URL(url).hostname),'Integration tests refuse remote projects');
const options={auth:{persistSession:false,autoRefreshToken:false}};
const admin=createClient(url,config.SERVICE_ROLE_KEY,options);
const anon=createClient(url,config.ANON_KEY,options);
const clients=[];const userIds=[];let objectPath;
function checked(result,label){assert.equal(result.error,null,label);return result.data;}
const tokenHash=(value)=>createHash('sha256').update(value).digest('hex');
try{
  for(const label of ['owner','recipient','stranger']){
    const email=`kin-test-${label}-${randomUUID()}@example.test`;
    const password=randomBytes(24).toString('base64url');
    const created=checked(await admin.auth.admin.createUser({email,password,email_confirm:true}),'Create synthetic test account');
    userIds.push(created.user.id);
    const client=createClient(url,config.ANON_KEY,options);
    checked(await client.auth.signInWithPassword({email,password}),'Local password test login');
    clients.push({client,email,id:created.user.id});
  }
  const [owner,recipient,stranger]=clients;
  // Only the isolated local database gets synthetic Google identity rows.
  for(const account of [recipient,stranger]){
    assert.match(account.id,/^[0-9a-f-]{36}$/);
    execFileSync('docker',['exec','supabase_db_kin','psql','-U','postgres','-c',
      `insert into auth.identities(id,user_id,provider_id,provider,identity_data) values ('${randomUUID()}','${account.id}','${account.id}','google','{}')`],{stdio:'ignore'});
  }
  const id=randomUUID();objectPath=`${owner.id}/${id}.png`;
  const image=readFileSync('fixtures/prescriptions/typed-example.png');
  checked(await owner.client.storage.from('prescriptions').upload(objectPath,image,{contentType:'image/png'}),'Private image upload');
  checked(await owner.client.from('documents').insert({id,object_path:objectPath,mime_type:'image/png'}).select().single(),'Owner document metadata insert and returned select');
  assert.equal((await recipient.client.from('documents').select()).data.length,0,'Other user cannot read originals');
  assert((await recipient.client.storage.from('prescriptions').download(objectPath)).error,'Other user cannot download private image');
  assert((await stranger.client.storage.from('prescriptions').upload(`${owner.id}/${randomUUID()}.png`,image,{contentType:'image/png'})).error,'Forged upload prefix denied');
  assert((await anon.from('documents').select()).error,'Anonymous original access denied');
  checked(await owner.client.rpc('review_document',{p_document_id:id,p_date:'2026-09-03',p_clinic:'FICTIONAL Clinic',p_medications:[{
    name:'Paracetamol',dosage:'500 mg',frequency:null,duration:'4 weeks',source_excerpt:'FICTIONAL software test',taking_status:'unknown',
  }]}),'Manual owner review');
  const history=checked(await owner.client.rpc('search_prescriptions',{p_medicine:'PARACETAMOL',p_from:'2026-09-01',p_to:'2026-09-30'}),'Reviewed history lookup');
  assert.equal(history.matches[0].dosage,'500 mg');assert.equal(history.matches[0].prescription_date,'2026-09-03');
  assert.equal(checked(await recipient.client.rpc('search_prescriptions'),'Other user history').matches.length,0);
  const publish={p_name:'FICTIONAL Owner',p_allergies:['Owner-reported fictional example'],p_notes:'Synthetic test note',p_medication_ids:[history.matches[0].id]};
  checked(await owner.client.rpc('publish_summary',publish),'Selected publication');
  assert((await stranger.client.rpc('publish_summary',publish)).error,'Another user cannot publish owner medicine ID');
  const token=randomBytes(32).toString('base64url');
  const share=checked(await owner.client.rpc('create_share',{p_email:recipient.email,p_token_hash:tokenHash(token)}),'Share creation');
  assert((await stranger.client.rpc('accept_share',{p_token_hash:tokenHash(token)})).error,'Forwarded share denied');
  assert.equal(checked(await recipient.client.rpc('accept_share',{p_token_hash:tokenHash(token)}),'Synthetic invited identity accepts'),share.id);
  const summary=checked(await recipient.client.rpc('read_shared_summary',{p_share_id:share.id}),'Authorized browser API read');
  assert.equal(summary.display_name,'FICTIONAL Owner');assert.equal(summary.medicines[0].name,'Paracetamol');
  assert(!JSON.stringify(summary).includes(objectPath),'No original path in recipient projection');
  assert(!('source_excerpt' in summary.medicines[0]),'No private excerpt in recipient projection');
  checked(await owner.client.rpc('publish_summary',{...publish,p_name:'FICTIONAL Updated Owner'}),'Subsequent publication');
  assert.equal(checked(await recipient.client.rpc('read_shared_summary',{p_share_id:share.id}),'Read fixed snapshot').display_name,'FICTIONAL Owner');
  const before=Date.now()-25*3600000;
  checked(await admin.from('shares').update({created_at:new Date(before).toISOString(),expires_at:new Date(before+24*3600000).toISOString()}).eq('id',share.id),'Test expiry fixture');
  assert((await recipient.client.rpc('read_shared_summary',{p_share_id:share.id})).error,'Expired access rejected');
  const secondToken=randomBytes(32).toString('base64url');
  const second=checked(await owner.client.rpc('create_share',{p_email:recipient.email,p_token_hash:tokenHash(secondToken)}),'Second share');
  checked(await recipient.client.rpc('accept_share',{p_token_hash:tokenHash(secondToken)}),'Accept second share');
  checked(await owner.client.rpc('revoke_share',{p_share_id:second.id}),'Owner revokes');
  assert((await recipient.client.rpc('read_shared_summary',{p_share_id:second.id})).error,'Revoked access rejected');
  const contactToken=randomBytes(32).toString('base64url');
  checked(await owner.client.rpc('save_contacts',{p_name:'FICTIONAL Owner',p_entries:[{name:'FICTIONAL Contact',relationship:'Example',phone:'+91 99999 00000',medical:'Must be stripped'}],p_token_hash:tokenHash(contactToken)}),'Contact creation');
  const contacts=checked(await admin.rpc('resolve_contact',{p_token_hash:tokenHash(contactToken)}),'Server-only contact projection');
  assert.deepEqual(Object.keys(contacts.contacts[0]).sort(),['name','phone','relationship']);
  assert((await anon.rpc('resolve_contact',{p_token_hash:tokenHash(contactToken)})).error,'Anonymous direct RPC bypass denied');
  checked(await owner.client.storage.from('prescriptions').remove([objectPath]),'Private original deletion');
  checked(await owner.client.rpc('delete_document',{p_document_id:id}),'Metadata deletion');
  assert.equal(checked(await owner.client.rpc('search_prescriptions'),'History after deletion').matches.length,0);
  console.log('Local HTTP integration passed: upload, review, lookup, recipient binding, snapshot, expiry, revocation, contacts and deletion.');
  console.log('Identity fixtures simulate Google eligibility. External Google OAuth and live Gemma remain untested.');
}finally{
  if(objectPath && clients[0])await clients[0].client.storage.from('prescriptions').remove([objectPath]);
  for(const id of userIds)await admin.auth.admin.deleteUser(id);
}
