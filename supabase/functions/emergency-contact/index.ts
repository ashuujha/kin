import {clients} from "../_shared/auth.ts";
import {endpoint,HttpError,readBody} from "../_shared/http.ts";
import {hash,validToken} from "../_shared/tokens.ts";
import {rateLimit} from "../_shared/rate_limit.ts";

Deno.serve(endpoint(async req => {
  const {admin} = clients(req);
  // Conservative shared global cap cannot be bypassed by spoofed forwarded-IP headers.
  await rateLimit(admin,"contact-global",600,60);
  const body = await readBody(req);
  if (!validToken(body.token)) throw new HttpError(404,"Contact card unavailable");
  const tokenHash = await hash(body.token);
  await rateLimit(admin,`contact:${tokenHash}`,120,60);
  const {data,error} = await admin.rpc("resolve_contact",{p_token_hash:tokenHash});
  if (error) throw new HttpError(503,"Contact service unavailable");
  if (!data) throw new HttpError(404,"Contact card unavailable");
  return data;
}));
