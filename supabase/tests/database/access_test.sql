begin;
create extension if not exists pgtap with schema extensions;
select plan(29);

insert into auth.users(id,email,email_confirmed_at) values
 ('10000000-0000-0000-0000-000000000001','owner@example.test',now()),
 ('10000000-0000-0000-0000-000000000002','family@example.test',now()),
 ('10000000-0000-0000-0000-000000000003','stranger@example.test',now());
insert into auth.identities(id,user_id,provider_id,provider,identity_data) values
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','fiction-family','google','{"email":"family@example.test","email_verified":true}'),
 ('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000003','fiction-stranger','google','{"email":"stranger@example.test","email_verified":true}');

set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
select lives_ok($$insert into public.documents(id,object_path,mime_type) values
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001/30000000-0000-0000-0000-000000000001.jpg','image/jpeg')$$,'Owner creates document');
select throws_ok($$insert into public.documents(id,object_path,mime_type) values
 ('30000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000003/30000000-0000-0000-0000-000000000003.jpg','image/jpeg')$$,'23514',null,'Owner cannot claim a different storage prefix');
select lives_ok($$select public.review_document('30000000-0000-0000-0000-000000000001','2026-09-03','FICTIONAL clinic',
 '[{"name":"Paracetamol","dosage":"500 mg","frequency":"as written","duration":"4 weeks","source_excerpt":"FICTIONAL test","taking_status":"unknown"}]')$$,'Review records literal fields');
select is((select count(*)::int from public.medications),1,'Reviewed medication stored');
select is((public.search_prescriptions('PARACETAMOL','2026-09-01','2026-09-30')->'matches'->0->>'dosage'),'500 mg','Case-insensitive name lookup uses prescription date');
select is(jsonb_array_length(public.search_prescriptions('Paracetamol','2026-10-01','2026-10-31')->'matches'),0,'Upload month is not substituted for prescription month');
select throws_ok($$select public.search_prescriptions(null,'2026-10-10','2026-10-01')$$,'P0001','Invalid date range','Reversed ranges rejected');
select lives_ok($$select public.publish_summary('FICTIONAL Owner','["Owner-reported example"]','Fictional demo',array(select id from public.medications))$$,'Owner publishes selected reviewed data');
select lives_ok($$select public.create_share('family@example.test',repeat('a',64))$$,'Owner creates recipient-bound share');
select is((select extract(epoch from expires_at-created_at)::int from public.shares),86400,'Expiry is exactly 24 hours from creation');
select ok(not (select snapshot ? 'object_path' from public.shares),'Snapshot excludes original paths');
select lives_ok($$select public.save_contacts('FICTIONAL Owner','[{"name":"FICTIONAL Contact","relationship":"Example","phone":"+91 99999 00000","medical":"not allowed"}]',repeat('b',64))$$,'Contact projection strips extra fields');

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
select is((select count(*)::int from public.documents),0,'Other user cannot read originals');
select is((select count(*)::int from public.medications),0,'Other user cannot read medications');
select is((select count(*)::int from public.summaries),0,'Other user cannot directly read published summaries');
select is(jsonb_array_length(public.search_prescriptions()->'matches'),0,'Lookup is owner-only');
select throws_ok($$select public.accept_share(repeat('a',64))$$,'P0001','Share unavailable for this account','Forwarded link rejected for wrong Google account');
select throws_ok($$select public.review_document('30000000-0000-0000-0000-000000000001',null,null,'[]')$$,'P0001','Record unavailable','Other user cannot review owner record');

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
reset role;
update auth.identities set identity_data='{"email":"other@example.test","email_verified":true}'
  where provider_id='fiction-family';
set local role authenticated;
select throws_ok($$select public.accept_share(repeat('a',64))$$,'P0001','Sign in with the invited Google account','Linked Google email must match the invited primary email');
reset role;
update auth.identities set identity_data='{"email":"family@example.test","email_verified":false}'
  where provider_id='fiction-family';
set local role authenticated;
select throws_ok($$select public.accept_share(repeat('a',64))$$,'P0001','Sign in with the invited Google account','Google must verify the invited email');
reset role;
update auth.identities set identity_data='{"email":"family@example.test","email_verified":true}'
  where provider_id='fiction-family';
set local role authenticated;
select lives_ok($$select public.accept_share(repeat('a',64))$$,'Invited Google identity accepts');
select lives_ok($$select public.accept_share(repeat('a',64))$$,'Same identity can accept idempotently');
reset role;
select is((public.read_shared_summary((select id from public.shares where token_hash=repeat('a',64)))->>'display_name'),'FICTIONAL Owner','Permitted reader receives snapshot');
select is((select count(*)::int from storage.buckets where id='prescriptions' and public=false),1,'Original storage bucket is private');
select ok(not (public.resolve_contact(repeat('b',64))->'contacts'->0 ? 'medical'),'Anonymous projection cannot include medical fields');
update public.shares set created_at=now()-interval '25 hours',expires_at=now()-interval '1 hour';
select throws_ok($$select public.read_shared_summary((select id from public.shares where token_hash=repeat('a',64)))$$,'P0001','Share unavailable','Expired grant rejected independently of JWT');
update public.shares set created_at=now(),expires_at=now()+interval '24 hours',revoked_at=now();
select throws_ok($$select public.read_shared_summary((select id from public.shares where token_hash=repeat('a',64)))$$,'P0001','Share unavailable','Revoked grant rejected');
set local role anon;
select throws_ok($$select public.search_prescriptions()$$,'42501',null,'Anonymous cannot search prescriptions');
select throws_ok($$select public.resolve_contact(repeat('b',64))$$,'42501',null,'Anonymous cannot bypass rate-limited contact endpoint');
reset role;
select * from finish();
rollback;
