-- Hosted production already has these uniqueness guards. Record them for fresh
-- databases too: the public submission RPC uses normalized_phone as its UPSERT
-- conflict target. Keep null legacy values and all existing records intact.
create unique index if not exists public_registration_normalized_phone_uidx
  on public.public_registration (normalized_phone);

create unique index if not exists competition_application_public_registration_uidx
  on public.competition_application (competition_id, public_registration_id)
  where public_registration_id is not null;
