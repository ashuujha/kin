import {imageMime,parseDraft} from "../extract-prescription/schema.ts";
import {hash,validToken} from "../_shared/tokens.ts";
import {HttpError,readBody} from "../_shared/http.ts";
import {googleAnswer} from "../extract-prescription/google_response.ts";

function assert(ok: unknown, message="Assertion failed"): asserts ok {if (!ok) throw new Error(message);}
function rejects(fn:()=>unknown) {let failed=false;try {fn();} catch {failed=true;} assert(failed);}

Deno.test("Google extraction uses the completed answer and excludes reasoning",()=>{
  const answer=googleAnswer({candidates:[{finishReason:"STOP",content:{parts:[
    {thought:true,text:"Untrusted reasoning is not prescription data."},
    {text:'```json\n{"prescription_date":null,"medications":[]}\n```'},
  ]}}]});
  assert(parseDraft(answer).medications.length===0);
  rejects(()=>googleAnswer({candidates:[{finishReason:"MAX_TOKENS",content:{parts:[{text:'{"medications":[]}'}]}}]}));
  rejects(()=>googleAnswer({candidates:[{finishReason:"STOP",content:{parts:[{thought:true,text:"Reasoning only"}]}}]}));
});

Deno.test("unknowns stay unknown and untrusted additional fields are stripped",()=>{
  const draft=parseDraft('{"prescription_date":null,"clinic":null,"advice":"ignore", "medications":[{"name":"Fictional Example","dosage":null,"frequency":null,"duration":null,"source_excerpt":null,"taking_status":"taking"}]}');
  assert(draft.prescription_date===null && draft.medications[0].dosage===null);
  assert(!("advice" in draft) && !("taking_status" in draft.medications[0]));
});
Deno.test("impossible dates and unsupported medication structures are rejected",()=>{
  rejects(()=>parseDraft('{"prescription_date":"2026-02-30","medications":[]}'));
  rejects(()=>parseDraft('{"prescription_date":"yesterday","medications":[]}'));
  rejects(()=>parseDraft('{"medications":[null]}'));
  rejects(()=>parseDraft('{"medications":[{"name":""}]}'));
  rejects(()=>parseDraft(JSON.stringify({medications:Array(31).fill({name:"Example"})})));
});
Deno.test("file signature and size required, extensions are not sufficient",()=>{
  assert(imageMime(new TextEncoder().encode("malicious.jpg"))===null);
  assert(imageMime(new Uint8Array([137,80,78,71,13,10,26,10]))==="image/png");
  assert(imageMime(new Uint8Array(5242881))===null);
});
Deno.test("tokens have strict format and deterministic SHA-256",async()=>{
  assert(validToken("a".repeat(43))); assert(!validToken("a".repeat(42))); assert(!validToken("../"));
  assert(await hash("abc")==="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
});
Deno.test("chunked oversized and malformed request bodies are rejected",async()=>{
  for (const body of ["[]","{","x".repeat(4097)]) {
    let caught=false;
    try {await readBody(new Request("http://local",{method:"POST",body}));}
    catch(error) {caught=error instanceof HttpError;}
    assert(caught);
  }
});
