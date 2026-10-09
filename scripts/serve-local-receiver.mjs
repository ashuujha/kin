// Production assets plus a same-origin local API proxy; no Vite dev server is exposed.
import {createServer} from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,sep,extname} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createPublicKey,verify} from 'node:crypto';

// CLI's legacy JWT secret is publicly known. Never accept those user/service
// tokens through a public tunnel. Only the exact anon key and locally issued,
// cryptographically verified asymmetric user sessions can cross this proxy.
let local,verificationKeys,publicKeys;
try{
  local=JSON.parse(execFileSync('./node_modules/.bin/supabase',['status','-o','json'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}));
  if(new URL(local.API_URL).hostname!=='127.0.0.1')throw new Error();
  const response=await fetch(`${local.API_URL}/auth/v1/.well-known/jwks.json`,{signal:AbortSignal.timeout(10000)});
  if(!response.ok)throw new Error();
  const {keys}=await response.json();
  const [configured]=JSON.parse(await readFile('supabase/signing-keys.local.json','utf8'));
  verificationKeys=new Map(keys.filter(k=>k.kty==='EC' && k.crv==='P-256' && k.kid && !k.d &&
    k.kid===configured.kid && k.x===configured.x && k.y===configured.y)
    .map(k=>[k.kid,createPublicKey({key:k,format:'jwk'})]));
  if(!verificationKeys.size)throw new Error();
  publicKeys=new Set([local.ANON_KEY]);
  // A previously configured preview may retain its old public anon identifier.
  // Translate that exact identifier to the current upstream anon credential;
  // it never grants a user identity or privileges after signing-key rotation.
  try{
    const profile=JSON.parse(await readFile('apps/mobile/config.local.json','utf8'));
    const role=JSON.parse(Buffer.from(profile.SUPABASE_ANON_KEY.split('.')[1],'base64url')).role;
    if(role==='anon')publicKeys.add(profile.SUPABASE_ANON_KEY);
  }catch{ /* CI and fresh checkouts have no ignored phone profile. */ }
}catch{
  console.error('Local receiver needs running Supabase with asymmetric Auth keys. Configuration was not logged.');
  process.exit(1);
}
function userSession(token){
  try{
    const parts=token.split('.');if(parts.length!==3 || token.length>8192)return false;
    const head=JSON.parse(Buffer.from(parts[0],'base64url'));
    const claims=JSON.parse(Buffer.from(parts[1],'base64url'));
    const key=verificationKeys.get(head.kid);
    return head.alg==='ES256' && !!key && claims.role==='authenticated' &&
      claims.aud==='authenticated' && claims.iss===`${local.API_URL}/auth/v1` &&
      typeof claims.exp==='number' && claims.exp>Date.now()/1000 &&
      /^[0-9a-f-]{36}$/.test(claims.sub ?? '') &&
      verify('sha256',Buffer.from(`${parts[0]}.${parts[1]}`),{key,dsaEncoding:'ieee-p1363'},Buffer.from(parts[2],'base64url'));
  }catch{return false;}
}

const dist=resolve('apps/recipient-web/dist');
const host=process.argv[2] ?? '127.0.0.1';
const port=5173;
const headers={
  'Cache-Control':'no-store','Referrer-Policy':'no-referrer','X-Content-Type-Options':'nosniff',
  'X-Frame-Options':'DENY','Permissions-Policy':'camera=(), microphone=(), geolocation=()',
  'Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'",
};
const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8',
  '.css':'text/css; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.ico':'image/x-icon'};
