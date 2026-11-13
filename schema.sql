-- ============================================================
-- Run this once in Supabase: Dashboard -> SQL Editor -> New query
-- Paste everything, click Run.
-- ============================================================

-- PROFILES: everyone's personal page
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null check (char_length(display_name) between 1 and 50),
  bio text default '' check (char_length(bio) <= 500),
  skills text[] default '{}',
  bg_video text default '' check (char_length(bg_video) <= 200),
  bg_zoom numeric default 1.15 check (bg_zoom between 1 and 2),
  accent text default '#ffffff' check (accent ~ '^#[0-9a-fA-F]{6}$'),
  socials jsonb default '{}'::jsonb,
  projects jsonb default '[]'::jsonb,
  music jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

-- POSTS: "building X, need Y" / "want to join something"
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('building','joining')),
  title text not null check (char_length(title) between 1 and 120),
  body text default '' check (char_length(body) <= 2000),
  roles text[] default '{}',
  created_at timestamptz default now()
);

-- INTERESTS: "I'm interested" on a post
create table if not exists public.interests (
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (post_id, user_id)
);

-- MESSAGES: direct messages
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz default now()
);
create index if not exists messages_pair_idx on public.messages (sender_id, recipient_id, created_at);
create index if not exists messages_recipient_idx on public.messages (recipient_id, created_at);

-- BLOCKS and REPORTS
create table if not exists public.blocks (
  blocker_id uuid references public.profiles(id) on delete cascade,
  blocked_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (blocker_id, blocked_id)
);
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('profile','post','message')),
  target_id text not null,
  reason text not null check (char_length(reason) <= 300),
  created_at timestamptz default now()
);

-- ============ Row Level Security (who can read/write what) ============
alter table public.profiles  enable row level security;
alter table public.posts     enable row level security;
alter table public.interests enable row level security;
alter table public.messages  enable row level security;
alter table public.blocks    enable row level security;
alter table public.reports   enable row level security;

-- profiles: anyone can read; you can only create/edit your own
drop policy if exists "profiles read" on public.profiles;
create policy "profiles read" on public.profiles for select using (true);
drop policy if exists "profiles insert own" on public.profiles;
create policy "profiles insert own" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles for update using (auth.uid() = id);

-- posts: anyone can read; you can only create/delete your own
drop policy if exists "posts read" on public.posts;
create policy "posts read" on public.posts for select using (true);
drop policy if exists "posts insert own" on public.posts;
create policy "posts insert own" on public.posts for insert with check (auth.uid() = author_id);
drop policy if exists "posts delete own" on public.posts;
create policy "posts delete own" on public.posts for delete using (auth.uid() = author_id);

-- interests
drop policy if exists "interests read" on public.interests;
create policy "interests read" on public.interests for select using (true);
drop policy if exists "interests insert own" on public.interests;
create policy "interests insert own" on public.interests for insert with check (auth.uid() = user_id);
drop policy if exists "interests delete own" on public.interests;
create policy "interests delete own" on public.interests for delete using (auth.uid() = user_id);

-- messages: only the two people in a conversation can read it;
-- you can't message someone who blocked you
drop policy if exists "messages read own" on public.messages;
create policy "messages read own" on public.messages for select
  using (auth.uid() = sender_id or auth.uid() = recipient_id);
drop policy if exists "messages send" on public.messages;
create policy "messages send" on public.messages for insert
  with check (
    auth.uid() = sender_id
    and sender_id <> recipient_id
    and not exists (select 1 from public.blocks b
                    where b.blocker_id = recipient_id and b.blocked_id = auth.uid())
  );

-- blocks: you see and manage only your own
drop policy if exists "blocks own" on public.blocks;
create policy "blocks own" on public.blocks for all
  using (auth.uid() = blocker_id) with check (auth.uid() = blocker_id);

-- reports: you can file them; only you (and you as admin in the dashboard) can see them
drop policy if exists "reports insert" on public.reports;
create policy "reports insert" on public.reports for insert with check (auth.uid() = reporter_id);
