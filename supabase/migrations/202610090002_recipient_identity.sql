-- A linked Google identity must verify the invited email itself. Merely linking
-- any Google account to a confirmed primary email does not prove that control.
create or replace function public.accept_share(p_token_hash text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid(); v_email text; v_id uuid;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if not public.check_rate_limit('accept-share:'||v_user::text,30,600) then raise exception 'Too many requests'; end if;
  select lower(u.email) into v_email from auth.users u
    where u.id=v_user and u.email_confirmed_at is not null
      and exists(select 1 from auth.identities i
        where i.user_id=u.id and i.provider='google'
          and lower(i.identity_data->>'email')=lower(u.email)
          and i.identity_data->'email_verified'='true'::jsonb);
  if v_email is null then raise exception 'Sign in with the invited Google account'; end if;
  update public.shares set recipient_id=v_user,accepted_at=coalesce(accepted_at,now())
    where token_hash=p_token_hash and recipient_email=v_email and revoked_at is null and expires_at>now()
      and (recipient_id is null or recipient_id=v_user) returning id into v_id;
  if v_id is null then raise exception 'Share unavailable for this account'; end if;
  insert into private.audit_events(actor_id,action,resource_id) values(v_user,'share_accept',v_id);
  return v_id;
end $$;

revoke all on function public.accept_share(text) from public,anon;
grant execute on function public.accept_share(text) to authenticated;
