import {authenticated} from "../_shared/auth.ts";
import {endpoint, HttpError, readBody} from "../_shared/http.ts";
import {rateLimit} from "../_shared/rate_limit.ts";
import {imageMime} from "./schema.ts";
import {extract} from "./gemma.ts";

Deno.serve(endpoint(async req => {
  const {user,admin,identity} = await authenticated(req);
  await rateLimit(admin,`extract:${identity.id}`,10,3600);
  const body = await readBody(req);
  if (typeof body.document_id !== "string" || !/^[a-f0-9-]{36}$/i.test(body.document_id)) throw new HttpError(400,"Invalid document");
  const {data:doc,error} = await user.from("documents").select("id,object_path,mime_type,status").eq("id",body.document_id).single();
  if (error || !doc) throw new HttpError(404,"Record unavailable");
  if (doc.status === "reviewed" || doc.status === "processing") throw new HttpError(409,"Record already reviewed or processing");
  const {data:file,error:downloadError} = await user.storage.from("prescriptions").download(doc.object_path);
  if (downloadError || !file) throw new HttpError(404,"File unavailable");
  const bytes = new Uint8Array(await file.arrayBuffer());
  const mime = imageMime(bytes);
  if (!mime || mime !== doc.mime_type) throw new HttpError(400,"Only valid JPEG or PNG images up to 5 MB are accepted");
  const {data:locked,error:lockError} = await admin.from("documents").update({status:"processing"})
    .eq("id",doc.id).eq("owner_id",identity.id).in("status",["uploaded","failed","draft"]).select("id");
  if (lockError || !locked?.length) throw new HttpError(409,"Record already processing");
  try {
    const draft = await extract(bytes,mime);
    const {error:saveError} = await admin.from("documents").update({draft,status:"draft",extraction_method:"gemma"})
      .eq("id",doc.id).eq("owner_id",identity.id).eq("status","processing");
    if (saveError) throw new HttpError(500,"Could not save extraction. Retry.");
    return {draft};
  } catch (failure) {
    await admin.from("documents").update({status:"failed"}).eq("id",doc.id).eq("owner_id",identity.id).eq("status","processing");
    throw failure;
  }
}));
