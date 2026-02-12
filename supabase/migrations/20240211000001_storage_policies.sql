-- Storage RLS 정책 추가
-- posts, avatars 버킷에 대한 업로드/조회 권한 설정

-- posts 버킷: 모든 사용자 조회 가능
create policy "Post images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'posts');

-- posts 버킷: 인증된 사용자가 본인 폴더에만 업로드 가능
-- 경로 형식: {user_id}/{timestamp}_{filename}
create policy "Authenticated users can upload to own posts folder"
  on storage.objects for insert
  with check (
    bucket_id = 'posts'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- posts 버킷: 본인 파일 삭제/수정 가능
create policy "Users can update own posts"
  on storage.objects for update
  using (
    bucket_id = 'posts'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete own posts"
  on storage.objects for delete
  using (
    bucket_id = 'posts'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- avatars 버킷: 모든 사용자 조회 가능
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- avatars 버킷: 인증된 사용자가 본인 폴더에만 업로드 가능
create policy "Authenticated users can upload own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
