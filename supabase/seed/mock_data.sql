-- بيانات تجريبية شاملة لاختبار كل المسارات (mock data).  NOT a migration — لا يُطبّق
-- في CI. شغّله يدويًا على DB التطوير عبر MCP execute_sql أو psql. كل مرحلة idempotent
-- (بتشتغل مرة واحدة عبر marker في system_settings: mock_v1_a/b/c).
--
-- يفترض وجود حسابات الأدوار (teacher@/parent@/supervisor@/... على qurancenter.app)
-- والـ seed الأساسي (حلقة تجريبية + طالب تجريبي + أسرة تجريبية).
--
-- لإعادة التهيئة (reset): امسح صفوف الـ mock + الـ markers، ثم أعد التشغيل:
--   delete from public.system_settings where key in ('mock_v1_a','mock_v1_b','mock_v1_c');
--   (وامسح الكيانات التجريبية حسب الحاجة قبل إعادة التشغيل لتفادي التكرار.)
--
-- ملاحظة: eligible_certificate_students() بترجّع كل من عدّى كل مقاطعه المسندة (مفيش
-- مقطع غير passed) — فالطلبة اللي عندهم مقطع واحد ناجح بيظهروا مؤهّلين؛ ده سلوك
-- النظام الفعلي (مفيش مقاطع متبقّية عليهم) ومناسب لاختبار مسار الترشيح/الإصدار.

-- ============================ المرحلة A — النواة ============================
do $$
declare
  v_curr uuid; v_lvl1 uuid; v_lvl2 uuid; v_circle1 uuid; v_circle2 uuid;
  v_teacher uuid; v_parent uuid; v_existing uuid;
  v_ahmed uuid; v_yusuf uuid; v_khaled uuid; v_sara uuid; v_maryam uuid; v_omar uuid; v_bilal uuid;
  v_gA uuid; v_gM uuid; v_gY uuid;
  v_p1 uuid; v_p2 uuid; v_p3 uuid; v_p4 uuid;
  v_e_existing uuid; v_e_ahmed uuid; v_e_yusuf uuid; v_e_khaled uuid; v_e_sara uuid; v_e_maryam uuid;
  v_hh_existing uuid; v_hh_ali uuid; v_hh_tariq uuid; v_hh_hasan uuid;
  v_active int;
