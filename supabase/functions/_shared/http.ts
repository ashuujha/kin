export class HttpError extends Error {
  constructor(public status: number, message: string) { super(message); }
}

export function responseHeaders(origin: string | null): Headers {
  const headers = new Headers({
    "Content-Type": "application/json", "Cache-Control": "no-store",
    "Referrer-Policy": "no-referrer", "X-Content-Type-Options": "nosniff",
    "Vary": "Origin", "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  });
  const allowed = (Deno.env.get("ALLOWED_ORIGINS") ?? "http://127.0.0.1:5173").split(",").map(s => s.trim());
  if (origin && allowed.includes(origin)) headers.set("Access-Control-Allow-Origin", origin);
  return headers;
}

export async function readBody(req: Request): Promise<Record<string, unknown>> {
  const reader = req.body?.getReader();
  if (!reader) throw new HttpError(400, "Request body required");
  const chunks: Uint8Array[] = []; let length = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    length += value.length;
    if (length > 4096) { await reader.cancel(); throw new HttpError(413, "Request too large"); }
    chunks.push(value);
  }
  const bytes = new Uint8Array(length); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  try {
    const result: unknown = JSON.parse(new TextDecoder().decode(bytes));
    if (!result || typeof result !== "object" || Array.isArray(result)) throw new Error();
    return result as Record<string, unknown>;
  } catch { throw new HttpError(400, "Invalid JSON"); }
}

export function endpoint(handler: (req: Request) => Promise<unknown>) {
  return async (req: Request): Promise<Response> => {
    const headers = responseHeaders(req.headers.get("origin"));
    if (req.method === "OPTIONS") return new Response(null, {status: 204, headers});
    if (req.method !== "POST") return new Response(JSON.stringify({error: "POST required"}), {status: 405, headers});
    try { return new Response(JSON.stringify(await handler(req)), {headers}); }
    catch (error) {
      const status = error instanceof HttpError ? error.status : 500;
      const message = error instanceof HttpError ? error.message : "Service unavailable. Please retry.";
      // Deliberately never log errors: provider errors may contain prompts or credentials.
      return new Response(JSON.stringify({error: message}), {status, headers});
    }
  };
}
