import {clients} from '../_shared/auth.ts';
import {endpoint,HttpError,readBody} from '../_shared/http.ts';
import {hash,validToken} from '../_shared/tokens.ts';
import {rateLimit} from '../_shared/rate_limit.ts';
Deno.serve(endpoint(async req=>{
 const {admin}=clients(req);await rateLimit(admin,'emergency-global',600,60);
 const body=await readBody(req);if(!validToken(body.token))throw new HttpError(404,'Emergency summary unavailable');
 const tokenHash=await hash(body.token);await rateLimit(admin,`emergency:${tokenHash}`,120,60);
 const {data,error}=await admin.rpc('resolve_emergency',{p_token_hash:tokenHash});
 if(error)throw new HttpError(503,'Emergency service unavailable');if(!data)throw new HttpError(404,'Emergency summary revoked or unavailable');return data;
}));
