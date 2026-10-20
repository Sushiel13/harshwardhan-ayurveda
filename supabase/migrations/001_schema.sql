-- =====================================================================
-- Harshwardhan Institute of Ayurveda — database schema
-- Run in Supabase: SQL Editor → paste → Run (or `supabase db push`)
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------- Profiles & roles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  email text,
  role text not null default 'student' check (role in ('student','admin')),
  is_blocked boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, phone, email)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name', ''),
          coalesce(new.raw_user_meta_data->>'phone', new.phone),
          new.email)
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- Users may not promote themselves to admin
create or replace function public.protect_role()
returns trigger language plpgsql as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only admins can change roles';
  end if;
  if new.is_blocked is distinct from old.is_blocked and not public.is_admin() then
    raise exception 'Only admins can block users';
  end if;
  return new;
end $$;
drop trigger if exists protect_role on public.profiles;
create trigger protect_role before update on public.profiles
for each row execute function public.protect_role();

-- ---------- Catalogue ----------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  position int not null default 0
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  subtitle text,
  description text,
  thumbnail_url text,
  category_id uuid references public.categories(id) on delete set null,
  instructor text default 'Harshwardhan Institute Faculty',
  language text default 'Hindi + English',
  price numeric(10,2) not null default 0,
  mrp numeric(10,2),
  is_free boolean not null default false,
  is_published boolean not null default false,
  is_featured boolean not null default false,
  validity_days int,               -- null = lifetime access
  created_at timestamptz not null default now()
);

create table if not exists public.course_sections (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  position int not null default 0
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  section_id uuid references public.course_sections(id) on delete set null,
  title text not null,
  description text,
  kind text not null default 'video' check (kind in ('video','pdf')),
  video_path text,      -- object path in the private "content" bucket
  video_url text,       -- OR an external URL (YouTube unlisted / Vimeo / Bunny)
  pdf_path text,        -- optional attached notes (private bucket)
  duration_minutes int,
  is_preview boolean not null default false,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subject text,
  description text,
  file_path text not null,      -- object path in the public "media" bucket
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.ebooks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text,
  description text,
  cover_url text,
  file_path text,               -- private "content" bucket: ebooks/<id>/file.pdf
  price numeric(10,2) not null default 0,
  mrp numeric(10,2),
  is_free boolean not null default false,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.test_series (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  thumbnail_url text,
  price numeric(10,2) not null default 0,
  mrp numeric(10,2),
  is_free boolean not null default false,
  is_published boolean not null default false,
  validity_days int,
  created_at timestamptz not null default now()
);

create table if not exists public.tests (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null references public.test_series(id) on delete cascade,
  title text not null,
  instructions text,
  duration_minutes int not null default 30,
  marks_per_question numeric(5,2) not null default 1,
  negative_marks numeric(5,2) not null default 0,
  position int not null default 0,
  is_published boolean not null default true
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  test_id uuid not null references public.tests(id) on delete cascade,
  question text not null,
  options jsonb not null,           -- ["A","B","C","D"]
  correct_index int not null,
  explanation text,
  position int not null default 0
);

create table if not exists public.test_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  test_id uuid not null references public.tests(id) on delete cascade,
  answers jsonb not null,
  correct int not null,
  wrong int not null,
  score numeric(8,2) not null,
  total numeric(8,2) not null,
  created_at timestamptz not null default now()
);

create table if not exists public.live_classes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references public.courses(id) on delete set null, -- null = open to all logged-in users
  title text not null,
  description text,
  starts_at timestamptz not null,
  duration_minutes int default 60,
  meeting_url text,
  is_free boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  link text,
  created_at timestamptz not null default now()
);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  discount_percent int not null check (discount_percent between 1 and 100),
  max_uses int,
  used_count int not null default 0,
  expires_at timestamptz,
  is_active boolean not null default true
);

create table if not exists public.testimonials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  detail text,
  quote text not null,
  position int not null default 0
);

create table if not exists public.inquiries (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text,
  phone text,
  message text not null,
  created_at timestamptz not null default now()
);

-- ---------- Commerce ----------
create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_type text not null check (item_type in ('course','ebook','test_series')),
  item_id uuid not null,
  amount numeric(10,2) not null default 0,
  source text not null default 'razorpay' check (source in ('razorpay','free','admin')),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, item_type, item_id)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_type text not null,
  item_id uuid not null,
  amount numeric(10,2) not null,
  coupon_code text,
  razorpay_order_id text unique,
  razorpay_payment_id text,
  status text not null default 'created' check (status in ('created','paid','failed')),
  created_at timestamptz not null default now()
);

create table if not exists public.lesson_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  completed_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

create table if not exists public.settings (
  key text primary key,
  value jsonb not null
);

