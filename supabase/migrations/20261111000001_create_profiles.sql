-- profiles: one row per auth user (1:1). Created automatically by a trigger on auth.users.

create table public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  display_name    text check (char_length(display_name) between 1 and 50),
  currency        char(3) not null default 'HUF' check (currency ~ '^[A-Z]{3}$'),
  -- 1–28 so every month has that day (no February / leap-year special cases).
  month_start_day smallint not null default 1 check (month_start_day between 1 and 28),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table public.profiles is 'Per-user settings. id = auth.users.id.';

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- No INSERT policy: only handle_new_user() creates rows.
-- No DELETE policy: rows are removed via ON DELETE CASCADE when the auth user is deleted.
-- In RLS "no policy" means "denied".
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
revoke all on table public.profiles from anon;

create policy profiles_select_own on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ---------------------------------------------------------------------------
-- Auto-create a profile on sign-up.
-- SECURITY DEFINER: runs as the function owner, because the inserting session
-- (supabase_auth_admin) has no privileges on public.profiles.
-- This must NEVER throw, otherwise the sign-up itself fails. So display_name is
-- normalised to satisfy the 1–50 check (OAuth providers send full_name / name).
-- ---------------------------------------------------------------------------
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(
      left(
        btrim(
          coalesce(
            new.raw_user_meta_data ->> 'display_name',
            new.raw_user_meta_data ->> 'full_name',
            new.raw_user_meta_data ->> 'name',
            ''
          )
        ),
        50
      ),
      ''
    )
  );
  return new;
end;
$$;

-- Trigger functions can't be called via RPC anyway, but keep the API surface minimal.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
