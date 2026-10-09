// Start only this project's development stack; keep CLI credential output private.
import {mkdirSync,openSync,chmodSync,closeSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
mkdirSync('supabase/.temp',{recursive:true});
const path='supabase/.temp/local-start.log';
const fd=openSync(path,'w',0o600);chmodSync(path,0o600);
let stage='private signing keys';
const run=(command,args)=>{
  const result=spawnSync(command,args,{stdio:['ignore',fd,fd]});
  if(result.error || result.status!==0)throw new Error('Local stage failed.');
};
try{
  console.log('Preparing Kin private development credentials. No keys are printed.');
  run(process.execPath,['scripts/prepare-local-keys.mjs']);
  stage='project network';
  if(spawnSync('docker',['network','inspect','kin-loopback'],{stdio:'ignore'}).status!==0){
    run('docker',['network','create','--driver','bridge','--opt','com.docker.network.bridge.host_binding_ipv4=127.0.0.1','kin-loopback']);
  }
  stage='local backend startup';
  console.log('Starting Kin backend; optional dashboards are excluded.');
  run('./node_modules/.bin/supabase',['start','-x','studio,logflare,vector,imgproxy,realtime,postgres-meta','--network-id','kin-loopback']);
  stage='explicit localhost port binding';
  run('python3',['scripts/bind-local-backend.py']);
  console.log('Kin backend ready. Raw API, database and local mail ports are verified on 127.0.0.1.');
}catch{
  console.error(`Local startup failed during ${stage}. Details remain in ignored supabase/.temp/local-start.log; do not share its credential output.`);
  process.exitCode=1;
}finally{closeSync(fd);}
