create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  object_path text not null unique,
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png')),
  status text not null default 'uploaded' check (status in ('uploaded','processing','draft','failed','reviewed')),
  draft jsonb,
  prescription_date date,
  clinic text check (length(clinic) <= 200),
  extraction_method text check (extraction_method in ('gemma','manual')),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  check (object_path = owner_id::text || '/' || id::text || case mime_type when 'image/png' then '.png' else '.jpg' end)
);
create index documents_owner_date on public.documents(owner_id, prescription_date);
create table public.medications (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.documents(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 120),
  dosage text check (length(dosage) <= 200),
  frequency text check (length(frequency) <= 200),
  duration text check (length(duration) <= 200),
  source_excerpt text check (length(source_excerpt) <= 500),
  taking_status text not null default 'unknown' check (taking_status in ('unknown','taking','stopped'))
);
create index medications_owner_name on public.medications(owner_id, lower(name));
create table public.summaries (
  owner_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  display_name text not null check (length(display_name) between 1 and 120),
  allergies jsonb not null default '[]',
  medicines jsonb not null default '[]',
  notes text not null default '' check (length(notes) <= 1000),
  updated_at timestamptz not null default now()
);
create table public.shares (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  recipient_email text not null,
  token_hash text not null unique check (token_hash ~ '^[a-f0-9]{64}$'),
  recipient_id uuid references auth.users(id) on delete set null,
  snapshot jsonb not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  accepted_at timestamptz,
  revoked_at timestamptz,
  check (expires_at = created_at + interval '24 hours')
);
create table public.contacts (
  owner_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  token_hash text unique check (token_hash ~ '^[a-f0-9]{64}$'),
  display_name text not null check (length(display_name) between 1 and 120),
  entries jsonb not null default '[]',
  updated_at timestamptz not null default now()
);
create table private.rate_limits (
  key_hash text not null,
  window_start timestamptz not null,
  hits integer not null default 1,
  primary key(key_hash, window_start)
);
create table private.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid,
  action text not null,
  resource_id uuid,
  created_at timestamptz not null default now()
);

