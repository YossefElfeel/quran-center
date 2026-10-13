-- Remove redundant UX registration indexes only when the original guard is an
-- identical, valid unique index. Keep records, constraints and original names.
do $cleanup$
declare
  v_pair record;
  v_duplicate regclass;
  v_keeper regclass;
  v_matches boolean;
begin
  perform set_config('lock_timeout','5s',true);
  for v_pair in select * from (values
    ('public_registration','public_registration_normalized_phone_uidx','public_registration_normalized_phone_key'),
    ('competition_application','competition_application_public_registration_uidx','competition_application_public_uniq')
  ) as pairs(table_name,duplicate_name,keeper_name)
  loop
    v_duplicate := to_regclass(format('public.%I',v_pair.duplicate_name));
    if v_duplicate is null then continue; end if;
    execute format('lock table public.%I in access exclusive mode',v_pair.table_name);
    v_keeper := to_regclass(format('public.%I',v_pair.keeper_name));
    select d.indisunique and d.indisvalid and d.indisready
      and k.indisunique and k.indisvalid and k.indisready
      and not d.indisreplident and not d.indisclustered
      and d.indrelid=to_regclass(format('public.%I',v_pair.table_name))
      and k.indrelid=d.indrelid
      and not exists(select 1 from pg_constraint c where c.conindid=d.indexrelid)
      and regexp_replace(pg_get_indexdef(d.indexrelid),'^CREATE UNIQUE INDEX [^ ]+ ','')
        = regexp_replace(pg_get_indexdef(k.indexrelid),'^CREATE UNIQUE INDEX [^ ]+ ','')
      into v_matches
    from pg_index d join pg_index k on k.indexrelid=v_keeper
    where d.indexrelid=v_duplicate;
    if v_matches is not true then
      raise exception 'Cannot remove %: identical valid original uniqueness guard required',v_pair.duplicate_name;
    end if;
    execute format('drop index public.%I restrict',v_pair.duplicate_name);
  end loop;
end $cleanup$;