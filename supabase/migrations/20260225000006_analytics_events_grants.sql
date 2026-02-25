-- Grant table privileges for API roles; RLS policies still enforce row access.

grant insert on table public.analytics_events to anon;
grant insert on table public.analytics_events to authenticated;
grant select on table public.analytics_events to authenticated;
