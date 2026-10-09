import {execFileSync} from 'node:child_process';
import {existsSync,readFileSync,writeFileSync,chmodSync} from 'node:fs';
import {parseEnv} from 'node:util';
import {randomBytes} from 'node:crypto';
import {isIP} from 'node:net';
import {createClient} from '@supabase/supabase-js';

const host=process.argv[2] ?? '127.0.0.1';
if(!isIP(host) || !/^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(host)){
  throw new Error('Use a local IPv4 address for the debug phone build.');
}
const config=JSON.parse(execFileSync('./node_modules/.bin/supabase',['status','-o','json'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}));
if(!['127.0.0.1','localhost'].includes(new URL(config.API_URL).hostname))throw new Error('Local setup refuses remote projects.');
const env=existsSync('.env.local')?parseEnv(readFileSync('.env.local','utf8')):{};
const save=(path,text)=>{writeFileSync(path,text,{mode:0o600});chmodSync(path,0o600);};
const receiver=(process.argv[3] ?? `http://${host}:5173`).replace(/\/$/,'');
const receiverUrl=new URL(receiver);
if(!['http:','https:'].includes(receiverUrl.protocol) || receiverUrl.origin!==receiver)throw new Error('Use a receiver origin without a path or credentials.');
const admin=createClient(config.API_URL,config.SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
if(!env.KIN_LOCAL_OWNER_EMAIL || !env.KIN_LOCAL_OWNER_PASSWORD){
  const email='fictional-owner@example.test';
  const password=randomBytes(24).toString('base64url');
  const {error}=await admin.auth.admin.createUser({email,password,email_confirm:true});
  if(error)throw new Error('Could not create the local fictional owner. Existing accounts are preserved.');
  save('.env.local',(existsSync('.env.local')?readFileSync('.env.local','utf8')+'\n':'')+
    `# Fictional local password account; this does not test Google OAuth.\nKIN_LOCAL_OWNER_EMAIL=${email}\nKIN_LOCAL_OWNER_PASSWORD=${password}\n`);
}
const phoneApi=receiverUrl.protocol==='https:'?`${receiver}/backend`:`http://${host}:54321`;
save('apps/mobile/config.local.json',JSON.stringify({SUPABASE_URL:phoneApi,
  SUPABASE_ANON_KEY:config.ANON_KEY,RECIPIENT_URL:receiver,ALLOW_LOCAL_AUTH:true},null,2)+'\n');
save('apps/recipient-web/.env.local',`VITE_SUPABASE_URL=${config.API_URL}\nVITE_SUPABASE_ANON_KEY=${config.ANON_KEY}\nVITE_SUPABASE_PROXY=true\nVITE_GOOGLE_ENABLED=false\n`);
// No provider key is invented. Preserve an existing function env file verbatim.
if(!existsSync('supabase/.env.local'))save('supabase/.env.local',
  `AI_PROVIDER=digitalocean\nAI_MODEL=gemma-4-31B-it\nAI_API_KEY=\nALLOWED_ORIGINS=http://127.0.0.1:5173,http://localhost:5173,${receiver}\n`);
console.log('Configured the local Android owner and same-origin browser receiver.');
console.log('Fictional owner credentials are in ignored .env.local. No secret key was printed or put in a client.');
console.log('Google sign-in and live AI remain unconfigured.');