const server=createServer(async(req,res)=>{
  for(const [name,value] of Object.entries(headers))res.setHeader(name,value);
  try{
    const url=new URL(req.url,'http://local');
    if(url.pathname.startsWith('/backend/')){
      const path=url.pathname.slice('/backend'.length);
      if(!/^\/(auth|rest|storage|functions)\/v1\//.test(path)){
        res.writeHead(404);res.end('Unavailable');return;
      }
      // Local accounts are created by the CLI helper. The public demo does not
      // expose signup, invitations, admin APIs or an unconfigured OAuth endpoint.
      if(path.startsWith('/auth/') && !['/auth/v1/token','/auth/v1/user','/auth/v1/logout','/auth/v1/settings'].includes(path)){
        res.writeHead(404);res.end('Unavailable');return;
      }
      if(path.startsWith('/storage/') && !/^\/storage\/v1\/object\/(?:authenticated\/)?prescriptions(?:\/[0-9a-f-]{36}\/[0-9a-f-]{36}\.(?:png|jpg))?$/.test(path)){
        res.writeHead(404);res.end('Unavailable');return;
      }
      if(path.startsWith('/functions/') && !['/functions/v1/extract-prescription','/functions/v1/emergency-contact'].includes(path)){
        res.writeHead(404);res.end('Unavailable');return;
      }
      const bearer=req.headers.authorization?.match(/^Bearer ([^\s]+)$/i)?.[1];
      if(!publicKeys.has(req.headers.apikey) ||
        (req.headers.authorization && !bearer) ||
        (bearer && !publicKeys.has(bearer) && !userSession(bearer)) ||
        [...url.searchParams.keys()].some(k=>['apikey','authorization','access_token'].includes(k.toLowerCase()))){
        res.writeHead(401);res.end('Session unavailable');return;
      }
      if(!['GET','HEAD','POST','PUT','PATCH','DELETE','OPTIONS'].includes(req.method)){
        res.writeHead(405);res.end();return;
      }
      let length=0;const chunks=[];
      for await(const chunk of req){
        length+=chunk.length;
        if(length>5308416){res.writeHead(413);res.end('Request too large');return;}
        chunks.push(chunk);
      }
      const forwarded={};
      for(const name of ['authorization','apikey','content-type','accept','prefer','range','x-client-info','x-upsert']){
        if(req.headers[name])forwarded[name]=req.headers[name];
      }
      // Explicitly bind upstream credentials even for anonymous requests.
      forwarded.apikey=local.ANON_KEY;
      forwarded.authorization=`Bearer ${bearer && !publicKeys.has(bearer)?bearer:local.ANON_KEY}`;
      const response=await fetch(`http://127.0.0.1:54321${path}${url.search}`,{
        method:req.method,headers:forwarded,
        body:['GET','HEAD'].includes(req.method)?undefined:Buffer.concat(chunks),
        redirect:'manual',signal:AbortSignal.timeout(65000),
      });
      // Do not follow upstream redirects or forward credential-bearing headers.
      if(response.status>=300 && response.status<400){res.writeHead(502);res.end('Upstream redirect unavailable');return;}
      const body=req.method==='HEAD'?undefined:Buffer.from(await response.arrayBuffer());
      res.writeHead(response.status,{'Content-Type':response.headers.get('content-type') ?? 'application/json'});
      res.end(body);return;
    }
    if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);res.end();return;}
    const spa=['/','/s','/e','/privacy','/auth/callback'].includes(url.pathname);
    const path=spa?resolve(dist,'index.html'):resolve(dist,`.${decodeURIComponent(url.pathname)}`);
    if(!path.startsWith(dist+sep) || (!spa && !url.pathname.startsWith('/assets/'))){res.writeHead(404);res.end('Not found');return;}
    const info=await stat(path);
    if(!info.isFile()){res.writeHead(404);res.end('Not found');return;}
    const body=req.method==='HEAD'?undefined:await readFile(path);
    res.writeHead(200,{'Content-Type':mime[extname(path)] ?? 'application/octet-stream'});
    res.end(body);
  }catch{
    res.writeHead(503,{'Content-Type':'text/plain'});res.end('Local service unavailable. Please retry.');
  }
});
server.requestTimeout=70000;
server.headersTimeout=10000;
server.listen(port,host,()=>console.log(`Kin receiver ready on port ${port}. Public assets only; requests and tokens are not logged.`));
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>server.close(()=>process.exit(0)));
