-- Insta Clone 초기 스키마
-- Supabase SQL Editor에서 실행하거나: supabase db push

-- profiles (auth.users와 연동)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  full_name text,
  avatar_url text,
  bio text,
  created_at timestamptz default now() not null
);

-- posts
create table if not exists public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  image_url text not null,
  caption text,
  created_at timestamptz default now() not null
);

-- likes
create table if not exists public.likes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  post_id uuid references public.posts on delete cascade not null,
  created_at timestamptz default now() not null,
  unique(user_id, post_id)
);

-- comments
create table if not exists public.comments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  post_id uuid references public.posts on delete cascade not null,
  content text not null,
  created_at timestamptz default now() not null
);

-- follows
create table if not exists public.follows (
  id uuid default gen_random_uuid() primary key,
  follower_id uuid references public.profiles on delete cascade not null,
  following_id uuid references public.profiles on delete cascade not null,
  created_at timestamptz default now() not null,
  unique(follower_id, following_id),
  check (follower_id != following_id)
);

-- RLS 활성화
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;

-- profiles 정책
create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- posts 정책
create policy "Posts are viewable by everyone"
  on public.posts for select
  using (true);

create policy "Users can insert own posts"
  on public.posts for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own posts"
  on public.posts for delete
  using (auth.uid() = user_id);

-- likes 정책
create policy "Likes are viewable by everyone"
  on public.likes for select
  using (true);

create policy "Users can manage own likes"
  on public.likes for all
  using (auth.uid() = user_id);

-- comments 정책
create policy "Comments are viewable by everyone"
  on public.comments for select
  using (true);

create policy "Authenticated users can insert comments"
  on public.comments for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own comments"
  on public.comments for delete
  using (auth.uid() = user_id);

-- follows 정책
create policy "Follows are viewable by everyone"
  on public.follows for select
  using (true);

create policy "Users can manage own follows"
  on public.follows for all
  using (auth.uid() = follower_id);

-- Storage: Supabase Dashboard > Storage에서 버킷 생성
-- 1. avatars (public)
-- 2. posts (public)

-- 새 유저 생성 시 프로필 자동 생성
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text, 1, 8))
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
