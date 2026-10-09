import {execFileSync} from 'node:child_process';
import {existsSync,readFileSync,writeFileSync,chmodSync} from 'node:fs';
import {parseEnv} from 'node:util';

const fail=message=>{console.error(message);process.exit(1);};
if(!existsSync('.env.launch.local'))fail('Fill the ignored .env.launch.local from .env.launch.example first. Secrets must remain on the laptop.');
const env=parseEnv(readFileSync('.env.launch.local','utf8'));
const required=['SUPABASE_ACCESS_TOKEN','SUPABASE_PROJECT_REF','SUPABASE_DB_PASSWORD','GOOGLE_CLIENT_ID','GOOGLE_CLIENT_SECRET','AI_API_KEY'];
if(required.some(k=>!env[k]?.trim()))fail('Launch credentials are incomplete. Fill the Supabase project/token/password, Google client ID/secret and AI key. Nothing was deployed.');
if(!/^[a-z]{20}$/.test(env.SUPABASE_PROJECT_REF))fail('Use the exact hosted Supabase project reference.');
if(!/^[A-Za-z0-9._-]+\.apps\.googleusercontent\.com$/.test(env.GOOGLE_CLIENT_ID))fail('Use a Google Web application client ID.');
if(Object.values(env).some(v=>/[\r\n]/.test(v)))fail('Use one-line environment values.');
let receiver;
try{receiver=new URL(env.RECIPIENT_URL);}catch{fail('Receiver URL is invalid.');}
if(receiver.protocol!=='https:' || receiver.username || receiver.password || receiver.port || receiver.search || receiver.hash ||
  !/^(?:\/[A-Za-z0-9_-]+)*\/?$/.test(receiver.pathname))fail('Use a stable HTTPS receiver URL.');
const receiverUrl=receiver.href.replace(/\/$/,'');
const ref=env.SUPABASE_PROJECT_REF;
const childEnv={...process.env,SUPABASE_ACCESS_TOKEN:env.SUPABASE_ACCESS_TOKEN,SUPABASE_DB_PASSWORD:env.SUPABASE_DB_PASSWORD};
const run=(label,command,args,input)=>{
  console.log(label);
  try{return execFileSync(command,args,{env:childEnv,input,encoding:'utf8',stdio:['pipe','pipe','pipe'],timeout:180000});}
  catch{fail(`${label} failed. No credential or raw service response was printed. Check the account and project configuration before retrying.`);}
};
const manage=async(path,method='GET',body)=>{
  let response;
  try{response=await fetch(`https://api.supabase.com/v1/projects/${ref}${path}`,{method,
    headers:{Authorization:`Bearer ${env.SUPABASE_ACCESS_TOKEN}`,'Content-Type':'application/json'},
    body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(30000)});}
  catch{fail('Supabase Management API could not be reached. No service response was printed.');}
  if(!response.ok)fail(`Supabase project configuration request was rejected (HTTP ${response.status}). Credentials were withheld.`);
  return response.json();
};
const save=(path,content)=>{writeFileSync(path,content,{mode:0o600});chmodSync(path,0o600);};
const quote=value=>JSON.stringify(value);
const project=await manage('');
if(project.name?.toLowerCase()!=='kin')fail('Use a dedicated project named Kin. This helper refuses to change authentication on unrelated projects.');
console.log(`Google authorized redirect URI: https://${ref}.supabase.co/auth/v1/callback`);
run('Prepare private local CLI configuration','node',['scripts/prepare-local-keys.mjs']);
run('Link the dedicated hosted project','./node_modules/.bin/supabase',['link','--project-ref',ref]);
run('Apply pending Kin database migrations','./node_modules/.bin/supabase',['db','push','--linked','--yes']);
await manage('/config/auth','PATCH',{
  site_url:receiverUrl,
  uri_allow_list:`${receiverUrl}/auth/callback,dev.ashuujha.kin://auth/callback`,
  disable_signup:false,external_google_enabled:true,
  external_google_client_id:env.GOOGLE_CLIENT_ID,external_google_secret:env.GOOGLE_CLIENT_SECRET,
  external_email_enabled:false,external_phone_enabled:false,external_anonymous_users_enabled:false,
});
console.log('Configured Google account creation/sign-in and exact callback allowlist.');
save('supabase/.env.production.local',[
  `AI_PROVIDER=${quote(env.AI_PROVIDER ?? 'digitalocean')}`,
  `AI_MODEL=${quote(env.AI_MODEL ?? 'gemma-4-31B-it')}`,
  `AI_API_KEY=${quote(env.AI_API_KEY)}`,
  `ALLOWED_ORIGINS=${quote(receiver.origin)}`,
].join('\n')+'\n');
run('Upload server-side model configuration','./node_modules/.bin/supabase',['secrets','set','--env-file','supabase/.env.production.local','--project-ref',ref]);
for(const name of ['extract-prescription','emergency-contact'])run(`Deploy ${name}`,'./node_modules/.bin/supabase',['functions','deploy',name,'--project-ref',ref]);
const keys=await manage('/api-keys');
const key=Array.isArray(keys)?keys.find(k=>k.name==='anon')?.api_key:undefined;
if(!key)fail('Hosted public anon key was unavailable. No privileged key was copied to a client.');
save('.env.production.local',`SUPABASE_URL=https://${ref}.supabase.co\nSUPABASE_ANON_KEY=${key}\nRECIPIENT_URL=${receiverUrl}\n`);
run('Verify and generate public client profiles','node',['scripts/configure-production.mjs']);
for(const [name,value] of [['SUPABASE_URL',`https://${ref}.supabase.co`],['SUPABASE_ANON_KEY',key],['RECIPIENT_URL',receiverUrl]]) {
  run(`Configure public GitHub variable ${name}`,'gh',['variable','set',name,'--repo','ashuujha/kin','--body',value]);
}
run('Build the hosted browser receiver','gh',['workflow','run','receiver-pages.yml','--repo','ashuujha/kin','--ref','main']);
run('Build the Google-configured Android APK','gh',['workflow','run','android-build.yml','--repo','ashuujha/kin','--ref','main','--json'],JSON.stringify({
  supabase_url:`https://${ref}.supabase.co`,supabase_public_key:key,receiver_url:receiverUrl,local_test_login:'false',
}));
console.log('Deployment configuration applied and builds dispatched. Actual Google login, live fictional-image extraction and the two-account walkthrough still need verification.');
