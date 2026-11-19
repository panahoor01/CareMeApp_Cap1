-- A.) get_or_create_chat_conversation
--  One conversation per pair of users (user_a is always the smaller uuid)
create table conversations (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.users(id) on delete cascade,
  user_b uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_a < user_b),
  unique (user_a, user_b)
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id),
  receiver_id uuid not null references public.users(id),
  content text not null check (length(trim(content)) > 0),
  created_at timestamptz not null default now()
);
create index on messages (conversation_id, created_at);

-- Security: only participants can see or send messages
alter table conversations enable row level security;
alter table messages enable row level security;

create policy "read own conversations" on conversations
  for select using (auth.uid() in (user_a, user_b));

create policy "read own messages" on messages
  for select using (auth.uid() in (sender_id, receiver_id));

create policy "send as yourself in your conversations" on messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from conversations c
      where c.id = conversation_id
        and auth.uid() in (c.user_a, c.user_b)
        and receiver_id in (c.user_a, c.user_b)
    )
  );

create policy "delete own messages" on messages
  for delete using (sender_id = auth.uid());

-- The function your Dart code calls
create or replace function get_or_create_chat_conversation(p_other_user_id uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  a uuid; b uuid; cid uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if p_other_user_id = me then raise exception 'cannot chat with yourself'; end if;
  a := least(me, p_other_user_id);
  b := greatest(me, p_other_user_id);
  insert into conversations (user_a, user_b) values (a, b)
    on conflict (user_a, user_b) do nothing;
  select id into cid from conversations where user_a = a and user_b = b;
  return cid;
end $$;

-- Needed for .stream() to receive live updates
alter publication supabase_realtime add table messages;

-- B.) get_chat_users
create or replace function get_chat_users()
returns table (id uuid, role user_role, first_name text, last_name text)
language sql
security definer
set search_path = public
as $$
  select u.id, u.role, u.first_name, u.last_name
  from users u
  where u.id <> auth.uid()
  order by u.first_name;
$$;
-- C.) get_chat_inbox
-- when the receiver opened the message (null = unread)
alter table messages add column read_at timestamptz;

-- treat everything sent so far as already read
update messages set read_at = created_at where read_at is null;

create or replace function mark_chat_read(p_other_user_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update messages set read_at = now()
  where receiver_id = auth.uid()
    and sender_id = p_other_user_id
    and read_at is null;
$$;

-- the return type changes, so drop the old version first
drop function if exists get_chat_inbox();

create function get_chat_inbox()
returns table (
  other_user_id uuid,
  first_name text,
  last_name text,
  role user_role,
  last_message text,
  last_sender_id uuid,
  last_message_at timestamptz,
  unread_count int
)
language sql
security definer
set search_path = public
as $$
  select * from (
    select distinct on (m.conversation_id)
      u.id, u.first_name, u.last_name, u.role,
      m.content, m.sender_id, m.created_at,
      (select count(*)::int from messages x
        where x.conversation_id = m.conversation_id
          and x.receiver_id = auth.uid()
          and x.read_at is null) as unread_count
    from messages m
    join conversations c on c.id = m.conversation_id
    join users u on u.id = case when c.user_a = auth.uid()
                                then c.user_b else c.user_a end
    where auth.uid() in (c.user_a, c.user_b)
    order by m.conversation_id, m.created_at desc
  ) t
  order by t.created_at desc;
$$;