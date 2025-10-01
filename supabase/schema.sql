-- Supabase initial schema for WeFixIt
-- Encoding: UTF-8

-- Extensions
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- Auth users are in auth.users
-- Public profile data (non-PII)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  avatar_url text,
  email_obfuscated text,
  is_pro boolean default false,
  available_credits integer not null default 0,
  share_vehicle_with_ai boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Trigger wird nach der Funktionsdefinition erstellt (weiter unten)

-- Helper updated_at function
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end; $$;

-- Trigger jetzt erstellen (nachdem die Funktion existiert)
drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Vehicles (no PII like full VIN in AI)
create table if not exists public.vehicles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  make text,
  model text,
  year integer,
  engine_code text,
  vin text, -- optional, never sent to AI
  created_at timestamptz not null default now()
);
create index if not exists vehicles_user_id_idx on public.vehicles(user_id);

-- Community
create table if not exists public.brands (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique
);

create table if not exists public.models (
  id uuid primary key default uuid_generate_v4(),
  brand_id uuid not null references public.brands(id) on delete cascade,
  name text not null
);
create index if not exists models_brand_idx on public.models(brand_id);

create table if not exists public.threads (
  id uuid primary key default uuid_generate_v4(),
  brand_id uuid references public.brands(id) on delete set null,
  model_id uuid references public.models(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now(),
  pinned boolean default false
);
create index if not exists threads_brand_model_idx on public.threads(brand_id, model_id);

create table if not exists public.posts (
  id uuid primary key default uuid_generate_v4(),
  thread_id uuid not null references public.threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  images text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  hidden boolean default false
);
drop trigger if exists set_posts_updated_at on public.posts;
create trigger set_posts_updated_at
before update on public.posts
for each row execute function public.set_updated_at();
create index if not exists posts_thread_idx on public.posts(thread_id);

create table if not exists public.post_likes (
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(post_id, user_id)
);

create table if not exists public.reports (
  id uuid primary key default uuid_generate_v4(),
  target_type text not null check (target_type in ('post','listing','user')),
  target_id uuid not null,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text,
  created_at timestamptz default now(),
  handled boolean default false
);

-- Private chat
create table if not exists public.private_messages (
  id uuid primary key default uuid_generate_v4(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  content text,
  image_url text,
  audio_url text,
  read_at timestamptz,
  created_at timestamptz default now(),
  deleted_by_sender boolean default false,
  deleted_by_recipient boolean default false
);
create index if not exists pm_participants_idx on public.private_messages(sender_id, recipient_id, created_at);

create table if not exists public.blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(blocker_id, blocked_id)
);

-- Marketplace
create table if not exists public.listings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  brand text,
  model text,
  year integer,
  condition text check (condition in ('new','used','defekt')),
  price numeric(12,2),
  location_city text,
  location_radius_km integer,
  shipping_options text[] check (shipping_options <@ array['pickup','shipping']::text[]),
  images text[],
  description text,
  highlighted boolean default false,
  highlight_expires_at timestamptz,
  created_at timestamptz default now()
);
create index if not exists listings_search_idx on public.listings(brand, model, price, highlighted, created_at);

-- Notifications
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  payload jsonb not null,
  read boolean default false,
  created_at timestamptz default now()
);
create index if not exists notifications_user_idx on public.notifications(user_id, created_at);

-- Credits & quotas
create table if not exists public.credit_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  delta integer not null, -- +purchase, -consume
  reason text,
  created_at timestamptz default now()
);
create index if not exists credit_events_user_idx on public.credit_events(user_id, created_at);

create table if not exists public.weekly_free_quota (
  user_id uuid primary key references auth.users(id) on delete cascade,
  week_start_date date not null, -- ISO week start (e.g., Monday)
  consumed integer not null default 0
);

-- OBD clear audit (no PII)
create table if not exists public.obd_clear_audit (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  action text not null check (action in ('clear_dtc')),
  created_at timestamptz default now()
);

-- RevenueCat webhook log (minimal)
create table if not exists public.revenuecat_webhooks (
  id uuid primary key default uuid_generate_v4(),
  event_type text,
  payload jsonb,
  received_at timestamptz default now()
);

-- RLS enable
alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.threads enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.reports enable row level security;
alter table public.private_messages enable row level security;
alter table public.blocks enable row level security;
alter table public.listings enable row level security;
alter table public.notifications enable row level security;
alter table public.credit_events enable row level security;
alter table public.weekly_free_quota enable row level security;
alter table public.obd_clear_audit enable row level security;

