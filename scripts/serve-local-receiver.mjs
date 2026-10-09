// Production assets plus a same-origin local API proxy; no Vite dev server is exposed.
import {createServer} from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,sep,extname} from 'node:path';

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
    const spa=['/','/s','/e','/auth/callback'].includes(url.pathname);
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