alter table public.documents enable row level security;
alter table public.medications enable row level security;
alter table public.summaries enable row level security;
alter table public.shares enable row level security;
alter table public.contacts enable row level security;
create policy documents_read on public.documents for select to authenticated using (owner_id = (select auth.uid()));
create policy documents_insert on public.documents for insert to authenticated with check (owner_id = (select auth.uid()));
create policy medications_read on public.medications for select to authenticated using (owner_id = (select auth.uid()));
create policy summaries_read on public.summaries for select to authenticated using (owner_id = (select auth.uid()));
create policy shares_read on public.shares for select to authenticated using (owner_id = (select auth.uid()));
create policy contacts_read on public.contacts for select to authenticated using (owner_id = (select auth.uid()));
revoke all on public.documents, public.medications, public.summaries, public.shares, public.contacts from anon, authenticated;
grant select on public.documents, public.medications, public.summaries, public.shares, public.contacts to authenticated;
grant insert (id, object_path, mime_type) on public.documents to authenticated;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('prescriptions','prescriptions',false,5242880,array['image/jpeg','image/png']);
create policy private_upload on storage.objects for insert to authenticated
with check (bucket_id = 'prescriptions' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy private_download on storage.objects for select to authenticated
using (bucket_id = 'prescriptions' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy private_delete on storage.objects for delete to authenticated
using (bucket_id = 'prescriptions' and (storage.foldername(name))[1] = (select auth.uid())::text);

create function public.review_document(p_document_id uuid, p_date date, p_clinic text, p_medications jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare item jsonb; v_owner uuid := auth.uid();
begin
  if v_owner is null then raise exception 'Authentication required'; end if;
  if not public.check_rate_limit('review:'||v_owner::text,60,3600) then raise exception 'Too many requests'; end if;
  perform 1 from public.documents where id=p_document_id and owner_id=v_owner for update;
  if not found then raise exception 'Record unavailable'; end if;
  if jsonb_typeof(p_medications) is distinct from 'array' or jsonb_array_length(p_medications) > 30 then
    raise exception 'Invalid medications';
  end if;
  delete from public.medications where document_id=p_document_id;
  for item in select value from jsonb_array_elements(p_medications) loop
    insert into public.medications(document_id, owner_id, name, dosage, frequency, duration, source_excerpt, taking_status)
    values(p_document_id, v_owner, trim(item->>'name'), item->>'dosage', item->>'frequency',
      item->>'duration', item->>'source_excerpt', coalesce(item->>'taking_status','unknown'));
  end loop;
  update public.documents set prescription_date=p_date, clinic=p_clinic, status='reviewed',
    reviewed_at=now(), extraction_method=coalesce(extraction_method,'manual') where id=p_document_id;
  -- Editing a source invalidates existing publication of that source and all snapshots.
  update public.summaries set medicines='[]',updated_at=now() where owner_id=v_owner;
  update public.shares set revoked_at=coalesce(revoked_at,now()) where owner_id=v_owner;
  insert into private.audit_events(actor_id,action,resource_id) values(v_owner,'review',p_document_id);
end $$;

create function public.search_prescriptions(p_medicine text default null, p_from date default null, p_to date default null)
returns jsonb language plpgsql stable security invoker set search_path = '' as $$
declare v_matches jsonb; v_undated integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_from is not null and p_to is not null and p_from > p_to then raise exception 'Invalid date range'; end if;
  select coalesce(jsonb_agg(row_to_json(t) order by t.prescription_date desc nulls last),'[]') into v_matches from (
    select m.*, d.prescription_date, d.reviewed_at, d.extraction_method, d.clinic
    from public.medications m join public.documents d on d.id=m.document_id
    where m.owner_id=auth.uid() and d.status='reviewed'
      and (p_medicine is null or lower(m.name)=lower(trim(p_medicine)))
      and (p_from is null or d.prescription_date >= p_from)
      and (p_to is null or d.prescription_date <= p_to)
    order by d.prescription_date desc nulls last limit 200
  ) t;
  select count(*) into v_undated from public.medications m join public.documents d on d.id=m.document_id
  where m.owner_id=auth.uid() and d.status='reviewed' and d.prescription_date is null
    and (p_medicine is null or lower(m.name)=lower(trim(p_medicine)));
  return jsonb_build_object('matches',v_matches,'undated_count',v_undated);
end $$;

create function public.publish_summary(p_name text, p_allergies jsonb, p_notes text, p_medication_ids uuid[])
returns void language plpgsql security definer set search_path = '' as $$
declare v_owner uuid := auth.uid(); v_meds jsonb;
begin
  if v_owner is null then raise exception 'Authentication required'; end if;
  if not public.check_rate_limit('publish:'||v_owner::text,60,3600) then raise exception 'Too many requests'; end if;
  if jsonb_typeof(p_allergies) is distinct from 'array' or jsonb_array_length(p_allergies)>30
    or exists(select 1 from jsonb_array_elements(p_allergies) a where jsonb_typeof(a)<>'string' or length(a#>>'{}')>200)
    or coalesce(cardinality(p_medication_ids),0)>30 then raise exception 'Invalid summary'; end if;
  if exists(select 1 from unnest(p_medication_ids) mid where not exists(
    select 1 from public.medications m join public.documents d on d.id=m.document_id
    where m.id=mid and m.owner_id=v_owner and d.status='reviewed')) then raise exception 'Record unavailable'; end if;
  select coalesce(jsonb_agg(jsonb_build_object('name',m.name,'dosage',m.dosage,'frequency',m.frequency,
    'duration',m.duration,'taking_status',m.taking_status,'prescription_date',d.prescription_date,
    'reviewed_at',d.reviewed_at)),'[]') into v_meds
    from public.medications m join public.documents d on d.id=m.document_id
    where m.owner_id=v_owner and m.id=any(p_medication_ids) and d.status='reviewed';
  insert into public.summaries(owner_id,display_name,allergies,medicines,notes)
    values(v_owner,trim(p_name),p_allergies,v_meds,coalesce(p_notes,''))
    on conflict(owner_id) do update set display_name=excluded.display_name,allergies=excluded.allergies,
      medicines=excluded.medicines,notes=excluded.notes,updated_at=now();
  insert into private.audit_events(actor_id,action) values(v_owner,'publish');
end $$;

create function public.create_share(p_email text, p_token_hash text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_owner uuid:=auth.uid(); v_snapshot jsonb; v_share public.shares;
begin
  if v_owner is null then raise exception 'Authentication required'; end if;
  if not public.check_rate_limit('create-share:'||v_owner::text,30,3600) then raise exception 'Too many requests'; end if;
  if length(p_email)>254 or p_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then raise exception 'Invalid email'; end if;
  select jsonb_build_object('display_name',display_name,'allergies',allergies,'medicines',medicines,
    'notes',notes,'updated_at',updated_at) into v_snapshot from public.summaries where owner_id=v_owner;
  if v_snapshot is null then raise exception 'Publish a summary first'; end if;
  if (select count(*) from public.shares where owner_id=v_owner and revoked_at is null and expires_at>now())>=20
    then raise exception 'Revoke an existing share first'; end if;
  insert into public.shares(owner_id,recipient_email,token_hash,snapshot)
    values(v_owner,lower(trim(p_email)),p_token_hash,v_snapshot) returning * into v_share;
  insert into private.audit_events(actor_id,action,resource_id) values(v_owner,'share_create',v_share.id);
  return jsonb_build_object('id',v_share.id,'expires_at',v_share.expires_at);
end $$;

create function public.accept_share(p_token_hash text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid(); v_email text; v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not public.check_rate_limit('accept-share:'||auth.uid()::text,30,600) then raise exception 'Too many requests'; end if;
  select lower(u.email) into v_email from auth.users u where u.id=v_user and u.email_confirmed_at is not null
    and exists(select 1 from auth.identities i where i.user_id=u.id and i.provider='google');
  if v_email is null then raise exception 'Sign in with the invited Google account'; end if;
  update public.shares set recipient_id=v_user,accepted_at=coalesce(accepted_at,now())
    where token_hash=p_token_hash and recipient_email=v_email and revoked_at is null and expires_at>now()
      and (recipient_id is null or recipient_id=v_user) returning id into v_id;
  if v_id is null then raise exception 'Share unavailable for this account'; end if;
  insert into private.audit_events(actor_id,action,resource_id) values(v_user,'share_accept',v_id);
  return v_id;
end $$;

create function public.read_shared_summary(p_share_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_summary jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not public.check_rate_limit('read-share:'||auth.uid()::text,500,3600) then raise exception 'Too many requests'; end if;
  select snapshot || jsonb_build_object('expires_at',expires_at) into v_summary from public.shares
    where id=p_share_id and recipient_id=auth.uid() and revoked_at is null and expires_at>now();
  if v_summary is null then raise exception 'Share unavailable'; end if;
  return v_summary;
end $$;
create function public.revoke_share(p_share_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.shares set revoked_at=coalesce(revoked_at,now()) where id=p_share_id and owner_id=auth.uid();
  if not found then raise exception 'Share unavailable'; end if;
  insert into private.audit_events(actor_id,action,resource_id) values(auth.uid(),'share_revoke',p_share_id);
end $$;

create function public.save_contacts(p_name text, p_entries jsonb, p_token_hash text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(p_entries) is distinct from 'array' or jsonb_array_length(p_entries)>5
    or exists(select 1 from jsonb_array_elements(p_entries) e where
      jsonb_typeof(e) <> 'object' or length(coalesce(e->>'name','')) not between 1 and 120
      or length(coalesce(e->>'relationship',''))>80 or coalesce(e->>'phone','') !~ '^\+?[0-9 ()-]{5,25}$')
    then raise exception 'Invalid contacts'; end if;
  insert into public.contacts(owner_id,display_name,entries,token_hash)
    values(auth.uid(),trim(p_name),(select coalesce(jsonb_agg(jsonb_build_object('name',e->>'name',
      'relationship',e->>'relationship','phone',e->>'phone')),'[]') from jsonb_array_elements(p_entries) e),p_token_hash)
    on conflict(owner_id) do update set display_name=excluded.display_name,entries=excluded.entries,
      token_hash=excluded.token_hash,updated_at=now();
  insert into private.audit_events(actor_id,action) values(auth.uid(),'contacts_change');
end $$;
create function public.resolve_contact(p_token_hash text)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('display_name',display_name,'contacts',entries,'updated_at',updated_at)
  from public.contacts where token_hash=p_token_hash;
$$;
create function public.check_rate_limit(p_key_hash text, p_limit integer, p_window_seconds integer)
returns boolean language plpgsql security definer set search_path = '' as $$
declare v_count integer; v_window timestamptz;
begin
  if p_limit<1 or p_window_seconds<1 then raise exception 'Invalid limit'; end if;
  v_window:=to_timestamp(floor(extract(epoch from now())/p_window_seconds)*p_window_seconds);
  insert into private.rate_limits(key_hash,window_start) values(p_key_hash,v_window)
    on conflict(key_hash,window_start) do update set hits=private.rate_limits.hits+1 returning hits into v_count;
  delete from private.rate_limits where window_start<now()-interval '2 days';
  return v_count<=p_limit;
end $$;
create function public.delete_document(p_document_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  delete from public.documents where id=p_document_id and owner_id=auth.uid();
  if not found then raise exception 'Record unavailable'; end if;
  update public.summaries set medicines='[]',updated_at=now() where owner_id=auth.uid();
  update public.shares set revoked_at=coalesce(revoked_at,now()) where owner_id=auth.uid();
  insert into private.audit_events(actor_id,action,resource_id) values(auth.uid(),'delete_document',p_document_id);
end $$;

-- Functions are executable by PUBLIC unless explicitly revoked.
revoke all on function public.review_document(uuid,date,text,jsonb),public.search_prescriptions(text,date,date),
  public.publish_summary(text,jsonb,text,uuid[]),public.create_share(text,text),public.accept_share(text),
  public.read_shared_summary(uuid),public.revoke_share(uuid),public.save_contacts(text,jsonb,text),
  public.resolve_contact(text),public.check_rate_limit(text,integer,integer),public.delete_document(uuid) from public,anon,authenticated;
grant execute on function public.review_document(uuid,date,text,jsonb),public.search_prescriptions(text,date,date),
  public.publish_summary(text,jsonb,text,uuid[]),public.create_share(text,text),public.accept_share(text),
  public.read_shared_summary(uuid),public.revoke_share(uuid),public.save_contacts(text,jsonb,text),public.delete_document(uuid) to authenticated;
grant execute on function public.resolve_contact(text),public.check_rate_limit(text,integer,integer) to service_role;
