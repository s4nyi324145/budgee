-- accounts: where money lives (cash, card, savings). One currency per account.

create table public.accounts (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users (id) on delete cascade,
  name                  text not null check (char_length(btrim(name)) between 1 and 40),
  type                  text not null check (type in ('cash', 'card', 'savings')),
  -- No default on purpose: the app sends the profile currency explicitly.
  currency              char(3) not null check (currency ~ '^[A-Z]{3}$'),
  -- A balance may be negative (overdrawn card). The "no signs" rule applies to transaction amounts.
  initial_balance_minor bigint not null default 0,
  archived              boolean not null default false,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),

  -- Target for transactions' composite FK (account_id, user_id, currency):
  -- guarantees a transaction's account has the same owner and currency.
  constraint accounts_id_user_currency_key unique (id, user_id, currency)
);

comment on table public.accounts is 'User money accounts. Archive instead of delete once transactions exist.';

create index accounts_user_id_idx on public.accounts (user_id);

create trigger accounts_set_updated_at
  before update on public.accounts
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.accounts enable row level security;
revoke all on table public.accounts from anon;

create policy accounts_select_own on public.accounts
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy accounts_insert_own on public.accounts
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- WITH CHECK stops moving a row to another user (update ... set user_id = '<other>').
create policy accounts_update_own on public.accounts
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy accounts_delete_own on public.accounts
  for delete to authenticated
  using ((select auth.uid()) = user_id);
