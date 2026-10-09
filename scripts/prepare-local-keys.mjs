import {existsSync,readFileSync,writeFileSync,chmodSync} from 'node:fs';
import {generateKeyPairSync,randomUUID,randomBytes,createPrivateKey,sign} from 'node:crypto';
import {parseEnv} from 'node:util';
const path='supabase/signing-keys.local.json';
if(!existsSync(path)){
  const {privateKey}=generateKeyPairSync('ec',{namedCurve:'prime256v1'});
  const key={...privateKey.export({format:'jwk'}),kid:randomUUID(),use:'sig',alg:'ES256',key_ops:['sign','verify']};
  writeFileSync(path,JSON.stringify([key])+'\n',{mode:0o600,flag:'wx'});
}
chmodSync(path,0o600);
const text=existsSync('.env')?readFileSync('.env','utf8'):'';
const env=parseEnv(text),added=[];
if(!env.KIN_LOCAL_JWT_SECRET)added.push(`KIN_LOCAL_JWT_SECRET=${randomBytes(48).toString('base64url')}`);
const [key]=JSON.parse(readFileSync(path,'utf8'));
const privateKey=createPrivateKey({key,format:'jwk'});
const encoded=value=>Buffer.from(JSON.stringify(value)).toString('base64url');
for(const [name,role] of [['KIN_LOCAL_ANON_KEY','anon'],['KIN_LOCAL_SERVICE_KEY','service_role']]){
  if(!env[name]){
    const data=`${encoded({alg:'ES256',typ:'JWT',kid:key.kid})}.${encoded({iss:'supabase-demo',role,exp:Math.floor(Date.now()/1000)+315360000})}`;
    added.push(`${name}=${data}.${sign('sha256',Buffer.from(data),{key:privateKey,dsaEncoding:'ieee-p1363'}).toString('base64url')}`);
  }
}
if(added.length)writeFileSync('.env',`${text}\n# Local credentials; never publish this file.\n${added.join('\n')}\n`,{mode:0o600});
chmodSync('.env',0o600);
console.log('Local Auth uses an ignored private signing-key file. Key material was not printed.');
