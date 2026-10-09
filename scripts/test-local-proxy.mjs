// Real HTTP regression checks for the public local-demo credential boundary.
import assert from 'node:assert/strict';
import {execFileSync,spawn} from 'node:child_process';
import {readFileSync} from 'node:fs';
import {randomUUID,randomBytes,createHmac} from 'node:crypto';
import {createClient} from '@supabase/supabase-js';

let admin,client,userId,objectPath,runtime,phase='local setup';
const checked=(r,label)=>{assert.equal(r.error,null,label);return r.data;};
try{
  const cfg=JSON.parse(execFileSync('./node_modules/.bin/supabase',['status','-o','json'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}));
  assert.equal(new URL(cfg.API_URL).hostname,'127.0.0.1','Proxy tests refuse remote databases');
  const origin=process.env.KIN_PROXY_ORIGIN ?? 'http://127.0.0.1:5173';
  const api=`${origin}/backend`;
  if(process.env.KIN_PROXY_START_SERVER==='1'){
    runtime=spawn(process.execPath,['scripts/serve-local-receiver.mjs'],{stdio:['ignore','pipe','pipe']});
    await new Promise((resolve,reject)=>{
      const timer=setTimeout(()=>reject(new Error('Proxy did not become ready')),30000);
      let output='';
      const ready=chunk=>{output=(output+chunk.toString()).slice(-4096);if(output.includes('Kin receiver ready')){clearTimeout(timer);resolve();}};
      runtime.stdout.on('data',ready);runtime.stderr.on('data',ready);
      runtime.once('error',()=>{clearTimeout(timer);reject(new Error('Proxy could not start'));});
      runtime.once('exit',()=>{clearTimeout(timer);reject(new Error('Proxy stopped during startup'));});
    });
  }
  const options={auth:{persistSession:false,autoRefreshToken:false}};
  admin=createClient(cfg.API_URL,cfg.SERVICE_ROLE_KEY,options);
  const email=`kin-proxy-${randomUUID()}@example.test`,password=randomBytes(24).toString('base64url');
  userId=checked(await admin.auth.admin.createUser({email,password,email_confirm:true}),'Create fictional proxy owner').user.id;
  client=createClient(api,cfg.ANON_KEY,options);
  phase='legitimate HTTPS/profile access';
  const session=checked(await client.auth.signInWithPassword({email,password}),'Password login through proxy').session;
  phase='asymmetric owner identity';
  checked(await client.auth.getUser(),'Owner identity through proxy');
  const header=JSON.parse(Buffer.from(session.access_token.split('.')[0],'base64url'));
  assert.equal(header.alg,'ES256','Local demo requires asymmetric user sessions');
  const documentId=randomUUID();objectPath=`${userId}/${documentId}.png`;
  phase='owner private upload';
  checked(await client.storage.from('prescriptions').upload(objectPath,readFileSync('fixtures/prescriptions/typed-example.png'),{contentType:'image/png'}),'Owner private upload');
  phase='owner private download';
  checked(await client.storage.from('prescriptions').download(objectPath),'Owner private download');
  phase='owner metadata insert';
  checked(await client.from('documents').insert({id:documentId,object_path:objectPath,mime_type:'image/png'}),'Owner metadata insert');
  phase='owner metadata read';
  assert.equal(checked(await client.from('documents').select('id'),'Owner reads metadata').length,1);
  const request=(path,token,key=cfg.ANON_KEY)=>fetch(`${api}${path}`,{
    headers:{apikey:key,...(token?{Authorization:`Bearer ${token}`}:{})},signal:AbortSignal.timeout(15000),
  });
  phase='known legacy signing-secret attack';
  const claims=JSON.parse(Buffer.from(session.access_token.split('.')[1],'base64url'));
  const encoded=value=>Buffer.from(JSON.stringify(value)).toString('base64url');
  const unsigned=`${encoded({alg:'HS256',typ:'JWT'})}.${encoded(claims)}`;
  const forged=`${unsigned}.${createHmac('sha256',cfg.JWT_SECRET).update(unsigned).digest('base64url')}`;
  assert.equal((await request('/rest/v1/documents?select=id',forged)).status,401,'Forged legacy owner rejected');
  assert.equal((await request(`/storage/v1/object/authenticated/prescriptions/${objectPath}`,forged)).status,401,'Forged legacy private read rejected');
  phase='privileged credential attack';
  assert.equal((await request('/rest/v1/documents?select=id',cfg.SERVICE_ROLE_KEY)).status,401,'Known local service bearer rejected');
  assert.equal((await request('/rest/v1/documents?select=id',session.access_token,cfg.SERVICE_ROLE_KEY)).status,401,'Privileged API key rejected');
  assert.equal((await request(`/rest/v1/documents?apikey=${encodeURIComponent(cfg.SERVICE_ROLE_KEY)}`)).status,401,'Query credential override rejected');
  const segments=session.access_token.split('.');
  const signature=Buffer.from(segments[2],'base64url');signature[0]^=1;
  segments[2]=signature.toString('base64url');
  assert.equal((await request('/rest/v1/documents?select=id',segments.join('.'))).status,401,'Modified asymmetric signature rejected');
  phase='unsigned and unsupported routes';
  const anon=createClient(api,cfg.ANON_KEY,options);
  assert((await anon.storage.from('prescriptions').download(objectPath)).error,'Anon private original denied');
  for(const path of ['/auth/v1/signup','/auth/v1/admin/users',`/storage/v1/object/sign/prescriptions/${objectPath}`]){
    assert.equal((await request(path)).status,404,'Unsupported privileged/signed routes blocked');
  }
  checked(await client.storage.from('prescriptions').remove([objectPath]),'Owner deletes original through proxy');
  console.log('Proxy HTTP checks passed: real asymmetric login, private upload/read/delete; forged legacy owner, service bearer/key, query credentials and modified signature rejected; anonymous originals and unsupported routes denied.');
}catch{
  console.error(`Proxy HTTP check failed during ${phase}. Credentials and response payloads withheld.`);process.exitCode=1;
}finally{
  try{
    if(objectPath && admin)await admin.storage.from('prescriptions').remove([objectPath]);
    if(userId && admin)await admin.auth.admin.deleteUser(userId);
  }finally{runtime?.kill('SIGINT');}
}
