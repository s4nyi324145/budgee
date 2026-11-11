-- transactions: amounts are positive integers in minor units; direction comes from `type`.

create table public.transactions (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users (id) on delete cascade,
  account_id        uuid not null,
  category_id       uuid not null,
  type              text not null check (type in ('income', 'expense')),
  amount_minor      bigint not null check (amount_minor > 0),
  currency          char(3) not null,
  -- No default: current_date is UTC, the app sends the user's local date.
  occurred_on       date not null,
  note              text check (char_length(note) <= 280),
  -- FK to recurring_rules is added in a later migration.
  recurring_rule_id uuid,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  -- Same owner + same currency as the account. Holds even when RLS is bypassed (service_role).
  -- NO ACTION (default) instead of RESTRICT: checked at statement end, so deleting an
  -- auth user (which cascades to both tables) still works, while deleting an account
  -- that still has transactions does not.
  constraint transactions_account_fk
    foreign key (account_id, user_id, currency)
    references public.accounts (id, user_id, currency),

  -- Category type must match transaction type.
  constraint transactions_category_type_fk
    foreign key (category_id, type)
    references public.categories (id, type)
);

comment on table public.transactions is 'Income/expense entries. amount_minor > 0, sign comes from type.';
comment on column public.transactions.recurring_rule_id is 'FK to recurring_rules added in a later migration.';

create index transactions_user_occurred_on_idx on public.transactions (user_id, occurred_on desc);
-- Postgres does not index FK columns automatically; these keep FK checks on delete fast.
create index transactions_account_id_idx on public.transactions (account_id);
create index transactions_category_id_idx on public.transactions (category_id);

create trigger transactions_set_updated_at
  before update on public.transactions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- Account ownership is enforced by the composite FK above. Category ownership
-- ("mine or default") can't be expressed as an FK, so it lives in WITH CHECK.
-- ---------------------------------------------------------------------------
alter table public.transactions enable row level security;
revoke all on table public.transactions from anon;

create policy transactions_select_own on public.transactions
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy transactions_insert_own on public.transactions
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.categories c
      where c.id = category_id
        and (c.user_id is null or c.user_id = (select auth.uid()))
    )
  );

create policy transactions_update_own on public.transactions
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.categories c
      where c.id = category_id
        and (c.user_id is null or c.user_id = (select auth.uid()))
    )
  );

create policy transactions_delete_own on public.transactions
  for delete to authenticated
  using ((select auth.uid()) = user_id);