begin
  if exists (select 1 from public.system_settings where key='mock_v1_a') then return; end if;

  select id into v_curr from public.curriculum where name='منهج تجريبي' limit 1;
  if v_curr is null then insert into public.curriculum (name) values ('منهج تجريبي') returning id into v_curr; end if;
  select id into v_lvl1 from public.level where curriculum_id=v_curr and ord=1 limit 1;
  if v_lvl1 is null then insert into public.level (curriculum_id,ord,name) values (v_curr,1,'المستوى ١') returning id into v_lvl1; end if;
  insert into public.level (curriculum_id,ord,name) values (v_curr,2,'المستوى ٢') returning id into v_lvl2;

  select ap.person_id into v_teacher from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='teacher@qurancenter.app';
  select ap.person_id into v_parent  from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='parent@qurancenter.app';
  select id into v_existing from public.person where full_name='طالب تجريبي' limit 1;

  select id into v_circle1 from public.circle where name='حلقة تجريبية' limit 1;
  if v_circle1 is null then insert into public.circle (level_id,name,teacher_id,status) values (v_lvl1,'حلقة تجريبية',v_teacher,'active') returning id into v_circle1; end if;
  insert into public.circle (level_id,name,teacher_id,status) values (v_lvl1,'حلقة العصر',v_teacher,'active') returning id into v_circle2;

  insert into public.person (full_name,gender,is_minor) values ('أحمد علي','male',true) returning id into v_ahmed;
  insert into public.person (full_name,gender,is_minor) values ('يوسف حسن','male',true) returning id into v_yusuf;
  insert into public.person (full_name,gender,is_minor) values ('خالد سمير','male',true) returning id into v_khaled;
  insert into public.person (full_name,gender,is_minor) values ('سارة محمود','female',true) returning id into v_sara;
  insert into public.person (full_name,gender,is_minor) values ('مريم طارق','female',true) returning id into v_maryam;
  insert into public.person (full_name,gender,is_minor) values ('عمر فاروق','male',true) returning id into v_omar;
  insert into public.person (full_name,gender,is_minor) values ('بلال صلاح','male',true) returning id into v_bilal;
  insert into public.person (full_name,gender) values ('والد أحمد','male') returning id into v_gA;
  insert into public.person (full_name,gender) values ('والدة مريم','female') returning id into v_gM;
  insert into public.person (full_name,gender) values ('والد يوسف','male') returning id into v_gY;

  insert into public.enrollment (student_person_id,circle_id,status) values
    (v_ahmed,v_circle1,'active'),(v_yusuf,v_circle1,'active'),(v_khaled,v_circle1,'active'),
    (v_sara,v_circle1,'active'),(v_maryam,v_circle1,'active'),
    (v_omar,v_circle2,'active'),(v_bilal,v_circle2,'active');
  select id into v_e_existing from public.enrollment where student_person_id=v_existing and circle_id=v_circle1 limit 1;
  select id into v_e_ahmed  from public.enrollment where student_person_id=v_ahmed  limit 1;
  select id into v_e_yusuf  from public.enrollment where student_person_id=v_yusuf  limit 1;
  select id into v_e_khaled from public.enrollment where student_person_id=v_khaled limit 1;
  select id into v_e_sara   from public.enrollment where student_person_id=v_sara   limit 1;
  select id into v_e_maryam from public.enrollment where student_person_id=v_maryam limit 1;

  insert into public.guardian_link (guardian_person_id,student_person_id,relation) values
    (v_parent,v_sara,'ابنة'),(v_gA,v_ahmed,'ابن'),(v_gM,v_maryam,'ابنة'),(v_gM,v_khaled,'ابن'),(v_gY,v_yusuf,'ابن');

  select id into v_hh_existing from public.household where name='أسرة تجريبية' limit 1;
  if v_hh_existing is not null then
    insert into public.household_member (household_id,person_id,role) values (v_hh_existing,v_sara,'student') on conflict do nothing;
  end if;
  insert into public.household (name,monthly_amount,created_at) values ('أسرة آل علي',10, now()-interval '40 days') returning id into v_hh_ali;
  insert into public.household_member (household_id,person_id,role) values (v_hh_ali,v_gA,'guardian'),(v_hh_ali,v_ahmed,'student');
  insert into public.household (name,monthly_amount) values ('أسرة آل طارق',10) returning id into v_hh_tariq;
  insert into public.household_member (household_id,person_id,role) values (v_hh_tariq,v_gM,'guardian'),(v_hh_tariq,v_maryam,'student'),(v_hh_tariq,v_khaled,'student');
  insert into public.subscription_payment (household_id,amount,period_month) values (v_hh_tariq,10,date_trunc('month',now())::date);
  insert into public.household (name,monthly_amount) values ('أسرة آل حسن',10) returning id into v_hh_hasan;
  insert into public.household_member (household_id,person_id,role) values (v_hh_hasan,v_gY,'guardian'),(v_hh_hasan,v_yusuf,'student');
  insert into public.subscription_payment (household_id,amount,period_month) values
    (v_hh_hasan,10,date_trunc('month',now())::date),
    (v_hh_hasan,10,(date_trunc('month',now())-interval '1 month')::date);

  insert into public.portion (name,surah_start,ayah_start,surah_end,ayah_end) values ('المقطع ١ — قصار السور',110,1,114,6) returning id into v_p1;
  insert into public.portion (name,surah_start,ayah_start,surah_end,ayah_end) values ('المقطع ٢',105,1,109,6) returning id into v_p2;
  insert into public.portion (name,surah_start,ayah_start,surah_end,ayah_end) values ('المقطع ٣',100,1,104,9) returning id into v_p3;
  insert into public.portion (name,surah_start,ayah_start,surah_end,ayah_end) values ('المقطع ٤',95,1,99,8) returning id into v_p4;

  select count(*) into v_active from public.enrollment where circle_id=v_circle1 and status='active';
  insert into public.group_portion_cycle (circle_id,portion_id,ord,active_at_open) values (v_circle1,v_p1,1,v_active);

  perform public.record_tasmee(p_enrollment_id=>v_e_existing,p_student_person_id=>v_existing,p_portion_id=>v_p1,p_score=>8::smallint,p_passed=>true, p_idempotency_key=>gen_random_uuid(),p_teacher_id=>v_teacher);
  perform public.record_tasmee(p_enrollment_id=>v_e_ahmed, p_student_person_id=>v_ahmed, p_portion_id=>v_p1,p_score=>9::smallint,p_passed=>true, p_idempotency_key=>gen_random_uuid(),p_teacher_id=>v_teacher);
  perform public.record_tasmee(p_enrollment_id=>v_e_yusuf, p_student_person_id=>v_yusuf, p_portion_id=>v_p1,p_score=>8::smallint,p_passed=>true, p_idempotency_key=>gen_random_uuid(),p_teacher_id=>v_teacher);
  perform public.record_tasmee(p_enrollment_id=>v_e_khaled,p_student_person_id=>v_khaled,p_portion_id=>v_p1,p_score=>4::smallint,p_passed=>false,p_idempotency_key=>gen_random_uuid(),p_teacher_id=>v_teacher);
  perform public.record_tasmee(p_enrollment_id=>v_e_sara,  p_student_person_id=>v_sara,  p_portion_id=>v_p1,p_score=>8::smallint,p_passed=>true, p_idempotency_key=>gen_random_uuid(),p_teacher_id=>v_teacher);
  perform public.record_tasmee(p_enrollment_id=>v_e_maryam,p_student_person_id=>v_maryam,p_portion_id=>v_p1,p_score=>9::smallint,p_passed=>true, p_idempotency_key=>gen_random_uuid(),p_teacher_id=>v_teacher);

  insert into public.portion_ledger_entry (student_person_id,portion_id,state,attempts_count,passed_on) values
    (v_yusuf,v_p2,'passed',1,current_date),(v_yusuf,v_p3,'passed',1,current_date),(v_yusuf,v_p4,'passed',1,current_date);

  insert into public.system_settings (key,value) values ('mock_v1_a','true'::jsonb);
