create table public.linked_reports (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 title text not null check(length(trim(title)) between 1 and 160), url text not null check(length(url)<=2048 and url ~ '^https://[^/@?#[:space:]]+(/|$)'),
 kind text not null check(kind in ('drive','dicom','lab_portal','other')), created_at timestamptz not null default now()
);
alter table public.linked_reports enable row level security;
create policy linked_owner on public.linked_reports for all to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
revoke all on public.linked_reports from public,anon,authenticated;
grant select,delete on public.linked_reports to authenticated;
grant insert(title,url,kind) on public.linked_reports to authenticated;
create table public.lab_reports (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 title text not null check(length(trim(title)) between 1 and 160), object_path text not null unique,
 mime_type text not null check(mime_type in ('application/pdf','image/jpeg','image/png')),
 status text not null default 'uploaded' check(status in ('uploaded','processing','draft','failed','reviewed')),
 draft jsonb, results jsonb not null default '[]', report_date date, laboratory text check(length(laboratory)<=200),
 summary text, reviewed_at timestamptz, created_at timestamptz not null default now(),
 check(object_path=owner_id::text || '/' || id::text || case mime_type when 'application/pdf' then '.pdf' when 'image/png' then '.png' else '.jpg' end)
);
create index lab_reports_owner_date on public.lab_reports(owner_id,report_date);
alter table public.lab_reports enable row level security;
create policy labs_read on public.lab_reports for select to authenticated using(owner_id=(select auth.uid()));
create policy labs_insert on public.lab_reports for insert to authenticated with check(owner_id=(select auth.uid()));
revoke all on public.lab_reports from public,anon,authenticated;
grant select on public.lab_reports to authenticated;
grant insert(id,title,object_path,mime_type) on public.lab_reports to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('lab-reports','lab-reports',false,5242880,array['application/pdf','image/png','image/jpeg']);
create policy labs_upload on storage.objects for insert to authenticated with check(bucket_id='lab-reports' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy labs_download on storage.objects for select to authenticated using(bucket_id='lab-reports' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy labs_delete on storage.objects for delete to authenticated using(bucket_id='lab-reports' and (storage.foldername(name))[1]=(select auth.uid())::text);
create function public.review_lab(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 update public.lab_reports set results=draft->'results',report_date=nullif(draft->>'report_date','')::date,laboratory=draft->>'laboratory',
 status='reviewed',reviewed_at=now() where id=p_id and owner_id=auth.uid() and status='draft' and jsonb_typeof(draft->'results')='array';
 if not found then raise exception 'Draft unavailable'; end if;
 insert into private.audit_events(actor_id,action,resource_id) values(auth.uid(),'review_lab',p_id);
end $$;
create table public.emergency_profiles (
 owner_id uuid primary key references auth.users(id) on delete cascade, token_hash text not null unique check(token_hash ~ '^[a-f0-9]{64}$'),
 snapshot jsonb not null, updated_at timestamptz not null default now()
);
alter table public.emergency_profiles enable row level security;
create policy emergency_owner_read on public.emergency_profiles for select to authenticated using(owner_id=(select auth.uid()));
revoke all on public.emergency_profiles from public,anon,authenticated;
grant select on public.emergency_profiles to authenticated;
create function public.publish_emergency(p_token_hash text,p_lab_ids uuid[] default '{}') returns void language plpgsql security definer set search_path='' as $$
declare v_summary jsonb; v_labs jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if p_token_hash is null or p_token_hash !~ '^[a-f0-9]{64}$' or p_lab_ids is null or cardinality(p_lab_ids)>10 then raise exception 'Invalid selection'; end if;
 if exists(select 1 from unnest(p_lab_ids) x where not exists(select 1 from public.lab_reports l where l.id=x and l.owner_id=auth.uid() and l.status='reviewed')) then raise exception 'Reviewed reports unavailable'; end if;
 select jsonb_build_object('display_name',display_name,'allergies',allergies,'medicines',medicines,'notes',notes,'summary_updated_at',updated_at) into v_summary from public.summaries where owner_id=auth.uid();
 if v_summary is null then raise exception 'Publish a selected summary first'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('title',l.title,'report_date',l.report_date,'laboratory',l.laboratory,'reviewed_at',l.reviewed_at,'results',
 (select coalesce(jsonb_agg(jsonb_build_object('test',r->>'test','value',r->>'value','unit',r->>'unit','reference_range',r->>'reference_range','report_flag',r->>'report_flag')),'[]') from jsonb_array_elements(l.results) r)) order by l.report_date desc nulls last),'[]') into v_labs from public.lab_reports l where l.owner_id=auth.uid() and l.id=any(p_lab_ids) and l.status='reviewed';
 insert into public.emergency_profiles(owner_id,token_hash,snapshot) values(auth.uid(),p_token_hash,v_summary || jsonb_build_object('labs',v_labs))
 on conflict(owner_id) do update set token_hash=excluded.token_hash,snapshot=excluded.snapshot,updated_at=now();
 insert into private.audit_events(actor_id,action) values(auth.uid(),'publish_public_emergency');
end $$;
create function public.revoke_emergency() returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 delete from public.emergency_profiles where owner_id=auth.uid();
 insert into private.audit_events(actor_id,action) values(auth.uid(),'revoke_public_emergency');
end $$;
create function public.resolve_emergency(p_token_hash text) returns jsonb language sql stable security definer set search_path='' as $$
 select snapshot || jsonb_build_object('updated_at',updated_at,'access','owner_opted_in_public_emergency') from public.emergency_profiles where token_hash=p_token_hash;
$$;
create function private.invalidate_emergency() returns trigger language plpgsql security definer set search_path='' as $$
begin delete from public.emergency_profiles where owner_id=old.owner_id;return old;end $$;
create trigger document_delete_emergency after delete on public.documents for each row execute function private.invalidate_emergency();
create trigger lab_delete_emergency after delete on public.lab_reports for each row execute function private.invalidate_emergency();
create function public.delete_lab(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin delete from public.lab_reports where id=p_id and owner_id=auth.uid();if not found then raise exception 'Report unavailable';end if;end $$;
revoke all on function public.review_lab(uuid),public.publish_emergency(text,uuid[]),public.revoke_emergency(),public.resolve_emergency(text),public.delete_lab(uuid) from public,anon,authenticated;
grant execute on function public.review_lab(uuid),public.publish_emergency(text,uuid[]),public.revoke_emergency(),public.delete_lab(uuid) to authenticated;
grant execute on function public.resolve_emergency(text) to service_role;
revoke all on function private.invalidate_emergency() from public,anon,authenticated;
