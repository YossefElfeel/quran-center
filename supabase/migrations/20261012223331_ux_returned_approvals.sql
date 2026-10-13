alter type public.monthly_eval_status add value if not exists 'returned';
alter table public.monthly_student_evaluation add column return_reason text;
alter table public.teacher_development add column return_reason text;

create or replace function public.enforce_monthly_eval_approval() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if tg_op='UPDATE' and old.status::text='approved' and not (private.is_supervisor() or private.is_admin() or private.is_super_admin()) then raise exception 'approved evaluation cannot be edited' using errcode='42501'; end if;
  if new.status::text in ('approved','returned') then
    if not (private.is_supervisor() or private.is_admin() or private.is_super_admin()) then
      raise exception 'only supervisor/admin can decide evaluation' using errcode='42501';
    end if;
    if new.status::text='returned' then
      if coalesce(btrim(new.return_reason),'')='' then raise exception 'return reason required' using errcode='22023'; end if;
      new.approved_by := null; new.approved_at := null;
    else
      new.return_reason := null; new.approved_by := private.current_person_id(); new.approved_at := now();
    end if;
  elsif new.status::text='submitted' then new.return_reason := null;
  end if;
  return new;
end $$;
create or replace function public.enforce_dev_approval() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if tg_op='UPDATE' and old.status::text='approved' and not (private.is_supervisor() or private.is_admin() or private.is_super_admin()) then raise exception 'approved development cannot be edited' using errcode='42501'; end if;
  if new.status::text in ('approved','returned') then
    if not (private.is_supervisor() or private.is_admin() or private.is_super_admin()) then
      raise exception 'only supervisor/admin can decide development' using errcode='42501';
    end if;
    if new.status::text='returned' then
      if coalesce(btrim(new.return_reason),'')='' then raise exception 'return reason required' using errcode='22023'; end if;
      new.approved_by := null; new.approved_at := null;
    else
      new.return_reason := null; new.approved_by := private.current_person_id(); new.approved_at := now();
    end if;
  elsif new.status::text='submitted' then new.return_reason := null;
  end if;
  return new;
end $$;
create function public.notify_returned_evaluation() returns trigger language plpgsql security invoker set search_path='' as $$
declare v_recipient uuid; v_circle uuid; v_type text;
begin
  if new.status::text <> 'returned' or old.status::text = 'returned' then return new; end if;
  if tg_table_name = 'teacher_development' then
    v_recipient := (to_jsonb(new)->>'teacher_person_id')::uuid; v_type := 'development_returned';
  else
    v_recipient := (to_jsonb(new)->>'evaluator_teacher_id')::uuid; v_type := 'monthly_eval_returned';
    select e.circle_id into v_circle from public.enrollment e join public.circle c on c.id=e.circle_id
      where e.student_person_id=(to_jsonb(new)->>'student_person_id')::uuid
      order by (c.teacher_id=v_recipient) desc nulls last, e.enrolled_at desc limit 1;
  end if;
  if v_recipient is not null then
    insert into public.notification(recipient_person_id,type,title,body,route_data) values(v_recipient,v_type,'التقييم رجع للتعديل',new.return_reason,jsonb_build_object('circle_id',v_circle,'evaluation_id',new.id,'month',new.month));
  end if;
  return new;
end $$;
revoke all on function public.notify_returned_evaluation() from public,anon,authenticated;
create trigger monthly_eval_returned after update on public.monthly_student_evaluation for each row execute function public.notify_returned_evaluation();
create trigger development_returned after update on public.teacher_development for each row execute function public.notify_returned_evaluation();