end $$;

-- ===================== المرحلة B — الحصص والتقييمات =====================
do $$
declare
  v_circle1 uuid; v_teacher uuid; v_supervisor uuid; v_parent uuid;
  v_existing uuid; v_ahmed uuid; v_yusuf uuid; v_khaled uuid; v_sara uuid; v_maryam uuid;
  v_gA uuid; v_gM uuid; v_lvl1 uuid; v_p1 uuid; v_p2 uuid; v_e_existing uuid;
  v_last date := (date_trunc('month',now())-interval '1 month')::date;
  v_eval uuid; v_sess_open uuid; v_wait uuid;
begin
  if exists (select 1 from public.system_settings where key='mock_v1_b') then return; end if;

  select id into v_circle1 from public.circle where name='حلقة تجريبية' limit 1;
  select ap.person_id into v_teacher    from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='teacher@qurancenter.app';
  select ap.person_id into v_supervisor from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='supervisor@qurancenter.app';
  select ap.person_id into v_parent     from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='parent@qurancenter.app';
  select id into v_existing from public.person where full_name='طالب تجريبي' limit 1;
  select id into v_ahmed  from public.person where full_name='أحمد علي' limit 1;
  select id into v_yusuf  from public.person where full_name='يوسف حسن' limit 1;
  select id into v_khaled from public.person where full_name='خالد سمير' limit 1;
  select id into v_sara   from public.person where full_name='سارة محمود' limit 1;
  select id into v_maryam from public.person where full_name='مريم طارق' limit 1;
  select id into v_gA from public.person where full_name='والد أحمد' limit 1;
  select id into v_gM from public.person where full_name='والدة مريم' limit 1;
  select l.id into v_lvl1 from public.level l join public.curriculum c on c.id=l.curriculum_id where c.name='منهج تجريبي' and l.ord=1 limit 1;
  select id into v_p1 from public.portion where name='المقطع ١ — قصار السور' limit 1;
  select id into v_p2 from public.portion where name='المقطع ٢' limit 1;
  select id into v_e_existing from public.enrollment where student_person_id=v_existing and circle_id=v_circle1 limit 1;

  insert into public.circle_session (circle_id, session_date, status, opened_by, closed_at)
  select v_circle1, (date_trunc('month',now())::date + g), 'closed', v_teacher, now() from generate_series(2,14,3) g;
  insert into public.circle_session (circle_id, session_date, status, opened_by)
  values (v_circle1, current_date, 'open', v_teacher) returning id into v_sess_open;
  insert into public.circle_session (circle_id, session_date, status, opened_by, closed_at)
  select v_circle1, (v_last + g), 'closed', v_teacher, now() from generate_series(4,25,7) g;

  insert into public.attendance (session_id, enrollment_id, status)
  select cs.id, e.id,
    (array['present','present','present','present','late','absent','absent_excused']::public.attendance_status[])
      [1 + (abs(hashtext(cs.id::text||e.id::text)) % 7)]
  from public.circle_session cs
  join public.enrollment e on e.circle_id=cs.circle_id and e.status='active'
  where cs.circle_id=v_circle1 and cs.status='closed';

  insert into public.behavioral_note (student_person_id, teacher_id, text, visibility) values
   (v_existing, v_teacher, 'متعاون وملتزم في الحلقة', 'parent'),
   (v_khaled,   v_teacher, 'محتاج متابعة أكتر في الحفظ', 'parent'),
   (v_ahmed,    v_teacher, 'ملاحظة داخلية للإدارة', 'internal');

  insert into public.supervisor_evaluation (circle_id, supervisor_id, selection) values (v_circle1, v_supervisor, 'random') returning id into v_eval;
  insert into public.eval_score (evaluation_id, student_person_id, criterion, score) values
   (v_eval,v_ahmed,'memorization',9),(v_eval,v_ahmed,'recitation',8),(v_eval,v_ahmed,'mushaf_reading',7),
   (v_eval,v_maryam,'memorization',10),(v_eval,v_maryam,'recitation',9),(v_eval,v_maryam,'mushaf_reading',9);

  insert into public.monthly_study_plan (circle_id, month, curriculum_plan, teaching_method, portions_ref, published, set_by) values
   (v_circle1, date_trunc('month',now())::date, 'حفظ المقطع ١ ومراجعة قصار السور', 'تلقين + تكرار جماعي', 'المقطع ١', true, v_teacher),
   (v_circle1, v_last, 'حفظ قصار السور', 'تلقين فردي', 'قصار السور', true, v_teacher);

  insert into public.monthly_student_evaluation (student_person_id, month, status, tasmee_avg, attendance_rate, behavior, evaluator_teacher_id) values
   (v_ahmed,    v_last, 'submitted', 8.50, 0.900, 'ممتاز ومنتظم', v_teacher),
   (v_sara,     v_last, 'draft',     8.00, 0.850, 'جيد جدًا', v_teacher),
   (v_existing, v_last, 'draft',     7.50, 0.800, 'جيد', v_teacher);

  insert into public.monthly_top_student (circle_id, month, student_person_id, reason) values (v_circle1, v_last, v_maryam, 'الأعلى حضورًا وتسميعًا');

  insert into public.excuse_request (enrollment_id, session_id, reason, status) values (v_e_existing, v_sess_open, 'سفر مع العائلة', 'pending');

  insert into public.person (full_name, gender, is_minor) values ('طالب منتظر', 'male', true) returning id into v_wait;
  insert into public.waiting_list (student_person_id, level_id, status) values (v_wait, v_lvl1, 'waiting');
  insert into public.placement_test (student_person_id, supervisor_id, result_level_id, notes) values (v_wait, v_supervisor, v_lvl1, 'مستوى مبتدئ — يبدأ من قصار السور');

  insert into public.parent_comment (student_person_id, author_guardian_id, body) values (v_existing, v_parent, 'شكرًا على المجهود مع ابني');

  insert into public.teacher_profile (teacher_person_id, cv, qualifications, certificates)
  values (v_teacher, 'محفّظ بخبرة ٥ سنوات', '["إجازة برواية حفص"]'::jsonb, '["دورة تجويد متقدّمة"]'::jsonb)
  on conflict (teacher_person_id) do nothing;
  insert into public.teacher_development (teacher_person_id, month, memorization_progress, ijazah, courses, status) values
   (v_teacher, date_trunc('month',now())::date, 'أتم مراجعة جزء عمّ', '["إجازة برواية حفص"]'::jsonb, '["دورة في أصول التدريس"]'::jsonb, 'submitted');

  insert into public.teacher_rating (teacher_person_id, parent_person_id, period, stars, comment, hidden_by_manager, hidden_reason) values
   (v_teacher, v_parent, date_trunc('month',now())::date, 5, 'محفّظ ممتاز وصبور', false, null),
   (v_teacher, v_gA,     date_trunc('month',now())::date, 4, 'جيد', false, null),
   (v_teacher, v_gM,     date_trunc('month',now())::date, 2, 'تعليق غير لائق', true, 'تعليق مسيء — مخفي');

  insert into public.session_plan (circle_id, for_session_id, memorization_portion_id, revision_portion_id, set_by)
  values (v_circle1, v_sess_open, v_p2, v_p1, v_teacher);

  insert into public.system_settings (key,value) values ('mock_v1_b','true'::jsonb);
