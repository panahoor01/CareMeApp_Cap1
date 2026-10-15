create extension if not exists pg_cron with schema pg_catalog;

create table if not exists public.booking_schedule_events (
  booking_id uuid not null references public.bookings(booking_id) on delete cascade,
  event_type text not null check (event_type in ('upcoming_10m', 'ongoing')),
  created_at timestamptz not null default now(),
  primary key (booking_id, event_type)
);

revoke all on public.booking_schedule_events from public, anon, authenticated;

create table if not exists public.booking_trip_locations (
  booking_id uuid primary key
    references public.bookings(booking_id) on delete cascade,
  beautician_id uuid not null references public.users(id) on delete cascade,
  latitude double precision,
  longitude double precision,
  updated_at timestamptz not null default now(),
  constraint booking_trip_location_pair_chk check (
    (latitude is null and longitude is null)
    or (
      latitude is not null
      and longitude is not null
      and
      latitude between -90 and 90
      and longitude between -180 and 180
    )
  )
);

alter table public.booking_trip_locations enable row level security;
create schema if not exists careme_booking_private;
revoke all on schema careme_booking_private from public, anon;
grant usage on schema careme_booking_private to authenticated;

create or replace function careme_booking_private.can_read_booking_trip(
  p_booking_id uuid
)
returns boolean
language sql
stable
security definer
set search_path to public
as $function$
  select exists (
    select 1
      from public.bookings b
     where b.booking_id = p_booking_id
       and b.booking_status = 'on_the_way'
       and auth.uid() in (b.client_id, b.beautician_id)
  );
$function$;

revoke all on function careme_booking_private.can_read_booking_trip(uuid)
  from public, anon;
grant execute on function careme_booking_private.can_read_booking_trip(uuid)
  to authenticated;

drop policy if exists booking_trip_locations_participants_read
  on public.booking_trip_locations;
create policy booking_trip_locations_participants_read
  on public.booking_trip_locations
  for select to authenticated
  using (careme_booking_private.can_read_booking_trip(booking_id));

revoke all on public.booking_trip_locations from public, anon, authenticated;
grant select on public.booking_trip_locations to authenticated;

do $publication$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'booking_trip_locations'
  ) then
    alter publication supabase_realtime
      add table public.booking_trip_locations;
  end if;
end;
$publication$;

create or replace function public.get_my_bookings()
returns table (
  booking_id uuid,
  other_name text,
  other_phone text,
  other_image text,
  service_title text,
  service_variant_name text,
  service_image text,
  unit_price numeric,
  quantity integer,
  total_price numeric,
  booking_date date,
  start_time time without time zone,
  end_time time without time zone,
  duration_minutes integer,
  final_duration_minutes integer,
  barangay text,
  distance_km numeric,
  status text,
  is_seen boolean,
  address text,
  landmark_note text,
  created_at timestamp with time zone
)
language plpgsql
stable
security definer
set search_path to public
as $function$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select u.role::text into v_role
    from public.users u
   where u.id = v_uid;

  if v_role = 'beautician' then
    return query
    select b.booking_id,
           c.first_name || ' ' || c.last_name,
           c.phone,
           c.profile_image,
           b.service_title,
           b.service_variant_name,
           (select s.service_images[1]
              from public.services s
             where s.service_id = b.service_id),
           b.unit_price,
           b.quantity,
           b.booking_total_price,
           b.booking_date,
           b.booking_start_time,
           b.booking_end_time,
           b.booking_duration_minutes,
           b.booking_final_duration_minutes,
           b.booking_barangay,
           b.booking_distance_km,
           b.booking_status::text,
           (b.beautician_seen_at is not null),
           case when b.booking_status = 'on_the_way'
                then b.booking_address end,
           case when b.booking_status = 'on_the_way'
                then b.booking_landmark_note end,
           b.created_at
      from public.bookings b
      join public.users c on c.id = b.client_id
     where b.beautician_id = v_uid
     order by b.booking_date, b.booking_start_time;
  else
    return query
    select b.booking_id,
           u.first_name || ' ' || u.last_name,
           null::text,
           u.profile_image,
           b.service_title,
           b.service_variant_name,
           (select s.service_images[1]
              from public.services s
             where s.service_id = b.service_id),
           b.unit_price,
           b.quantity,
           b.booking_total_price,
           b.booking_date,
           b.booking_start_time,
           b.booking_end_time,
           b.booking_duration_minutes,
           b.booking_final_duration_minutes,
           b.booking_barangay,
           b.booking_distance_km,
           b.booking_status::text,
           true,
           b.booking_address,
           b.booking_landmark_note,
           b.created_at
      from public.bookings b
      join public.users u on u.id = b.beautician_id
     where b.client_id = v_uid
     order by b.booking_date desc, b.booking_start_time desc;
  end if;
