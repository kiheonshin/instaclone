-- Visitor analytics: structured page view records
-- Separate from analytics_events for clean aggregation queries

create table if not exists public.page_views (
  id               uuid primary key default gen_random_uuid(),
  session_id       text not null,
  page_url         text not null,
  referrer         text,
  utm_source       text,
  utm_medium       text,
  utm_campaign     text,
  device_type      text,            -- 'mobile' | 'tablet' | 'desktop'
  browser          text,            -- 'Chrome' | 'Safari' | 'Firefox' | 'Edge' | 'Other'
  screen_width     integer,
  duration_seconds numeric,         -- decimal for precision (e.g. 123.45)
  created_at       timestamptz not null default now()
);

-- Performance indexes for dashboard queries
create index if not exists idx_page_views_created_at
  on public.page_views (created_at desc);

create index if not exists idx_page_views_session_created
  on public.page_views (session_id, created_at desc);

create index if not exists idx_page_views_page_url_created
  on public.page_views (page_url, created_at desc);

create index if not exists idx_page_views_device_created
  on public.page_views (device_type, created_at desc);

-- created_at DESC index already covers hourly distribution queries

-- RLS
alter table public.page_views enable row level security;

-- Anyone can insert (JS tracker uses anon key)
drop policy if exists "Anyone can insert page views" on public.page_views;
create policy "Anyone can insert page views"
  on public.page_views for insert
  with check (true);

-- Only admins can read
drop policy if exists "Admins can read page views" on public.page_views;
create policy "Admins can read page views"
  on public.page_views for select
  using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and is_admin = true
    )
  );

-- Grant access to authenticated and anon roles
grant insert on public.page_views to anon, authenticated;
grant select on public.page_views to authenticated;
