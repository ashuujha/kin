import {existsSync,readFileSync,writeFileSync,chmodSync} from 'node:fs';
import {parseEnv} from 'node:util';

const fail=message=>{console.error(message);process.exit(1);};
if(!existsSync('.env.production.local'))fail('Copy .env.production.example to .env.production.local and enter the public project URL, key and receiver origin.');
const env=parseEnv(readFileSync('.env.production.local','utf8'));
let api,receiver;
try {
  api=new URL(env.SUPABASE_URL);receiver=new URL(env.RECIPIENT_URL);
}catch {fail('Both public origins must be valid HTTPS URLs.');}
for(const origin of [api,receiver]) {
  if(origin.protocol!=='https:' || origin.username || origin.password || origin.port ||
    origin.pathname!=='/' || origin.search || origin.hash)fail('Use HTTPS origins without credentials, ports, paths or query strings.');
}
if(!/^[a-z0-9]+\.supabase\.co$/.test(api.hostname))fail('The final profile requires a hosted Supabase project, not a local testing endpoint.');
if(/(?:^|\.)trycloudflare\.com$/.test(receiver.hostname))fail('Use a stable deployed receiver origin for the final build.');
const key=env.SUPABASE_ANON_KEY ?? '';
let publicKey=key.startsWith('sb_publishable_') && /^[A-Za-z0-9_-]+$/.test(key);
try {publicKey ||= key.split('.').length===3 && JSON.parse(Buffer.from(key.split('.')[1],'base64url')).role==='anon';}catch { /* Reject unknown credentials without printing them. */ }
if(!publicKey)fail('Use a Supabase publishable or anon key. Secret and service-role keys are forbidden in clients.');
try {
  const response=await fetch(`${api.origin}/auth/v1/settings`,{headers:{apikey:key},signal:AbortSignal.timeout(15000)});
  if(!response.ok)fail('The hosted project did not accept its public key. Check the project configuration.');
  const settings=await response.json();
  if(settings.external?.google!==true)fail('Enable Google in the hosted project before generating the final profile.');
  if(settings.disable_signup===true)fail('Enable new user signups in the hosted project so first Google sign-in can create an account.');
}catch {fail('Could not verify the hosted authentication service. Client files were not changed.');}
const save=(path,value)=>{writeFileSync(path,value,{mode:0o600});chmodSync(path,0o600);};
save('apps/mobile/config.production.json',JSON.stringify({SUPABASE_URL:api.origin,SUPABASE_ANON_KEY:key,RECIPIENT_URL:receiver.origin,ALLOW_LOCAL_AUTH:false},null,2)+'\n');
save('apps/recipient-web/.env.production.local',`VITE_SUPABASE_URL=${api.origin}\nVITE_SUPABASE_ANON_KEY=${key}\nVITE_SUPABASE_PROXY=false\nVITE_GOOGLE_ENABLED=true\n`);
console.log('Hosted Google provider is enabled. Wrote public Android and browser configuration with local password login disabled.');
console.log('OAuth callbacks, deployed database/functions and live extraction still require actual verification.');
