-- =============================================================================
--  DEV PROJECT ONLY. Never run this against production.
--  It inserts and deletes two fake users in auth.users.
-- =============================================================================
--  RLS / integrity check for profiles, accounts, categories, transactions.
--
--  How to use: paste the whole file into the Supabase SQL Editor and run it.
--  It runs as `postgres`, impersonates users by switching to the
--  `authenticated` / `anon` roles and setting request.jwt.claims, and prints
--  one PASS/FAIL row per check at the end. Safe to re-run: it removes its
--  own test users first and last.
--
--  Each check matches the EXACT expected outcome (row count or SQLSTATE), so a
--  typo or an unrelated error shows up as FAIL instead of a false PASS:
--    23503 = foreign_key_violation, 23514 = check_violation,
--    42501 = insufficient_privilege / RLS WITH CHECK violation
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Results table + helpers (postgres-owned; only written while role = postgres)
-- ---------------------------------------------------------------------------
drop table if exists pg_temp.rls_results;
create temp table rls_results (
  n          serial primary key,
  check_name text not null,
  status     text not null,
  detail     text
);

create or replace function pg_temp.record(p_name text, p_ok boolean, p_detail text)
returns void language sql as $$
  insert into rls_results (check_name, status, detail)
  values (p_name, case when p_ok then 'PASS' else 'FAIL' end, p_detail);
$$;

-- Switch to a role. p_uid NULL means anon, otherwise authenticated as that user.
create or replace function pg_temp.become(p_uid uuid)
returns void language plpgsql as $$
begin
  if p_uid is null then
    perform set_config('request.jwt.claims', '{"role":"anon"}', true);
    execute 'set local role anon';
  else
    perform set_config('request.jwt.claims',
      json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
  end if;
end;
$$;

-- Runs a `select count(*) ...` as the user and expects p_expected.
-- p_denied_ok: a "permission denied" (42501) also counts as PASS (used for anon).
create or replace function pg_temp.expect_count(
  p_name text, p_uid uuid, p_sql text, p_expected int, p_denied_ok boolean default false)
returns void language plpgsql as $$
declare v_n int; v_ok boolean; v_detail text;
begin
  perform pg_temp.become(p_uid);
  begin
    execute p_sql into v_n;
    v_ok := v_n = p_expected;
    v_detail := format('got %s row(s), expected %s', v_n, p_expected);
  exception when others then
    v_ok := p_denied_ok and sqlstate = '42501';
    v_detail := sqlstate || ': ' || sqlerrm;
  end;
  reset role;
  perform pg_temp.record(p_name, v_ok, v_detail);
end;
$$;

-- Runs an UPDATE/DELETE as the user and expects it to affect p_expected rows.
create or replace function pg_temp.expect_affected(
  p_name text, p_uid uuid, p_sql text, p_expected int)
returns void language plpgsql as $$
declare v_n int; v_ok boolean; v_detail text;
begin
  perform pg_temp.become(p_uid);
  begin
    execute p_sql;
    get diagnostics v_n = row_count;
    v_ok := v_n = p_expected;
    v_detail := format('%s row(s) affected, expected %s', v_n, p_expected);
  exception when others then
    v_ok := false;
    v_detail := sqlstate || ': ' || sqlerrm;
  end;
  reset role;
  perform pg_temp.record(p_name, v_ok, v_detail);
end;
$$;

-- Runs a statement as the user and expects it to fail with p_sqlstate.
-- p_sqlstate NULL = expect success (positive control).
create or replace function pg_temp.expect_error(
  p_name text, p_uid uuid, p_sql text, p_sqlstate text)
returns void language plpgsql as $$
declare v_ok boolean; v_detail text;
begin
  perform pg_temp.become(p_uid);
  begin
    execute p_sql;
    v_ok := p_sqlstate is null;
    v_detail := 'statement succeeded';
  exception when others then
    v_ok := sqlstate = p_sqlstate;
    v_detail := sqlstate || ': ' || sqlerrm;
  end;
  reset role;
  perform pg_temp.record(p_name, v_ok, v_detail);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1. Fixtures (as postgres, which bypasses RLS as table owner)
--    User A = 11111111-…   User B = 22222222-…
--    Row ids: a…01 account, a…02 expense cat, a…03 income cat, a…04 transaction (same for b…)
-- ---------------------------------------------------------------------------
-- Transactions first, so a broken cascade (tested in step 11) can't block re-runs.
delete from public.transactions
where user_id in ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222');
delete from auth.users
where id in ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222');

insert into auth.users (instance_id, id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  -- A: OAuth-style metadata with surrounding spaces, so the trigger must use full_name + btrim
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-4111-8111-111111111111',
   'authenticated', 'authenticated', 'rls-check-a@example.test', '{}',
   '{"full_name": "  Alice Example  "}', now(), now()),
  -- B: 60-char display_name, so the trigger must truncate to 50 instead of failing sign-up
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-4222-8222-222222222222',
   'authenticated', 'authenticated', 'rls-check-b@example.test', '{}',
   json_build_object('display_name', repeat('b', 60))::jsonb, now(), now());

