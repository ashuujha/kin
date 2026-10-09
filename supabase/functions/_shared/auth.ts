import {createClient} from "@supabase/supabase-js";
import {HttpError} from "./http.ts";

export function clients(req: Request) {
  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anon || !service) throw new HttpError(503, "Backend configuration missing");
  const options = {auth: {persistSession: false, autoRefreshToken: false}};
  return {
    user: createClient(url, anon, {...options, global: {headers: {Authorization: req.headers.get("authorization") ?? ""}}}),
    admin: createClient(url, service, options),
  };
}
export async function authenticated(req: Request) {
  const authorization = req.headers.get("authorization") ?? "";
  if (!/^Bearer \S+$/.test(authorization)) throw new HttpError(401, "Sign in required");
  const db = clients(req);
  const {data, error} = await db.user.auth.getUser(authorization.slice(7));
  if (error || !data.user) throw new HttpError(401, "Session invalid. Sign in again.");
  return {...db, identity: data.user};
}
