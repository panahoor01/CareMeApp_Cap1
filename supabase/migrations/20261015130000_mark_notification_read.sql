create or replace function public.mark_notification_read(
  p_notification_id text
)
returns void
language plpgsql
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  update public.notifications n
     set is_read = true
   where n.notification_id::text = p_notification_id
     and n.recipient_id = v_uid
     and not n.is_read;
end;
$function$;

revoke all on function public.mark_notification_read(text) from public, anon;
grant execute on function public.mark_notification_read(text) to authenticated;