import {createClient} from '@supabase/supabase-js';
import {button,card,element,field,formatTime,safePhone} from './ui';
import {captureLink,hashToken,isExpired,withDeadline,type Summary,type ContactCard} from './sharing';
import './style.css';

const root = document.querySelector<HTMLDivElement>('#app')!;
const header = element('header',undefined,'site-header');
const brand = element('a','kin','brand'); brand.href='/';
header.append(brand,element('span','Shared with care','header-caption'));
const main = element('main'); main.id='main';
const footer = element('footer','Your information. Your permission. ');
const privacyLink=element('a','Privacy','text-link');privacyLink.href='/privacy';footer.append(privacyLink);
root.append(header,main,footer);
const url = import.meta.env.VITE_SUPABASE_PROXY === 'true'
  ? `${location.origin}/backend` : import.meta.env.VITE_SUPABASE_URL as string | undefined;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
const client = url && key ? createClient(url,key,{auth:{flowType:'pkce',storage:sessionStorage,persistSession:true,detectSessionInUrl:true}}) : null;
const captured = captureLink(window.location);
if (captured) {
  sessionStorage.setItem(`kin.${captured.kind}.token`,captured.token);
  history.replaceState(null,'',window.location.pathname);
}
let poll: ReturnType<typeof setInterval> | undefined;
let expiration: ReturnType<typeof setTimeout> | undefined;
let generation = 0;
let activeKind: 'summary' | 'contacts' | null = null;
function clearDisplay() {
  generation++; clearInterval(poll); clearTimeout(expiration); main.replaceChildren();
}
function heading(eyebrow: string,title: string,description: string) {
  main.append(element('p',eyebrow,'eyebrow'),element('h1',title),element('p',description,'intro'));
}
function message(title: string,text: string,retry?:()=>Promise<void>) {
  clearDisplay(); heading('KIN / SECURE SHARING',title,text);
  if (retry) main.append(button('Try again',retry));
}
async function signOut() {
  clearDisplay(); sessionStorage.removeItem('kin.share.id'); sessionStorage.removeItem('kin.s.token');
  await client?.auth.signOut(); await route();
}
function sessionControls() { main.append(button('Sign out',signOut,true)); }

async function showSummary() {
  try {await loadSummary();}
  catch {message('Access could not be checked','Medical information is hidden. Check your connection and retry.',showSummary);sessionControls();}
}
async function loadSummary() {
  if (!client) return;
  clearDisplay(); activeKind='summary'; const current = generation;
  heading('KIN / MEDICAL SUMMARY','Opening your shared summary…','Checking your permission securely.');
  const {data:sessionData} = await withDeadline(client.auth.getSession());
  if (current!==generation) return;
  if (!sessionData.session) {
    if (import.meta.env.VITE_GOOGLE_ENABLED === 'false') {
      message('Google sharing is not connected',
        'This local build can show contact cards. Private medical invitations need the invited Google account; Google sign-in has not been configured yet.');
      return;
    }
    clearDisplay(); heading('INVITATION / 24-HOUR ACCESS','A little context. Better care.',
      'Sign in with the Google account the owner invited. You can read only the information they chose to share.');
    const info=card('Private by permission');
    info.append(element('p','Original prescriptions and full medical history stay private. This link expires 24 hours after the owner created it.'));
    main.append(info,button('Continue with Google',async()=>{
      const {error}=await client.auth.signInWithOAuth({provider:'google',options:{redirectTo:`${location.origin}/auth/callback`,queryParams:{prompt:'select_account'}}});
      if (error) message('Could not sign in','Please retry. The owner can also send a new invitation.',showSummary);
    })); return;
  }
  const token=sessionStorage.getItem('kin.s.token');
  let shareId=sessionStorage.getItem('kin.share.id');
  if (token) {
    const {data,error}=await withDeadline(client.rpc('accept_share',{p_token_hash:await hashToken(token)}));
    if (current!==generation) return;
    if (error || typeof data!=='string') {
      message('This share is unavailable','Use the invited Google account. The link may also have expired or been revoked.',showSummary);
      sessionControls(); return;
    }
    shareId=data; sessionStorage.setItem('kin.share.id',data); sessionStorage.removeItem('kin.s.token');
  }
  if (!shareId) {message('Open an invitation','Ask the owner to send their Kin link.');sessionControls();return;}
  const refresh=async()=>{
    const {data,error}=await withDeadline(client.rpc('read_shared_summary',{p_share_id:shareId}));
    if (current!==generation) return;
    if (error || !data || isExpired(data.expires_at)) {
      message('Access has ended','The share expired, was revoked, or could not be checked. No medical information is displayed.',showSummary);
      sessionControls(); return;
    }
    const summary=data as Summary;
    main.replaceChildren();
    heading('OWNER REVIEWED / SELECTED INFORMATION',`${summary.display_name}’s summary`,
      'Historical prescriptions and owner-reported details. Owner review is not clinical verification.');
    const status=element('div',undefined,'notice');
    status.append(element('strong','View-only access'),element('p',`Expires ${formatTime(summary.expires_at)}. Snapshot published ${formatTime(summary.updated_at)}.`));
    main.append(status);
    const allergies=card('Owner-reported allergies');
    if (!summary.allergies.length) allergies.append(element('p','None recorded. This does not establish absence of allergies.'));
    else {const list=element('ul');for (const allergy of summary.allergies) list.append(element('li',allergy));allergies.append(list);}
    const medicines=card('Selected prescription medicines');
    if (!summary.medicines.length) medicines.append(element('p','No medicines selected by the owner.'));
    for (const med of summary.medicines) {
      const item=element('article',undefined,'medicine'); item.append(element('h3',med.name));
      item.append(field('Prescribed dosage',med.dosage),field('Frequency',med.frequency),field('Duration',med.duration),field('Prescription date',med.prescription_date));
      item.append(field('Owner-reported use',med.taking_status==='taking'?'Reported taking':med.taking_status==='stopped'?'Reported stopped':'Not confirmed'),field('Owner reviewed',formatTime(med.reviewed_at)));
      medicines.append(item);
    }
    main.append(allergies,medicines);
    if (summary.notes) {const notes=card('Owner’s notes');notes.append(element('p',summary.notes,'preserve-lines'));main.append(notes);}
    main.append(element('p','This prototype provides context from records. It does not recommend treatment or replace clinical assessment.','fine-print'));
    sessionControls();
    clearTimeout(expiration);
    expiration=setTimeout(()=>{message('Access has ended','This share has expired.');sessionControls();},Math.max(0,Date.parse(summary.expires_at)-Date.now()));
  };
  await refresh();
  if (current===generation) poll=setInterval(()=>{void refresh().catch(()=>{
    if(current===generation){message('Access could not be checked','Medical information is hidden. Check your connection and retry.',showSummary);sessionControls();}
  });},15000);
}

