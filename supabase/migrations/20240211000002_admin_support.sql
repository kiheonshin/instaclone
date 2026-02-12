-- 관리자 기능 지원: profiles에 is_admin 컬럼 추가

alter table public.profiles
add column if not exists is_admin boolean default false;

-- 기존 관리자 지정 (SQL로 직접 설정 필요)
-- update public.profiles set is_admin = true where username = 'admin';

comment on column public.profiles.is_admin is '관리자 여부. true인 사용자만 admin 서브도메인 접근 가능';
