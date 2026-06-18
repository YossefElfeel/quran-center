-- M5.3a: secure national-id storage (PDPL): keyed-HMAC blind index + symmetric
-- encryption, with the pepper kept in Supabase Vault (never in app/code). Also
-- closes the deferred "national-id key custody" item (M2.4).

-- 1) Vault pepper (generated once; stays encrypted at rest in Vault).
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'national_id_pepper') then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'national_id_pepper',
      'Keyed-HMAC pepper + symmetric key for national-id blind index (PDPL).'
    );
  end if;
end $$;

-- 2) Pure digit normalization (Arabic-Indic / Persian -> Western; strip non-digits).
create or replace function public.normalize_national_id(p_raw text)
returns text language sql immutable set search_path = '' as $$
  select regexp_replace(
    translate(coalesce(p_raw, ''),
              '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹',
              '01234567890123456789'),
    '[^0-9]', '', 'g')
$$;

-- 3) Set a person's national id: validate, blind-index (HMAC), encrypt, store last4.
--    Admin/supervisor only. Dedup via the existing unique index on national_id_hmac.
create or replace function public.set_person_national_id(p_person uuid, p_raw text)
returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_norm text;
  v_pepper text;
  v_hmac text;
begin
  if not (public.is_admin() or public.is_supervisor() or public.is_super_admin()) then
    raise exception 'غير مصرّح بتسجيل الرقم القومي' using errcode = '42501';
  end if;

  v_norm := public.normalize_national_id(p_raw);
  if length(v_norm) <> 14 then
    raise exception 'الرقم القومي لازم يكون ١٤ رقم' using errcode = '22023';
  end if;

  select decrypted_secret into v_pepper
    from vault.decrypted_secrets where name = 'national_id_pepper';
  if v_pepper is null then
    raise exception 'national-id pepper not configured';
  end if;

  v_hmac := encode(extensions.hmac(v_norm, v_pepper, 'sha256'), 'hex');

  update public.person
     set national_id_hmac = v_hmac,
         national_id_encrypted = extensions.pgp_sym_encrypt(v_norm, v_pepper),
         national_id_last4 = right(v_norm, 4)
   where id = p_person;

  if not found then
    raise exception 'الشخص مش موجود' using errcode = 'P0002';
  end if;

  return right(v_norm, 4);
exception
  when unique_violation then
    raise exception 'الرقم القومي ده مسجّل قبل كده لشخص تاني' using errcode = '23505';
end;
$$;

revoke all on function public.set_person_national_id(uuid, text) from public, anon;
grant execute on function public.set_person_national_id(uuid, text) to authenticated;
