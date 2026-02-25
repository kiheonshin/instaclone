-- User behavior analytics events (heatmap/scroll/rage/dead/session replay)

create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  page_url text not null,
  element_info jsonb,
  x_pos integer,
  y_pos integer,
  scroll_depth integer,
  session_id text not null,
  created_at timestamptz not null default now(),
  user_agent text,
  referrer text
);

create index if not exists idx_analytics_events_created_at
  on public.analytics_events (created_at desc);

create index if not exists idx_analytics_events_page_type_created
  on public.analytics_events (page_url, event_type, created_at desc);

create index if not exists idx_analytics_events_session_created
  on public.analytics_events (session_id, created_at desc);

alter table public.analytics_events enable row level security;

drop policy if exists "Anyone can insert analytics events" on public.analytics_events;
create policy "Anyone can insert analytics events"
  on public.analytics_events for insert
  with check (true);

drop policy if exists "Admins can read analytics events" on public.analytics_events;
create policy "Admins can read analytics events"
  on public.analytics_events for select
  using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and is_admin = true
    )
  );
