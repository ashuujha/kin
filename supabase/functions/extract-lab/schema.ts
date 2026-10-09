export type LabResult={test:string;value:string|null;unit:string|null;reference_range:string|null;report_flag:'high'|'low'|'normal'|'unknown';source_excerpt:string|null};
export type LabDraft={report_date:string|null;laboratory:string|null;results:LabResult[]};
function text(v:unknown,max:number,required=false):string|null{
 if(v===null||v===undefined||v===''){if(required)throw Error('Missing field');return null;}
 if(typeof v!=='string'||v.length>max||!v.trim())throw Error('Invalid field');return v.trim();
}
export function parseLab(raw:string):LabDraft{
 if(raw.length>30000)throw Error('Too large');const v=JSON.parse(raw.replace(/^\s*```(?:json)?\s*/i,'').replace(/\s*```\s*$/,''));
 if(!v||!Array.isArray(v.results)||v.results.length<1||v.results.length>50)throw Error('No readable results');
 const date=text(v.report_date,10);if(date&&(!/^\d{4}-\d{2}-\d{2}$/.test(date)||!Number.isFinite(Date.parse(date))||new Date(date).toISOString().slice(0,10)!==date))throw Error('Invalid date');
 return{report_date:date,laboratory:text(v.laboratory,200),results:v.results.map((r:Record<string,unknown>)=>{
 if(!r||!['high','low','normal','unknown'].includes(String(r.report_flag)))throw Error('Invalid result');
 return{test:text(r.test,120,true)!,value:text(r.value,100),unit:text(r.unit,80),reference_range:text(r.reference_range,120),report_flag:r.report_flag as LabResult['report_flag'],source_excerpt:text(r.source_excerpt,300)};
 })};
}
export function summarizeLab(d:LabDraft){
 const flagged=d.results.filter(r=>r.report_flag==='high'||r.report_flag==='low');
 return `The report lists ${d.results.length} test result${d.results.length===1?'':'s'}. ${flagged.length} ${flagged.length===1?'is':'are'} explicitly marked high or low by the laboratory. ${flagged.slice(0,5).map(r=>`${r.test}: ${r.value??'value not readable'}${r.unit?' '+r.unit:''} (${r.report_flag})`).join('; ')}${flagged.length?'.':''} This describes the source report; it does not assess your health or recommend treatment.`;
}
