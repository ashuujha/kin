import {parseLab,summarizeLab} from '../extract-lab/schema.ts';
Deno.test('Lab parser preserves literal values and never invents flags',()=>{
 const d=parseLab(JSON.stringify({report_date:null,laboratory:'FICTIONAL',results:[{test:'Glucose',value:'110',unit:'mg/dL',reference_range:'70-100',report_flag:'unknown',source_excerpt:'Glucose 110 mg/dL'}]}));
 if(d.results[0].report_flag!=='unknown'||!summarizeLab(d).includes('0 are explicitly'))throw Error('Invented interpretation');
});
Deno.test('Lab parser rejects invalid dates and diagnosis-shaped results',()=>{
 for(const v of [{report_date:'2026-02-30',results:[]},{results:[{test:'Glucose',report_flag:'diabetes'}]}]){let rejected=false;try{parseLab(JSON.stringify(v));}catch{rejected=true;}if(!rejected)throw Error('Invalid data accepted');}
});
