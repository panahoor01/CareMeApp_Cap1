alter table public.booking_trip_locations
  add column if not exists client_latitude double precision,
  add column if not exists client_longitude double precision,
  add column if not exists client_location_updated_at timestamptz;

do $constraint$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.booking_trip_locations'::regclass
       and conname = 'booking_trip_client_location_pair_chk'
  ) then
    alter table public.booking_trip_locations
      add constraint booking_trip_client_location_pair_chk check (
        (client_latitude is null and client_longitude is null)
        or (
          client_latitude is not null
          and client_longitude is not null
          and client_latitude between -90 and 90
          and client_longitude between -180 and 180
        )
      );
  end if;
end;
$constraint$;

create or replace function public.update_booking_client_location(
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
  if (p_lat is null) <> (p_lng is null)
     or (p_lat is not null and (
       p_lat not between -90 and 90
       or p_lng not between -180 and 180
     )) then
    raise exception 'invalid_location';
  end if;

  update public.booking_trip_locations t
     set client_latitude = p_lat,
         client_longitude = p_lng,
         client_location_updated_at = case
           when p_lat is null then null
           else now()
         end
    from public.bookings b
   where t.booking_id = p_booking_id
     and b.booking_id = t.booking_id
     and b.client_id = v_uid
     and b.booking_status = 'on_the_way';

  if not found then
    raise exception 'booking_not_on_the_way';
  end if;
end;
$function$;

revoke all on function public.update_booking_client_location(
  uuid, double precision, double precision
) from public, anon;
grant execute on function public.update_booking_client_location(
  uuid, double precision, double precision
) to authenticated;

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
      case when b.booking_status = 'on_the_way' then v_trip.updated_at end,
    'client_latitude',
      case
        when b.booking_status = 'on_the_way'
         and v_trip.client_location_updated_at > now() - interval '5 minutes'
        then v_trip.client_latitude
      end,
    'client_longitude',
      case
        when b.booking_status = 'on_the_way'
         and v_trip.client_location_updated_at > now() - interval '5 minutes'
        then v_trip.client_longitude
      end
  );
end;
$function$;