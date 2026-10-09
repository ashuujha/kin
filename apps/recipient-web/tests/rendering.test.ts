// @vitest-environment jsdom
import {beforeEach,afterEach,describe,it,expect,vi} from 'vitest';
const api=vi.hoisted(()=>({
  rpc:vi.fn(),
  functions:{invoke:vi.fn()},
  auth:{getSession:vi.fn(),signOut:vi.fn(),signInWithOAuth:vi.fn(),onAuthStateChange:vi.fn()},
}));
vi.mock('@supabase/supabase-js',()=>({createClient:()=>api}));
beforeEach(()=>{
  vi.resetModules();vi.useFakeTimers();vi.stubGlobal('crypto',{subtle:{digest:async()=>new Uint8Array(32).buffer}});
  vi.stubEnv('VITE_SUPABASE_URL','https://fictional.supabase.co');vi.stubEnv('VITE_SUPABASE_ANON_KEY','fictional-public-key');
  document.body.innerHTML='<div id="app"></div>';sessionStorage.clear();
  api.auth.getSession.mockResolvedValue({data:{session:{user:{id:'fictional'}}}});
  api.auth.onAuthStateChange.mockReturnValue({data:{subscription:{unsubscribe:vi.fn()}}});
  api.rpc.mockReset();api.functions.invoke.mockReset();
});
afterEach(()=>{vi.clearAllTimers();vi.useRealTimers();vi.unstubAllEnvs();vi.unstubAllGlobals();});
async function flush(){await vi.advanceTimersByTimeAsync(0);}
describe('medical display lifecycle with synthetic API responses',()=>{
  it('escapes record text, avoids record persistence and clears on revocation',async()=>{
    history.replaceState(null,'','/s#'+'a'.repeat(43));
    api.rpc.mockImplementation(async(name:string)=>name==='accept_share'?{data:'fictional-share',error:null}:{data:{
      display_name:'<img src=x onerror=alert(1)>',allergies:['Synthetic allergy'],medicines:[],notes:'Synthetic sensitive note',
      updated_at:new Date().toISOString(),expires_at:new Date(Date.now()+86400000).toISOString(),
    },error:null});
    await import('../src/main');await flush();
    expect(document.querySelector('h1')?.textContent).toContain('<img src=x onerror=alert(1)>');
    expect(document.querySelector('img')).toBeNull();
    expect(document.body.textContent).toContain('Synthetic sensitive note');
    expect(JSON.stringify(sessionStorage)).not.toContain('Synthetic sensitive note');
    expect(location.hash).toBe('');
    api.rpc.mockResolvedValue({data:null,error:{message:'revoked'}});
    await vi.advanceTimersByTimeAsync(15000);
    expect(document.body.textContent).not.toContain('Synthetic sensitive note');
    expect(document.body.textContent).toContain('Access has ended');
  });
  it('a stalled permission check clears previously displayed data',async()=>{
    history.replaceState(null,'','/s#'+'a'.repeat(43));
    api.rpc.mockImplementation(async(name:string)=>name==='accept_share'?{data:'fictional-share',error:null}:{data:{
      display_name:'Fictional person',allergies:[],medicines:[],notes:'Synthetic visible record',
      updated_at:new Date().toISOString(),expires_at:new Date(Date.now()+86400000).toISOString(),
    },error:null});
    await import('../src/main');await flush();
    expect(document.body.textContent).toContain('Synthetic visible record');
    api.rpc.mockImplementation(()=>new Promise(()=>{}));
    await vi.advanceTimersByTimeAsync(23000);
    expect(document.body.textContent).not.toContain('Synthetic visible record');
    expect(document.body.textContent).toContain('Access could not be checked');
  });
  it('anonymous contact path never requests a medical RPC',async()=>{
    history.replaceState(null,'','/e#'+'b'.repeat(43));
    api.functions.invoke.mockResolvedValue({data:{display_name:'Fictional person',contacts:[{name:'Fictional contact',relationship:'Example',phone:'+91 99999 00000'}],updated_at:new Date().toISOString()},error:null});
    await import('../src/main');await flush();
    expect(api.rpc).not.toHaveBeenCalled();
    expect(api.auth.getSession).not.toHaveBeenCalled();
    expect(document.querySelector('a[href="tel:+919999900000"]')).not.toBeNull();
    expect(document.body.textContent).toContain('No medical records are included');
  });
});