end;
$function$;

create or replace function public.respond_to_booking(
  p_booking_id uuid,
  p_accept boolean,
  p_final_minutes integer default null
)
returns void
language plpgsql
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  b record;
  v_minutes integer;
  v_start_min integer;
  v_end time;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select *
    into b
    from public.bookings
   where booking_id = p_booking_id
     and beautician_id = v_uid
   for update;
  if not found then
    raise exception 'booking_not_found';
  end if;
  if b.booking_status <> 'pending' then
    raise exception 'booking_not_pending';
  end if;

  if p_accept then
    v_minutes := coalesce(p_final_minutes, b.booking_duration_minutes);
    if v_minutes < b.booking_duration_minutes then
      raise exception 'service_duration_cannot_be_reduced';
    end if;
    if v_minutes < 1 or v_minutes > 1440 then
      raise exception 'invalid_duration';
    end if;

    v_start_min := (
      extract(hour from b.booking_start_time) * 60
      + extract(minute from b.booking_start_time)
    )::int;
    if v_start_min + v_minutes >= 1440 then
      raise exception 'booking_crosses_midnight';
    end if;
    v_end := b.booking_start_time + (v_minutes * interval '1 minute');

    if exists (
      select 1
        from public.bookings o
       where o.beautician_id = v_uid
         and o.booking_id <> b.booking_id
         and o.booking_date = b.booking_date
         and o.booking_status in ('accepted', 'on_the_way', 'ongoing')
         and o.booking_start_time < v_end
         and o.booking_end_time > b.booking_start_time
    ) then
      raise exception 'booking_overlap';
    end if;

    update public.bookings
       set booking_status = 'accepted',
           booking_final_duration_minutes = v_minutes,
           booking_end_time = v_end,
           beautician_seen_at = coalesce(beautician_seen_at, now()),
           updated_at = now()
     where booking_id = b.booking_id;

    insert into public.notifications (
      recipient_id, actor_id, notification_type, booking_id, message
    )
    values (
      b.client_id,
      v_uid,
      'booking_accepted',
      b.booking_id,
      'accepted your booking request for ' || b.service_title || '.'
    );
  else
    update public.bookings
       set booking_status = 'declined',
           beautician_seen_at = coalesce(beautician_seen_at, now()),
           updated_at = now()
     where booking_id = b.booking_id;

    insert into public.notifications (
      recipient_id, actor_id, notification_type, booking_id, message
    )
    values (
      b.client_id,
      v_uid,
      'booking_declined',
      b.booking_id,
      'declined your booking request for ' || b.service_title || '.'
    );
  end if;
end;
$function$;

