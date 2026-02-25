-- Data quality constraints for analytics events

alter table public.analytics_events
  drop constraint if exists analytics_events_event_type_check;

alter table public.analytics_events
  add constraint analytics_events_event_type_check
  check (
    event_type in (
      'page_view',
      'click',
      'cta_click',
      'scroll_depth',
      'dead_click',
      'rage_click',
      'page_dwell'
    )
  );

alter table public.analytics_events
  drop constraint if exists analytics_events_scroll_depth_check;

alter table public.analytics_events
  add constraint analytics_events_scroll_depth_check
  check (
    scroll_depth is null
    or scroll_depth in (25, 50, 75, 100)
  );

alter table public.analytics_events
  drop constraint if exists analytics_events_xy_non_negative_check;

alter table public.analytics_events
  add constraint analytics_events_xy_non_negative_check
  check (
    (x_pos is null or x_pos >= 0)
    and (y_pos is null or y_pos >= 0)
  );

create index if not exists idx_analytics_events_event_type_created
  on public.analytics_events (event_type, created_at desc);