insert into public.accounts (id, user_id, name, type, currency) values
  ('a0000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'A cash', 'cash', 'HUF'),
  ('b0000000-0000-4000-8000-000000000001', '22222222-2222-4222-8222-222222222222', 'B cash', 'cash', 'HUF');

insert into public.categories (id, user_id, name, icon, color, type) values
  ('a0000000-0000-4000-8000-000000000002', '11111111-1111-4111-8111-111111111111', 'A coffee', 'coffee', '#B45309', 'expense'),
  ('a0000000-0000-4000-8000-000000000003', '11111111-1111-4111-8111-111111111111', 'A tutoring', 'book', '#15803D', 'income'),
  ('b0000000-0000-4000-8000-000000000002', '22222222-2222-4222-8222-222222222222', 'B coffee', 'coffee', '#B45309', 'expense');

insert into public.transactions (id, user_id, account_id, category_id, type, amount_minor, currency, occurred_on) values
  ('a0000000-0000-4000-8000-000000000004', '11111111-1111-4111-8111-111111111111',
   'a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002', 'expense', 1500, 'HUF', '2026-11-11'),
  ('b0000000-0000-4000-8000-000000000004', '22222222-2222-4222-8222-222222222222',
   'b0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000002', 'expense', 2500, 'HUF', '2026-11-11');

-- ---------------------------------------------------------------------------
-- 2. Profile trigger
-- ---------------------------------------------------------------------------
select pg_temp.record('trigger: profile created for A with trimmed full_name',
  exists (select 1 from public.profiles where id = '11111111-1111-4111-8111-111111111111' and display_name = 'Alice Example'),
  (select coalesce(display_name, '<null>') from public.profiles where id = '11111111-1111-4111-8111-111111111111'));

select pg_temp.record('trigger: profile created for B with name truncated to 50',
  exists (select 1 from public.profiles where id = '22222222-2222-4222-8222-222222222222' and char_length(display_name) = 50),
  (select 'length ' || coalesce(char_length(display_name)::text, '<null>') from public.profiles where id = '22222222-2222-4222-8222-222222222222'));

-- ---------------------------------------------------------------------------
-- 3. Sanity: A sees own rows + defaults (otherwise "0 rows" checks would prove nothing)
-- ---------------------------------------------------------------------------
select pg_temp.expect_count('A sees own profile', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.profiles where id = '11111111-1111-4111-8111-111111111111'$q$, 1);
select pg_temp.expect_count('A sees own account', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.accounts$q$, 1);
select pg_temp.expect_count('A sees own transaction', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.transactions$q$, 1);
select pg_temp.expect_count('A sees 13 default categories', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.categories where user_id is null$q$, 13);
select pg_temp.expect_count('A sees own 2 categories + 13 defaults, not B''s', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.categories$q$, 15);

-- ---------------------------------------------------------------------------
-- 4. A cannot READ B's rows
-- ---------------------------------------------------------------------------
select pg_temp.expect_count('A cannot read B''s profile', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.profiles where id = '22222222-2222-4222-8222-222222222222'$q$, 0);
select pg_temp.expect_count('A cannot read B''s account', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.accounts where user_id = '22222222-2222-4222-8222-222222222222'$q$, 0);
select pg_temp.expect_count('A cannot read B''s category', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.categories where user_id = '22222222-2222-4222-8222-222222222222'$q$, 0);
select pg_temp.expect_count('A cannot read B''s transaction', '11111111-1111-4111-8111-111111111111',
  $q$select count(*) from public.transactions where user_id = '22222222-2222-4222-8222-222222222222'$q$, 0);

-- ---------------------------------------------------------------------------
-- 5. A cannot UPDATE B's rows (RLS USING hides them → 0 rows affected)
-- ---------------------------------------------------------------------------
select pg_temp.expect_affected('A cannot update B''s profile', '11111111-1111-4111-8111-111111111111',
  $q$update public.profiles set display_name = 'hacked' where id = '22222222-2222-4222-8222-222222222222'$q$, 0);
select pg_temp.expect_affected('A cannot update B''s account', '11111111-1111-4111-8111-111111111111',
  $q$update public.accounts set name = 'hacked' where id = 'b0000000-0000-4000-8000-000000000001'$q$, 0);
select pg_temp.expect_affected('A cannot update B''s category', '11111111-1111-4111-8111-111111111111',
  $q$update public.categories set name = 'hacked' where id = 'b0000000-0000-4000-8000-000000000002'$q$, 0);
select pg_temp.expect_affected('A cannot update B''s transaction', '11111111-1111-4111-8111-111111111111',
  $q$update public.transactions set amount_minor = 1 where id = 'b0000000-0000-4000-8000-000000000004'$q$, 0);

-- ---------------------------------------------------------------------------
-- 6. A cannot DELETE B's rows
-- ---------------------------------------------------------------------------
select pg_temp.expect_affected('A cannot delete B''s profile', '11111111-1111-4111-8111-111111111111',
  $q$delete from public.profiles where id = '22222222-2222-4222-8222-222222222222'$q$, 0);
select pg_temp.expect_affected('A cannot delete B''s account', '11111111-1111-4111-8111-111111111111',
  $q$delete from public.accounts where id = 'b0000000-0000-4000-8000-000000000001'$q$, 0);
select pg_temp.expect_affected('A cannot delete B''s category', '11111111-1111-4111-8111-111111111111',
  $q$delete from public.categories where id = 'b0000000-0000-4000-8000-000000000002'$q$, 0);
select pg_temp.expect_affected('A cannot delete B''s transaction', '11111111-1111-4111-8111-111111111111',
  $q$delete from public.transactions where id = 'b0000000-0000-4000-8000-000000000004'$q$, 0);

-- ---------------------------------------------------------------------------
-- 7. A cannot move own rows to B (UPDATE ... WITH CHECK)
-- ---------------------------------------------------------------------------
select pg_temp.expect_error('A cannot move own account to B', '11111111-1111-4111-8111-111111111111',
  $q$update public.accounts set user_id = '22222222-2222-4222-8222-222222222222' where id = 'a0000000-0000-4000-8000-000000000001'$q$, '42501');
select pg_temp.expect_error('A cannot move own category to B', '11111111-1111-4111-8111-111111111111',
  $q$update public.categories set user_id = '22222222-2222-4222-8222-222222222222' where id = 'a0000000-0000-4000-8000-000000000003'$q$, '42501');
select pg_temp.expect_error('A cannot move own transaction to B', '11111111-1111-4111-8111-111111111111',
  $q$update public.transactions set user_id = '22222222-2222-4222-8222-222222222222' where id = 'a0000000-0000-4000-8000-000000000004'$q$, '42501');
select pg_temp.expect_error('A cannot insert a row owned by B', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.accounts (user_id, name, type, currency) values ('22222222-2222-4222-8222-222222222222', 'x', 'cash', 'HUF')$q$, '42501');

-- ---------------------------------------------------------------------------
-- 8. Transaction integrity: cross-user references + constraints
-- ---------------------------------------------------------------------------
select pg_temp.expect_error('positive control: A can insert a valid transaction', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.transactions (user_id, account_id, category_id, type, amount_minor, currency, occurred_on)
     values ('11111111-1111-4111-8111-111111111111', 'a0000000-0000-4000-8000-000000000001',
             'a0000000-0000-4000-8000-000000000002', 'expense', 990, 'HUF', '2026-11-11')$q$, null);
select pg_temp.expect_error('positive control: A can use a default category', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.transactions (user_id, account_id, category_id, type, amount_minor, currency, occurred_on)
     select '11111111-1111-4111-8111-111111111111', 'a0000000-0000-4000-8000-000000000001', id, 'expense', 500, 'HUF', '2026-11-11'
     from public.categories where key = 'food'$q$, null);
select pg_temp.expect_error('A cannot insert a transaction on B''s account', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.transactions (user_id, account_id, category_id, type, amount_minor, currency, occurred_on)
     values ('11111111-1111-4111-8111-111111111111', 'b0000000-0000-4000-8000-000000000001',
             'a0000000-0000-4000-8000-000000000002', 'expense', 100, 'HUF', '2026-11-11')$q$, '23503');
select pg_temp.expect_error('A cannot repoint own transaction to B''s account', '11111111-1111-4111-8111-111111111111',
  $q$update public.transactions set account_id = 'b0000000-0000-4000-8000-000000000001'
     where id = 'a0000000-0000-4000-8000-000000000004'$q$, '23503');
select pg_temp.expect_error('A cannot insert a transaction with B''s category', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.transactions (user_id, account_id, category_id, type, amount_minor, currency, occurred_on)
     values ('11111111-1111-4111-8111-111111111111', 'a0000000-0000-4000-8000-000000000001',
             'b0000000-0000-4000-8000-000000000002', 'expense', 100, 'HUF', '2026-11-11')$q$, '42501');
select pg_temp.expect_error('currency must match account (EUR on HUF account)', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.transactions (user_id, account_id, category_id, type, amount_minor, currency, occurred_on)
     values ('11111111-1111-4111-8111-111111111111', 'a0000000-0000-4000-8000-000000000001',
             'a0000000-0000-4000-8000-000000000002', 'expense', 100, 'EUR', '2026-11-11')$q$, '23503');
select pg_temp.expect_error('category type must match (expense tx, income category)', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.transactions (user_id, account_id, category_id, type, amount_minor, currency, occurred_on)
     values ('11111111-1111-4111-8111-111111111111', 'a0000000-0000-4000-8000-000000000001',
             'a0000000-0000-4000-8000-000000000003', 'expense', 100, 'HUF', '2026-11-11')$q$, '23503');
select pg_temp.expect_error('amount_minor must be > 0', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.transactions (user_id, account_id, category_id, type, amount_minor, currency, occurred_on)
     values ('11111111-1111-4111-8111-111111111111', 'a0000000-0000-4000-8000-000000000001',
             'a0000000-0000-4000-8000-000000000002', 'expense', 0, 'HUF', '2026-11-11')$q$, '23514');
select pg_temp.expect_error('note max 280 chars', '11111111-1111-4111-8111-111111111111',
  $q$update public.transactions set note = repeat('x', 281) where id = 'a0000000-0000-4000-8000-000000000004'$q$, '23514');
select pg_temp.expect_error('A cannot delete own category that is in use', '11111111-1111-4111-8111-111111111111',
  $q$delete from public.categories where id = 'a0000000-0000-4000-8000-000000000002'$q$, '23503');

-- ---------------------------------------------------------------------------
-- 9. Default categories are read-only
-- ---------------------------------------------------------------------------
select pg_temp.expect_affected('A cannot update a default category', '11111111-1111-4111-8111-111111111111',
  $q$update public.categories set name = 'hacked' where user_id is null$q$, 0);
select pg_temp.expect_affected('A cannot delete a default category', '11111111-1111-4111-8111-111111111111',
  $q$delete from public.categories where user_id is null$q$, 0);
select pg_temp.expect_error('A cannot create a default (user_id null) category', '11111111-1111-4111-8111-111111111111',
  $q$insert into public.categories (user_id, key, name, icon, color, type) values (null, 'evil', 'Evil', 'x', '#000000', 'expense')$q$, '42501');

-- ---------------------------------------------------------------------------
-- 10. anon sees nothing (permission denied or 0 rows both count as PASS)
-- ---------------------------------------------------------------------------
select pg_temp.expect_count('anon cannot read profiles', null, $q$select count(*) from public.profiles$q$, 0, true);
select pg_temp.expect_count('anon cannot read accounts', null, $q$select count(*) from public.accounts$q$, 0, true);
select pg_temp.expect_count('anon cannot read categories', null, $q$select count(*) from public.categories$q$, 0, true);
select pg_temp.expect_count('anon cannot read transactions', null, $q$select count(*) from public.transactions$q$, 0, true);

-- ---------------------------------------------------------------------------
-- 11. Account deletion: deleting the auth user cascades everything
--     (also proves NO ACTION FKs don't block the cascade)
-- ---------------------------------------------------------------------------
do $$
declare v_ok boolean; v_detail text; v_left int;
begin
  begin
    delete from auth.users where id = '11111111-1111-4111-8111-111111111111';
    select (select count(*) from public.profiles     where id      = '11111111-1111-4111-8111-111111111111')
         + (select count(*) from public.accounts     where user_id = '11111111-1111-4111-8111-111111111111')
         + (select count(*) from public.categories   where user_id = '11111111-1111-4111-8111-111111111111')
         + (select count(*) from public.transactions where user_id = '11111111-1111-4111-8111-111111111111')
      into v_left;
    v_ok := v_left = 0;
    v_detail := v_left || ' row(s) left for A';
  exception when others then
    v_ok := false;
    v_detail := sqlstate || ': ' || sqlerrm;
  end;
  perform pg_temp.record('deleting auth user A cascades all of A''s rows', v_ok, v_detail);
end;
$$;

select pg_temp.record('B''s data untouched after all checks',
  (select count(*) from public.transactions where user_id = '22222222-2222-4222-8222-222222222222' and amount_minor = 2500) = 1
  and (select name from public.accounts where id = 'b0000000-0000-4000-8000-000000000001') = 'B cash',
  null);

-- ---------------------------------------------------------------------------
-- 12. Cleanup + report
-- ---------------------------------------------------------------------------
delete from public.transactions
where user_id in ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222');
delete from auth.users
where id in ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222');

select n, status, check_name, detail from rls_results order by n;
