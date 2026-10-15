alter table public.bookings
  add column if not exists booking_arrived_at timestamptz,
  add column if not exists booking_completed_at timestamptz;

create table if not exists public.service_reviews (
  service_review_id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique
    references public.bookings(booking_id) on delete cascade,
  service_id uuid not null
    references public.services(service_id) on delete cascade,
  beautician_id uuid not null references public.users(id) on delete cascade,
  client_id uuid not null references public.users(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  review_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists service_reviews_service_idx
  on public.service_reviews(service_id);
create index if not exists service_reviews_beautician_idx
  on public.service_reviews(beautician_id);

alter table public.service_reviews enable row level security;
revoke all on public.service_reviews from public, anon, authenticated;

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
     and b.booking_status = 'on_the_way'
     and b.booking_arrived_at is null;

  if not found then
    raise exception 'booking_not_on_the_way';
  end if;
end;
$function$;

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
     and b.booking_status = 'on_the_way'
     and b.booking_arrived_at is null;

  if not found then
    raise exception 'booking_not_on_the_way';
  end if;
end;
$function$;

create or replace function public.mark_booking_arrived(p_booking_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  v_arrived_at timestamptz;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  update public.bookings
     set booking_arrived_at = coalesce(booking_arrived_at, now()),
         updated_at = now()
   where booking_id = p_booking_id
     and beautician_id = v_uid
     and booking_status = 'on_the_way'
  returning booking_arrived_at into v_arrived_at;

  if not found then
    raise exception 'booking_not_on_the_way';
  end if;

  update public.booking_trip_locations
     set latitude = null,
         longitude = null,
         client_latitude = null,
         client_longitude = null,
         client_location_updated_at = null,
         updated_at = now()
   where booking_id = p_booking_id;

  return v_arrived_at;
end;
$function$;

create or replace function public.complete_booking_service(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  b public.bookings%rowtype;
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
  if b.booking_status <> 'on_the_way' or b.booking_arrived_at is null then
    raise exception 'booking_not_arrived';
  end if;

  update public.bookings
     set booking_status = 'completed',
         booking_completed_at = coalesce(booking_completed_at, now()),
         updated_at = now()
   where booking_id = b.booking_id;

  update public.booking_trip_locations
     set latitude = null,
         longitude = null,
         client_latitude = null,
         client_longitude = null,
         client_location_updated_at = null,
         updated_at = now()
   where booking_id = b.booking_id;

  return jsonb_build_object(
    'status', 'completed',
    'completed_at', (select booking_completed_at
                       from public.bookings
                      where booking_id = b.booking_id)
  );
end;
$function$;

create or replace function public.get_booking_phase(p_booking_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  b public.bookings%rowtype;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select *
    into b
    from public.bookings
   where booking_id = p_booking_id
     and auth.uid() in (client_id, beautician_id);
  if not found then
    raise exception 'booking_not_found';
  end if;

  return jsonb_build_object(
    'status', b.booking_status::text,
    'arrived_at', b.booking_arrived_at,
    'completed_at', b.booking_completed_at
  );
end;
$function$;

create or replace function public.get_booking_service_details(p_booking_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  v_details jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select jsonb_build_object(
    'service_id', b.service_id,
    'beautician_id', b.beautician_id,
    'client_id', b.client_id,
    'client_name', c.first_name || ' ' || c.last_name,
    'client_image', c.profile_image,
    'client_phone', c.phone,
    'beautician_name', p.first_name || ' ' || p.last_name,
    'beautician_image', p.profile_image,
    'service_title', b.service_title,
    'service_image', s.service_images[1],
    'variant_name', b.service_variant_name,
    'service_price', coalesce(s.service_price, b.unit_price),
    'variant_price', case
      when b.service_variant_name is null then 0
      else coalesce(
        v.add_price,
        greatest(b.unit_price - coalesce(s.service_price, b.unit_price), 0)
      )
    end,
    'unit_price', b.unit_price,
    'total_price', b.booking_total_price,
    'quantity', b.quantity,
    'base_service_minutes', coalesce(
      s.service_duration_minutes,
      greatest(b.booking_duration_minutes - coalesce(v.extra_minutes, 0), 0)
    ),
    'variant_extra_minutes', coalesce(v.extra_minutes, 0),
    'service_minutes', b.booking_duration_minutes,
    'additional_minutes', greatest(
      coalesce(b.booking_final_duration_minutes, b.booking_duration_minutes)
        - b.booking_duration_minutes,
      0
    ),
    'reserved_minutes', coalesce(
      b.booking_final_duration_minutes,
      b.booking_duration_minutes
    ),
    'address', case
      when b.client_id = v_uid
        or b.booking_status in ('on_the_way', 'completed')
      then b.booking_address
    end,
    'landmark_note', case
      when b.client_id = v_uid
        or b.booking_status in ('on_the_way', 'completed')
      then b.booking_landmark_note
    end,
    'booking_date', b.booking_date,
    'start_time', b.booking_start_time,
    'end_time', b.booking_end_time,
    'arrived_at', b.booking_arrived_at
  )
    into v_details
    from public.bookings b
    left join public.users c on c.id = b.client_id
    left join public.users p on p.id = b.beautician_id
    left join public.services s on s.service_id = b.service_id
    left join lateral (
            select sv.service_variant_add_price as add_price,
              sv.service_variant_extra_minute as extra_minutes
        from public.service_variants sv
       where sv.service_id = b.service_id
         and sv.service_variant_name = b.service_variant_name
       order by sv.service_variant_id
       limit 1
    ) v on true
   where b.booking_id = p_booking_id
     and auth.uid() in (b.client_id, b.beautician_id);

  if v_details is null then
    raise exception 'booking_not_found';
  end if;
  return v_details;
end;
$function$;

create or replace function public.submit_service_review(
  p_booking_id uuid,
  p_rating integer,
  p_review text default null
)
returns void
language plpgsql
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
  b public.bookings%rowtype;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;
  if p_rating is null or p_rating not between 1 and 5 then
    raise exception 'invalid_rating';
  end if;

  select *
    into b
    from public.bookings
   where booking_id = p_booking_id
     and client_id = v_uid
     and booking_status = 'completed'
     and booking_completed_at is not null;
  if not found then
    raise exception 'booking_not_completed';
  end if;

  insert into public.service_reviews (
    booking_id, service_id, beautician_id, client_id, rating, review_text
  )
  values (
    b.booking_id,
    b.service_id,
    b.beautician_id,
    b.client_id,
    p_rating,
    nullif(trim(p_review), '')
  )
  on conflict (booking_id) do update
    set rating = excluded.rating,
        review_text = excluded.review_text,
        updated_at = now()
   where service_reviews.client_id = v_uid;
end;
$function$;

create or replace function public.get_service_rating_summaries(
  p_service_ids text[]
)
returns table (
  service_id text,
  average_rating numeric,
  rating_count bigint
)
language plpgsql
stable
security definer
set search_path to public
as $function$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  return query
  select r.service_id::text,
         round(avg(r.rating)::numeric, 1),
         count(*)
    from public.service_reviews r
   where r.service_id::text = any(coalesce(p_service_ids, array[]::text[]))
   group by r.service_id;
end;
$function$;

create or replace function public.get_beautician_rating_summary(
  p_beautician_id text
)
returns jsonb
language plpgsql
stable
security definer
set search_path to public
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  return (
    select jsonb_build_object(
      'average_rating', round(avg(r.rating)::numeric, 1),
      'rating_count', count(r.service_review_id)
    )
      from public.service_reviews r
     where r.beautician_id::text = p_beautician_id
  );
end;
$function$;

create or replace function public.get_service_reviews(p_service_id text)
returns table (
  review_id uuid,
  rating smallint,
  review_text text,
  reviewer_name text,
  reviewer_image text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path to public
as $function$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  return query
  select r.service_review_id,
         r.rating,
         r.review_text,
         u.first_name || ' ' || u.last_name,
         u.profile_image,
         r.created_at
    from public.service_reviews r
    join public.users u on u.id = r.client_id
   where r.service_id::text = p_service_id
   order by r.created_at desc;
end;
$function$;

revoke all on function public.mark_booking_arrived(uuid) from public, anon;
grant execute on function public.mark_booking_arrived(uuid) to authenticated;
revoke all on function public.complete_booking_service(uuid) from public, anon;
grant execute on function public.complete_booking_service(uuid) to authenticated;
revoke all on function public.get_booking_phase(uuid) from public, anon;
grant execute on function public.get_booking_phase(uuid) to authenticated;
revoke all on function public.get_booking_service_details(uuid) from public, anon;
grant execute on function public.get_booking_service_details(uuid) to authenticated;
revoke all on function public.submit_service_review(uuid, integer, text)
  from public, anon;
grant execute on function public.submit_service_review(uuid, integer, text)
  to authenticated;
revoke all on function public.get_service_rating_summaries(text[])
  from public, anon;
grant execute on function public.get_service_rating_summaries(text[])
  to authenticated;
revoke all on function public.get_beautician_rating_summary(text)
  from public, anon;
grant execute on function public.get_beautician_rating_summary(text)
  to authenticated;
revoke all on function public.get_service_reviews(text) from public, anon;
grant execute on function public.get_service_reviews(text) to authenticated;

notify pgrst, 'reload schema';