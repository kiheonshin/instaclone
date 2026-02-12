-- 관리자 RLS 정책: is_admin=true 사용자는 전체 조회/삭제 가능

-- 게시물: 관리자는 모든 게시물 삭제 가능
drop policy if exists "Users can delete own posts" on public.posts;
create policy "Users can delete own posts"
  on public.posts for delete
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and is_admin = true
    )
  );
