-- CI-only psql regression: simulate the old hosted index names and roll back.
\set ON_ERROR_STOP on
begin;
create unique index public_registration_normalized_phone_uidx
  on public.public_registration(normalized_phone);
create unique index competition_application_public_registration_uidx
  on public.competition_application(competition_id,public_registration_id)
  where public_registration_id is not null;
\ir ../migrations/20261013213451_ux_remove_duplicate_registration_indexes.sql
do $$
begin
  if to_regclass('public.public_registration_normalized_phone_uidx') is not null
    or to_regclass('public.competition_application_public_registration_uidx') is not null then
    raise exception 'INDEX CLEANUP FAIL: redundant indexes remain';
  end if;
  if not exists(select 1 from pg_index where indexrelid=to_regclass('public.public_registration_normalized_phone_key') and indisunique and indisvalid)
    or not exists(select 1 from pg_index where indexrelid=to_regclass('public.competition_application_public_uniq') and indisunique and indisvalid) then
    raise exception 'INDEX CLEANUP FAIL: original uniqueness guard lost';
  end if;
end $$;
-- A retry must leave the two original guards intact.
\ir ../migrations/20261013213451_ux_remove_duplicate_registration_indexes.sql
rollback;
select 'INDEX CLEANUP OK (rolled back)';