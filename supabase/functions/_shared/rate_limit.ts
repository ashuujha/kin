import type {SupabaseClient} from "@supabase/supabase-js";
import {hash} from "./tokens.ts";
import {HttpError} from "./http.ts";

export async function rateLimit(db: SupabaseClient, key: string, limit: number, seconds: number) {
  const {data, error} = await db.rpc("check_rate_limit", {
    p_key_hash: await hash(key), p_limit: limit, p_window_seconds: seconds,
  });
  if (error) throw new HttpError(503, "Service unavailable");
  if (data !== true) throw new HttpError(429, "Too many requests. Try again later.");
}