-- Policies
drop policy if exists "profiles_self_select" on public.profiles;
drop policy if exists "profiles_self_update" on public.profiles;
drop policy if exists "profiles_self_insert" on public.profiles;
create policy "profiles_self_select" on public.profiles for select using (auth.uid() = id);
create policy "profiles_self_update" on public.profiles for update using (auth.uid() = id);
create policy "profiles_self_insert" on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "vehicles_owner_all" on public.vehicles;
create policy "vehicles_owner_all" on public.vehicles for all using (auth.uid() = user_id);

drop policy if exists "threads_read_all" on public.threads;
create policy "threads_read_all" on public.threads for select using (true);
drop policy if exists "threads_write_owner" on public.threads;
create policy "threads_write_owner" on public.threads for insert with check (auth.uid() = user_id);
drop policy if exists "threads_update_owner" on public.threads;
create policy "threads_update_owner" on public.threads for update using (auth.uid() = user_id);

drop policy if exists "posts_read_all" on public.posts;
create policy "posts_read_all" on public.posts for select using (true);
drop policy if exists "posts_write_owner" on public.posts;
create policy "posts_write_owner" on public.posts for insert with check (auth.uid() = user_id);
drop policy if exists "posts_update_owner" on public.posts;
create policy "posts_update_owner" on public.posts for update using (auth.uid() = user_id);

drop policy if exists "post_likes_read" on public.post_likes;
create policy "post_likes_read" on public.post_likes for select using (true);
drop policy if exists "post_likes_write_self" on public.post_likes;
create policy "post_likes_write_self" on public.post_likes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "reports_read_self" on public.reports;
create policy "reports_read_self" on public.reports for select using (auth.uid() = reporter_id);
drop policy if exists "reports_insert_self" on public.reports;
create policy "reports_insert_self" on public.reports for insert with check (auth.uid() = reporter_id);

drop policy if exists "pm_participants_read" on public.private_messages;
create policy "pm_participants_read" on public.private_messages for select using (auth.uid() in (sender_id, recipient_id));
drop policy if exists "pm_participants_write" on public.private_messages;
create policy "pm_participants_write" on public.private_messages for insert with check (auth.uid() = sender_id);

drop policy if exists "blocks_owner_all" on public.blocks;
create policy "blocks_owner_all" on public.blocks for all using (auth.uid() = blocker_id);

drop policy if exists "listings_read_all" on public.listings;
create policy "listings_read_all" on public.listings for select using (true);
drop policy if exists "listings_owner_all" on public.listings;
create policy "listings_owner_all" on public.listings for all using (auth.uid() = user_id);

drop policy if exists "notifications_owner_all" on public.notifications;
create policy "notifications_owner_all" on public.notifications for all using (auth.uid() = user_id);

drop policy if exists "credit_events_owner_read" on public.credit_events;
create policy "credit_events_owner_read" on public.credit_events for select using (auth.uid() = user_id);
drop policy if exists "credit_events_owner_insert" on public.credit_events;
create policy "credit_events_owner_insert" on public.credit_events for insert with check (auth.uid() = user_id);

drop policy if exists "weekly_quota_owner_all" on public.weekly_free_quota;
create policy "weekly_quota_owner_all" on public.weekly_free_quota for all using (auth.uid() = user_id);

drop policy if exists "obd_clear_audit_owner_read" on public.obd_clear_audit;
create policy "obd_clear_audit_owner_read" on public.obd_clear_audit for select using (auth.uid() = user_id);

-- Minimal functions for credit consume/check can be added as Edge Functions; DB holds state.

-- === WeFixIt MVP Profile Enhancements ===
-- Add new profile fields if they don't exist yet
do $$ begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='display_name'
  ) then
    alter table public.profiles add column display_name text;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='first_name'
  ) then
    alter table public.profiles add column first_name text;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='last_name'
  ) then
    alter table public.profiles add column last_name text;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='nickname'
  ) then
    alter table public.profiles add column nickname text;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='vehicle_photo_url'
  ) then
    alter table public.profiles add column vehicle_photo_url text;
  end if;
end $$;

-- Create helper function to obfuscate email
create or replace function public.obfuscate_email(email text)
returns text language plpgsql as $$
declare
  name_part text;
  domain_part text;
begin
  if email is null then return null; end if;
  name_part := split_part(email, '@', 1);
  domain_part := split_part(email, '@', 2);
  if length(name_part) > 2 then
    name_part := left(name_part, 1) || repeat('*', greatest(length(name_part)-2,1)) || right(name_part, 1);
  else
    name_part := name_part || '*';
  end if;
  return name_part || '@' || domain_part;
end $$;

-- Insert trigger to create profile row on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, email_obfuscated, created_at, updated_at)
  values (new.id, split_part(new.email, '@', 1), public.obfuscate_email(new.email), now(), now())
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