create or replace function public.mark_booking_seen(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path to public
as $function$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  update public.bookings
     set beautician_seen_at = now()
   where booking_id = p_booking_id
     and beautician_id = auth.uid()
     and booking_status = 'pending'
     and beautician_seen_at is null;
end;
$function$;

create or replace function public.mark_notifications_read()
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
   where n.recipient_id = v_uid
     and not n.is_read
     and not (
       n.notification_type = 'booking_ongoing'
       and exists (
         select 1
           from public.bookings b
          where b.booking_id = n.booking_id
            and b.beautician_id = v_uid
            and b.booking_status = 'ongoing'
       )
     );
end;
$function$;

create or replace function public.cancel_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  b record;
  v_target uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select *
    into b
    from public.bookings
   where booking_id = p_booking_id
     and (client_id = v_uid or beautician_id = v_uid)
   for update;

  if not found then
    raise exception 'booking_not_found';
  end if;

  if v_uid = b.client_id then
    if b.booking_status not in ('pending', 'accepted') then
      raise exception 'cannot_cancel';
    end if;
    v_target := b.beautician_id;
  else
    if b.booking_status not in ('accepted', 'ongoing') then
      raise exception 'cannot_cancel';
    end if;
    v_target := b.client_id;
  end if;

  update public.bookings
     set booking_status = 'cancelled',
         beautician_seen_at = coalesce(beautician_seen_at, now()),
         updated_at = now()
   where booking_id = b.booking_id;

  insert into public.notifications (
    recipient_id, actor_id, notification_type, booking_id, message
  )
  values (
    v_target,
    v_uid,
    'booking_cancelled',
    b.booking_id,
    'cancelled the booking for ' || b.service_title || '.'
  );
end;
$function$;

create or replace function public.start_booking_trip(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  b record;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select *
    into b
    from public.bookings
   where booking_id = p_booking_id
     and beautician_id = v_uid
   for update;

  if not found then
    raise exception 'booking_not_found';
  end if;
  if b.booking_status <> 'ongoing' then
    raise exception 'booking_not_ongoing';
  end if;

  update public.bookings
     set booking_status = 'on_the_way',
         beautician_seen_at = now(),
         updated_at = now()
   where booking_id = b.booking_id;

  insert into public.booking_trip_locations (booking_id, beautician_id)
  values (b.booking_id, v_uid)
  on conflict (booking_id) do update
    set beautician_id = excluded.beautician_id,
        latitude = null,
        longitude = null,
        updated_at = now();

  insert into public.notifications (
    recipient_id, actor_id, notification_type, booking_id, message
  )
  values (
    b.client_id,
    v_uid,
    'booking_on_the_way',
    b.booking_id,
    'Your beautician is on the way for ' || b.service_title || '.'
  );

  update public.notifications
     set is_read = true
   where recipient_id = v_uid
     and booking_id = b.booking_id
     and notification_type = 'booking_ongoing'
     and not is_read;
end;
$function$;

create or replace function public.update_booking_trip_location(
  p_booking_id uuid,
  p_lat double precision,
  p_lng double precision
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
  if p_lat is null or p_lng is null
     or p_lat not between -90 and 90
     or p_lng not between -180 and 180 then
    raise exception 'invalid_location';
  end if;

  update public.booking_trip_locations t
     set latitude = p_lat,
         longitude = p_lng,
         updated_at = now()
    from public.bookings b
   where t.booking_id = p_booking_id
     and t.beautician_id = v_uid
     and b.booking_id = t.booking_id
     and b.booking_status = 'on_the_way';

  if not found then
    raise exception 'booking_not_on_the_way';
  end if;
end;
$function$;

create or replace function public.get_booking_trip(p_booking_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  b public.bookings%rowtype;
  v_trip public.booking_trip_locations%rowtype;
  v_client public.users%rowtype;
  v_beautician public.users%rowtype;
  v_is_client boolean;
  v_can_see_address boolean;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select *
    into b
    from public.bookings
   where booking_id = p_booking_id
     and (client_id = v_uid or beautician_id = v_uid);
  if not found then
    raise exception 'booking_not_found';
  end if;
  if b.booking_status not in ('ongoing', 'on_the_way') then
    raise exception 'booking_not_active';
  end if;

  v_is_client := b.client_id = v_uid;
  v_can_see_address := v_is_client or b.booking_status = 'on_the_way';

  select * into v_client from public.users where id = b.client_id;
  select * into v_beautician from public.users where id = b.beautician_id;
  select *
    into v_trip
    from public.booking_trip_locations
   where booking_id = b.booking_id;

  return jsonb_build_object(
    'status', b.booking_status::text,
    'client_name', v_client.first_name || ' ' || v_client.last_name,
    'client_image', v_client.profile_image,
    'beautician_name', v_beautician.first_name || ' ' || v_beautician.last_name,
    'beautician_image', v_beautician.profile_image,
    'destination_latitude',
      case when v_can_see_address then b.booking_latitude end,
    'destination_longitude',
      case when v_can_see_address then b.booking_longitude end,
    'address',
      case when v_can_see_address then b.booking_address end,
    'landmark_note',
      case when v_can_see_address then b.booking_landmark_note end,
    'barangay', b.booking_barangay,
    'distance_km', b.booking_distance_km,
    'beautician_latitude',
      case when b.booking_status = 'on_the_way' then v_trip.latitude end,
    'beautician_longitude',
      case when b.booking_status = 'on_the_way' then v_trip.longitude end,
    'location_updated_at',
      case when b.booking_status = 'on_the_way' then v_trip.updated_at end
  );
end;
$function$;

create or replace function public.process_booking_lifecycle()
returns void
language plpgsql
security definer
set search_path to public
as $function$
declare
  b record;
begin
  for b in
    select *
      from public.bookings
     where booking_status = 'accepted'
       and (booking_date + booking_start_time) at time zone 'Asia/Manila'
             > now()
       and (booking_date + booking_start_time) at time zone 'Asia/Manila'
             <= now() + interval '10 minutes'
  loop
    insert into public.booking_schedule_events (booking_id, event_type)
    values (b.booking_id, 'upcoming_10m')
    on conflict do nothing;

    if found then
      insert into public.notifications (
        recipient_id, actor_id, notification_type, booking_id, message
      )
      values
        (
          b.client_id, b.beautician_id, 'booking_starting_soon',
          b.booking_id, 'Your ' || b.service_title || ' booking starts in 10 minutes.'
        ),
        (
          b.beautician_id, b.client_id, 'booking_starting_soon',
          b.booking_id, 'Your ' || b.service_title || ' booking starts in 10 minutes.'
        );
    end if;
  end loop;

  for b in
    select *
      from public.bookings
     where booking_status = 'accepted'
       and (booking_date + booking_start_time) at time zone 'Asia/Manila'
             <= now()
     for update skip locked
  loop
    update public.bookings
       set booking_status = 'ongoing',
           beautician_seen_at = null,
           updated_at = now()
     where booking_id = b.booking_id
       and booking_status = 'accepted';

    if found then
      insert into public.booking_schedule_events (booking_id, event_type)
      values (b.booking_id, 'ongoing')
      on conflict do nothing;

      if found then
        insert into public.notifications (
          recipient_id, actor_id, notification_type, booking_id, message
        )
        values
          (
            b.beautician_id, b.client_id, 'booking_ongoing',
            b.booking_id, 'Your ' || b.service_title || ' booking is now ongoing.'
          ),
          (
            b.client_id, b.beautician_id, 'booking_ongoing',
            b.booking_id, 'Your ' || b.service_title || ' booking is now ongoing.'
          );
      end if;
    end if;
  end loop;
end;
$function$;

revoke all on function public.get_my_bookings() from public, anon;
grant execute on function public.get_my_bookings() to authenticated;
revoke all on function public.respond_to_booking(uuid, boolean, integer)
  from public, anon;
grant execute on function public.respond_to_booking(uuid, boolean, integer)
  to authenticated;
revoke all on function public.mark_booking_seen(uuid) from public, anon;
grant execute on function public.mark_booking_seen(uuid) to authenticated;
revoke all on function public.mark_notifications_read() from public, anon;
grant execute on function public.mark_notifications_read() to authenticated;
revoke all on function public.cancel_booking(uuid) from public, anon;
grant execute on function public.cancel_booking(uuid) to authenticated;
revoke all on function public.start_booking_trip(uuid) from public, anon;
grant execute on function public.start_booking_trip(uuid) to authenticated;
revoke all on function public.update_booking_trip_location(uuid, double precision, double precision)
  from public, anon;
grant execute on function public.update_booking_trip_location(uuid, double precision, double precision)
  to authenticated;
revoke all on function public.get_booking_trip(uuid) from public, anon;
grant execute on function public.get_booking_trip(uuid) to authenticated;
revoke all on function public.process_booking_lifecycle()
  from public, anon, authenticated;

do $schedule$
declare
  v_job_id bigint;
begin
  for v_job_id in
    select jobid from cron.job where jobname = 'careme_booking_lifecycle'
  loop
    perform cron.unschedule(v_job_id);
  end loop;

  perform cron.schedule(
    'careme_booking_lifecycle',
    '* * * * *',
    'select public.process_booking_lifecycle();'
  );
end;
$schedule$;

notify pgrst, 'reload schema';
