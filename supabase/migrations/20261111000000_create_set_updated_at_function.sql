-- Shared trigger function: keeps `updated_at` current on every UPDATE.
-- Attach per table with:
--   create trigger <table>_set_updated_at before update on public.<table>
--     for each row execute function public.set_updated_at();
--
-- `set search_path = ''` stops search_path hijacking: the function can't be tricked into
-- resolving names from a schema the caller controls. `now()` lives in pg_catalog, which is
-- always searched, so it still resolves.

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function public.set_updated_at() is 'BEFORE UPDATE trigger: sets updated_at = now().';