end $$;

-- ============== المرحلة C — الشكاوى/المسابقة/الشهادات/الوسائط ==============
do $$
declare
  v_teacher uuid; v_supervisor uuid; v_parent uuid;
  v_ahmed uuid; v_yusuf uuid; v_sara uuid; v_maryam uuid; v_gM uuid;
  v_comp uuid; v_cat1 uuid; v_cat2 uuid; v_reg1 uuid; v_reg2 uuid;
  v_app_ahmed uuid; v_app_reg1 uuid;
begin
  if exists (select 1 from public.system_settings where key='mock_v1_c') then return; end if;

  select ap.person_id into v_teacher    from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='teacher@qurancenter.app';
  select ap.person_id into v_supervisor from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='supervisor@qurancenter.app';
  select ap.person_id into v_parent     from public.app_user ap join auth.users au on au.id=ap.auth_user_id where au.email='parent@qurancenter.app';
  select id into v_ahmed  from public.person where full_name='أحمد علي' limit 1;
  select id into v_yusuf  from public.person where full_name='يوسف حسن' limit 1;
  select id into v_sara   from public.person where full_name='سارة محمود' limit 1;
  select id into v_maryam from public.person where full_name='مريم طارق' limit 1;
  select id into v_gM from public.person where full_name='والدة مريم' limit 1;

  insert into public.complaint (author_person_id, category, body, status, created_at)
  values (v_parent, 'academic', 'ابني محتاج متابعة أكتر في الحفظ', 'open', now()-interval '4 days');
  insert into public.complaint (author_person_id, category, body, status, manager_response, responded_at, created_at)
  values (v_parent, 'financial', 'استفسار عن قيمة الاشتراك', 'answered', 'تم الرد: الاشتراك ١٠ جنيه شهريًا', now()-interval '8 days', now()-interval '10 days');

  insert into public.certificate (student_person_id, kind, issued_at, approved_by) values (v_maryam, 'honor', current_date, v_supervisor);

  insert into public.competition (name, year, status) values ('مسابقة رمضان السنوية', 2026, 'open') returning id into v_comp;
  insert into public.competition_category (competition_id, name, min_age, max_age) values (v_comp,'الفئة الصغرى',6,12) returning id into v_cat1;
  insert into public.competition_category (competition_id, name, min_age, max_age) values (v_comp,'الفئة الكبرى',13,18) returning id into v_cat2;

  insert into public.public_registration (name, phone, consent_ack, normalized_phone) values ('متسابق عام ١','01000000001', true, '01000000001') returning id into v_reg1;
  insert into public.public_registration (name, phone, consent_ack, normalized_phone) values ('متسابق عام ٢','01000000002', true, '01000000002') returning id into v_reg2;
  insert into public.public_registration (name, phone, consent_ack, normalized_phone, created_at) values ('تسجيل قديم للتنظيف','01000000009', false, '01000000009', now()-interval '120 days');

  insert into public.competition_application (competition_id, category_id, origin, student_person_id, status, youtube_url)
  values (v_comp, v_cat2, 'internal_student', v_ahmed, 'accepted', 'https://youtu.be/demo1') returning id into v_app_ahmed;
  insert into public.competition_application (competition_id, category_id, origin, student_person_id, status)
  values (v_comp, v_cat2, 'internal_student', v_yusuf, 'pending');
  insert into public.competition_application (competition_id, category_id, origin, public_registration_id, status, youtube_url)
  values (v_comp, v_cat1, 'public', v_reg1, 'accepted', 'https://youtu.be/demo2') returning id into v_app_reg1;
  insert into public.competition_application (competition_id, category_id, origin, public_registration_id, status)
  values (v_comp, v_cat1, 'public', v_reg2, 'pending');

  insert into public.competition_judge (competition_id, judge_person_id) values (v_comp, v_supervisor);
  insert into public.competition_score (application_id, judge_person_id, score, notes) values
   (v_app_ahmed, v_supervisor, 85.50, 'أداء جيد'),
   (v_app_reg1,  v_supervisor, 90.00, 'متميّز');

  insert into public.course (title, video_url, description, is_free) values
   ('مقدمة في التجويد','https://youtu.be/c1','أساسيات مخارج الحروف', true),
   ('أحكام النون الساكنة والتنوين','https://youtu.be/c2','شرح مبسّط بالأمثلة', true),
   ('آداب طالب القرآن','https://youtu.be/c3','سلسلة تربوية قصيرة', true);

  insert into public.media (student_person_id, type, storage_path, watermarked, uploaded_by) values
   (v_sara,   'video', 'sara/v1.mp4',   true, v_teacher),
   (v_ahmed,  'photo', 'ahmed/p1.jpg',  true, v_teacher),
   (v_maryam, 'photo', 'maryam/p1.jpg', true, v_teacher);
  insert into public.consent_record (student_person_id, scope, granted_by) values (v_maryam, 'photo', v_gM);

  insert into public.notification (recipient_person_id, type, title, body) values
   (v_parent,  'progress_card',        'بطاقة التقدّم الشهرية جاهزة', 'بطاقة تقدّم ابنك للشهر اللي فات بقت متاحة في التطبيق.'),
   (v_parent,  'subscription_overdue', 'تذكير اشتراك',               'لو سمحت سدّد اشتراك الشهر.'),
   (v_teacher, 'complaint_overdue',    'شكوى محتاجة رد',             'فيه شكوى عدّى عليها أكتر من ٤٨ ساعة.');

  insert into public.system_settings (key,value) values ('mock_v1_c','true'::jsonb);
end $$;