-- ---------- Access helper ----------
create or replace function public.has_access(p_type text, p_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin()
      or exists (select 1 from public.purchases p
                 where p.user_id = auth.uid() and p.item_type = p_type and p.item_id = p_id
                   and (p.expires_at is null or p.expires_at > now()))
      or (p_type = 'course'      and exists (select 1 from public.courses     where id = p_id and is_free and auth.uid() is not null))
      or (p_type = 'ebook'       and exists (select 1 from public.ebooks      where id = p_id and is_free and auth.uid() is not null))
      or (p_type = 'test_series' and exists (select 1 from public.test_series where id = p_id and is_free and auth.uid() is not null));
$$;

-- ---------- Row Level Security ----------
alter table public.profiles        enable row level security;
alter table public.categories      enable row level security;
alter table public.courses         enable row level security;
alter table public.course_sections enable row level security;
alter table public.lessons         enable row level security;
alter table public.notes           enable row level security;
alter table public.ebooks          enable row level security;
alter table public.test_series     enable row level security;
alter table public.tests           enable row level security;
alter table public.questions       enable row level security;
alter table public.test_attempts   enable row level security;
alter table public.live_classes    enable row level security;
alter table public.notifications   enable row level security;
alter table public.coupons         enable row level security;
alter table public.testimonials    enable row level security;
alter table public.inquiries       enable row level security;
alter table public.purchases       enable row level security;
alter table public.payments        enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.settings        enable row level security;

-- profiles
create policy "own profile read"   on public.profiles for select using (id = auth.uid() or public.is_admin());
create policy "own profile update" on public.profiles for update using (id = auth.uid() or public.is_admin());

-- public catalogue (published items readable by everyone, admins manage all)
create policy "categories read"  on public.categories for select using (true);
create policy "categories admin" on public.categories for all using (public.is_admin()) with check (public.is_admin());

create policy "courses read"  on public.courses for select using (is_published or public.is_admin());
create policy "courses admin" on public.courses for all using (public.is_admin()) with check (public.is_admin());

create policy "sections read"  on public.course_sections for select using (true);
create policy "sections admin" on public.course_sections for all using (public.is_admin()) with check (public.is_admin());

-- Lesson rows (titles, durations) are visible so the curriculum can be shown.
-- The actual video/PDF files are protected by storage policies + signed URLs,
-- and external video_url is only returned via get_lesson_media().
create policy "lessons read"  on public.lessons for select using (true);
create policy "lessons admin" on public.lessons for all using (public.is_admin()) with check (public.is_admin());

create policy "notes read"  on public.notes for select using (is_published or public.is_admin());
create policy "notes admin" on public.notes for all using (public.is_admin()) with check (public.is_admin());

create policy "ebooks read"  on public.ebooks for select using (is_published or public.is_admin());
create policy "ebooks admin" on public.ebooks for all using (public.is_admin()) with check (public.is_admin());

create policy "series read"  on public.test_series for select using (is_published or public.is_admin());
create policy "series admin" on public.test_series for all using (public.is_admin()) with check (public.is_admin());

create policy "tests read"  on public.tests for select using (is_published or public.is_admin());
create policy "tests admin" on public.tests for all using (public.is_admin()) with check (public.is_admin());

-- questions: admin only (students get them via RPC without answers)
create policy "questions admin" on public.questions for all using (public.is_admin()) with check (public.is_admin());

create policy "attempts own" on public.test_attempts for select using (user_id = auth.uid() or public.is_admin());

create policy "live read"  on public.live_classes for select using (true);
create policy "live admin" on public.live_classes for all using (public.is_admin()) with check (public.is_admin());

create policy "notif read"  on public.notifications for select using (true);
create policy "notif admin" on public.notifications for all using (public.is_admin()) with check (public.is_admin());

create policy "coupons admin" on public.coupons for all using (public.is_admin()) with check (public.is_admin());

create policy "testimonials read"  on public.testimonials for select using (true);
create policy "testimonials admin" on public.testimonials for all using (public.is_admin()) with check (public.is_admin());

create policy "inquiries insert" on public.inquiries for insert with check (true);
create policy "inquiries admin"  on public.inquiries for select using (public.is_admin());
create policy "inquiries delete" on public.inquiries for delete using (public.is_admin());

create policy "purchases own"   on public.purchases for select using (user_id = auth.uid() or public.is_admin());
create policy "purchases admin" on public.purchases for all using (public.is_admin()) with check (public.is_admin());

create policy "payments own" on public.payments for select using (user_id = auth.uid() or public.is_admin());

create policy "progress own" on public.lesson_progress for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "settings read"  on public.settings for select using (true);
create policy "settings admin" on public.settings for all using (public.is_admin()) with check (public.is_admin());

-- ---------- RPCs ----------

-- Enrol in a free item
create or replace function public.enroll_free(p_type text, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_free boolean;
begin
  if auth.uid() is null then raise exception 'Login required'; end if;
  if p_type = 'course' then select is_free into v_free from courses where id = p_id and is_published;
  elsif p_type = 'ebook' then select is_free into v_free from ebooks where id = p_id and is_published;
  elsif p_type = 'test_series' then select is_free into v_free from test_series where id = p_id and is_published;
  end if;
  if coalesce(v_free,false) = false then raise exception 'Item is not free'; end if;
  insert into purchases(user_id, item_type, item_id, amount, source)
  values (auth.uid(), p_type, p_id, 0, 'free') on conflict do nothing;
end $$;

-- Return playable media for a lesson (only if user has access or it's a preview)
create or replace function public.get_lesson_media(p_lesson uuid)
returns table (video_path text, video_url text, pdf_path text)
language plpgsql stable security definer set search_path = public as $$
declare l lessons;
begin
  select * into l from lessons where id = p_lesson;
  if not found then return; end if;
  if l.is_preview or public.has_access('course', l.course_id) then
    return query select l.video_path, l.video_url, l.pdf_path;
  end if;
end $$;

-- Questions for a test, without answers
create or replace function public.get_test_questions(p_test uuid)
returns table (id uuid, question text, options jsonb, q_position int)
language plpgsql stable security definer set search_path = public as $$
declare v_series uuid;
begin
  select series_id into v_series from tests where tests.id = p_test;
  if not public.has_access('test_series', v_series) then raise exception 'Purchase required'; end if;
  return query select q.id, q.question, q.options, q.position from questions q
               where q.test_id = p_test order by q.position, q.id;
end $$;

-- Grade a submission. p_answers = {"<question_id>": <selected_index>, ...}
create or replace function public.submit_test(p_test uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  t tests; v_correct int := 0; v_wrong int := 0; v_total int := 0;
  q record; v_sel int; v_score numeric; v_review jsonb := '[]'::jsonb;
begin
  select * into t from tests where id = p_test;
  if not public.has_access('test_series', t.series_id) then raise exception 'Purchase required'; end if;
  for q in select * from questions where test_id = p_test order by position, id loop
    v_total := v_total + 1;
    v_sel := (p_answers->>q.id::text)::int;
    if v_sel is null then null;
    elsif v_sel = q.correct_index then v_correct := v_correct + 1;
    else v_wrong := v_wrong + 1; end if;
    v_review := v_review || jsonb_build_object('id', q.id, 'question', q.question, 'options', q.options,
                 'selected', v_sel, 'correct', q.correct_index, 'explanation', q.explanation);
  end loop;
  v_score := v_correct * t.marks_per_question - v_wrong * t.negative_marks;
  insert into test_attempts(user_id, test_id, answers, correct, wrong, score, total)
  values (auth.uid(), p_test, p_answers, v_correct, v_wrong, v_score, v_total * t.marks_per_question);
  return jsonb_build_object('correct', v_correct, 'wrong', v_wrong, 'unanswered', v_total - v_correct - v_wrong,
                            'score', v_score, 'total', v_total * t.marks_per_question, 'review', v_review);
end $$;

-- Admin dashboard numbers
create or replace function public.admin_stats()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  return jsonb_build_object(
    'students', (select count(*) from profiles where role = 'student'),
    'courses',  (select count(*) from courses),
    'revenue',  (select coalesce(sum(amount),0) from payments where status = 'paid'),
    'revenue_30d', (select coalesce(sum(amount),0) from payments where status = 'paid' and created_at > now() - interval '30 days'),
    'sales',    (select count(*) from payments where status = 'paid'),
    'enrollments', (select count(*) from purchases)
  );
end $$;

-- ---------- Storage ----------
-- "media"  : public  — thumbnails, covers, free notes PDFs
-- "content": private — lesson videos & PDFs, ebook files
insert into storage.buckets (id, name, public) values ('media','media', true)    on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('content','content', false) on conflict (id) do nothing;

create policy "media public read" on storage.objects for select using (bucket_id = 'media');
create policy "media admin write" on storage.objects for insert with check (bucket_id = 'media' and public.is_admin());
create policy "media admin update" on storage.objects for update using (bucket_id = 'media' and public.is_admin());
create policy "media admin delete" on storage.objects for delete using (bucket_id = 'media' and public.is_admin());

-- content paths: courses/<course_id>/... or ebooks/<ebook_id>/...
create or replace function public.can_read_content(p_name text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_kind text := split_part(p_name, '/', 1); v_id uuid;
begin
  if public.is_admin() then return true; end if;
  begin v_id := split_part(p_name, '/', 2)::uuid; exception when others then return false; end;
  if v_kind = 'courses' then
    return public.has_access('course', v_id)
        or exists (select 1 from lessons where course_id = v_id and is_preview
                   and (video_path = p_name or pdf_path = p_name));
  elsif v_kind = 'ebooks' then
    return public.has_access('ebook', v_id);
  end if;
  return false;
end $$;

create policy "content read"   on storage.objects for select using (bucket_id = 'content' and public.can_read_content(name));
create policy "content write"  on storage.objects for insert with check (bucket_id = 'content' and public.is_admin());
create policy "content update" on storage.objects for update using (bucket_id = 'content' and public.is_admin());
create policy "content delete" on storage.objects for delete using (bucket_id = 'content' and public.is_admin());