async function showContacts() {
  try {await loadContacts();}
  catch {message('Contact service unavailable','Check your connection and retry.',showContacts);}
}
async function loadContacts() {
  if (!client) return;
  clearDisplay(); activeKind='contacts';const current=generation;
  const token=sessionStorage.getItem('kin.e.token');
  if (!token) {message('Contact card unavailable','Scan the owner’s contact QR or open their contact link.');return;}
  heading('KIN / CONTACT CARD','Opening emergency contacts…','No sign-in or installation required.');
  const {data,error}=await withDeadline(client.functions.invoke('emergency-contact',{body:{token}}));
  if (current!==generation) return;
  if (error || !data) {message('Contact card unavailable','The card may have been revoked, or the service is temporarily unavailable.',showContacts);return;}
  const contacts=data as ContactCard;
  main.replaceChildren(); heading('PUBLIC / OWNER-CHOSEN CONTACTS',`Contacts for ${contacts.display_name}`,
    'The owner made these contacts available to anyone with this link. No medical records are included.');
  for (const contact of contacts.contacts) {
    const block=card(contact.name);block.append(element('p',contact.relationship));
    const phone=safePhone(contact.phone);
    if (phone) {const call=element('a',`Call ${contact.phone}`,'button');call.href=`tel:${phone}`;block.append(call);}
    main.append(block);
  }
  if (!contacts.contacts.length) main.append(element('p','No contacts are currently listed.'));
  main.append(element('p',`Updated ${formatTime(contacts.updated_at)}`,'fine-print'));
  // The contact service may be revoked too; recheck on foreground and periodically.
  poll=setInterval(()=>{void showContacts();},30000);
}
async function route() {
  const path=location.pathname;
  if (path==='/privacy') {
    clearDisplay();heading('KIN / PRIVACY','Your information. Your permission.',
      'How Kin handles your account, records and shared information.');
    for (const [title,text] of [
      ['Account access','Google sign-in identifies your account using your basic profile and email. Kin does not request Google Drive or Gmail access.'],
      ['Private records','Prescription images and history are accessible to their owner. Requesting AI extraction sends the selected image to the configured AI provider through the server. The server and provider process readable data; end-to-end encryption is not claimed.'],
      ['Selected sharing','Medical invitations show a selected summary to the invited Google account for 24 hours. Originals and full history remain private. Public contact cards show chosen contacts to anyone with their link.'],
      ['Your controls','You can delete prescriptions and revoke invitations or contact cards. Revocation stops future access, but cannot erase existing copies. Account erasure and backup retention still require operator handling.'],
      ['Hackathon use','Use fictional records for this hackathon build. Kin provides information from records and does not diagnose, prescribe or recommend treatment.'],
    ]) {const block=card(title);block.append(element('p',text));main.append(block);}
    return;
  }
  if (!client && ['/e','/s','/auth/callback'].includes(path)) {
    message('Service not connected','This build is not connected to the sharing service. Ask the owner for a link from the configured app.');return;
  }
  if (path==='/e') await showContacts();
  else if (path==='/s' || path==='/auth/callback') {
    // getSession waits for the SDK’s PKCE callback handling before accepting the pending link.
    await client?.auth.getSession();
    if (path==='/auth/callback') history.replaceState(null,'','/s');
    await showSummary();
  } else {
    clearDisplay();heading('KIN / YOUR INFORMATION, YOUR PERMISSION','Care begins with context.',
      'A reviewed medical summary, shared with permission, opened in any browser.');
    const details=element('div',undefined,'home-grid');
    for (const [title,text] of [['Private records','Original prescriptions belong to their owner.'],['Chosen access','Medical summaries require the invited Google account and expire after 24 hours.'],['Contacts in a scan','A separate contact QR opens immediately. No app installation.']]) {
      const block=card(title);block.append(element('p',text));details.append(block);
    }
    main.append(details,element('p','Open a link sent by a Kin owner to continue.','notice'));
    const repo=element('a','Explore the open-source project','text-link');repo.href='https://github.com/ashuujha/kin';repo.rel='noreferrer';main.append(repo);
  }
}
document.addEventListener('visibilitychange',()=>{
  if (document.hidden) clearDisplay();
  else if (activeKind==='contacts') void showContacts();
  else void route();
});
client?.auth.onAuthStateChange((event)=>{if(event==='SIGNED_OUT'){clearDisplay();}});
void route();
