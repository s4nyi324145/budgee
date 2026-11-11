-- categories: user_id NULL = shared default category (read-only, visible to everyone signed in).

create table public.categories (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users (id) on delete cascade,
  -- i18n key for default categories; the app shows t(`categories.${key}`) and falls back to name.
  key        text unique check (key ~ '^[a-z_]+$'),
  name       text not null check (char_length(btrim(name)) between 1 and 30),
  icon       text not null check (icon ~ '^[a-z0-9-]+$'),
  color      text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  type       text not null check (type in ('income', 'expense')),
  sort_order smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Defaults always have a key; user categories never do.
  constraint categories_key_only_on_defaults check ((user_id is null) = (key is not null)),
  -- Target for transactions' composite FK (category_id, type): enforces matching type.
  constraint categories_id_type_key unique (id, type)
);

comment on table public.categories is 'Expense/income categories. user_id NULL = shared default.';

-- One name per (user, type), case-insensitive. NULLS NOT DISTINCT (PG15+) makes the
-- defaults (user_id NULL) unique among themselves too.
create unique index categories_user_type_name_uq
  on public.categories (user_id, type, lower(name)) nulls not distinct;

create trigger categories_set_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- Write policies compare auth.uid() = user_id. For defaults that is uid = NULL, which is
-- NULL, which counts as false, so defaults are read-only without extra rules.
-- ---------------------------------------------------------------------------
alter table public.categories enable row level security;
revoke all on table public.categories from anon;

create policy categories_select_own_or_default on public.categories
  for select to authenticated
  using (user_id is null or (select auth.uid()) = user_id);

create policy categories_insert_own on public.categories
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy categories_update_own on public.categories
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy categories_delete_own on public.categories
  for delete to authenticated
  using ((select auth.uid()) = user_id);
