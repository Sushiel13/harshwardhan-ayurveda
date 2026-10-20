-- Sample data so the site doesn't look empty on day one.
-- Safe to edit or delete everything from the Admin panel later.

insert into public.categories (name, slug, position) values
  ('BAMS 1st Professional', 'bams-1st-prof', 1),
  ('BAMS 2nd Professional', 'bams-2nd-prof', 2),
  ('BAMS 3rd Professional', 'bams-3rd-prof', 3),
  ('BAMS Final Professional', 'bams-final-prof', 4),
  ('AIAPGET / PG Entrance', 'aiapget', 5),
  ('Government Exams (MO / UPSC-AYUSH)', 'govt-exams', 6)
on conflict (slug) do nothing;

insert into public.courses (title, slug, subtitle, description, category_id, price, mrp, is_free, is_published, is_featured, validity_days)
select * from (values
  ('Padartha Vigyan — Complete Course', 'padartha-vigyan-complete',
   'Foundations of Ayurvedic philosophy, made clear',
   'Every chapter of the CCIM/NCISM syllabus explained with diagrams, mnemonics and previous-year questions. Includes chapter-wise notes and weekly doubt sessions.',
   (select id from public.categories where slug='bams-1st-prof'), 2499.00, 4999.00, false, true, true, 365),
  ('Dravyaguna Vigyan Masterclass', 'dravyaguna-masterclass',
   'Herbs, properties and identification — the clinical way',
   'Rasa-Guna-Virya-Vipaka-Prabhava for 150+ dravyas with photographs, identification tips and high-yield tables for university and PG exams.',
   (select id from public.categories where slug='bams-2nd-prof'), 3499.00, 6999.00, false, true, true, 365),
  ('Kayachikitsa Clinical Series', 'kayachikitsa-clinical',
   'From nidana to chikitsa — case-based learning',
   'Disease-wise lectures that connect classical references to bedside practice, with prescription-writing practice.',
   (select id from public.categories where slug='bams-final-prof'), 4499.00, 8999.00, false, true, true, 365),
  ('AIAPGET Crash Course', 'aiapget-crash-course',
   'High-yield revision for PG entrance',
   'Subject-wise rapid revision, 5,000+ MCQs discussed, and full-length mock tests with analysis.',
   (select id from public.categories where slug='aiapget'), 5999.00, 11999.00, false, true, true, 180),
  ('Sanskrit for Ayurveda — Free Starter', 'sanskrit-starter-free',
   'Read shlokas with confidence',
   'A free starter course on Sanskrit grammar essentials needed for Samhita reading.',
   (select id from public.categories where slug='bams-1st-prof'), 0, null, true, true, false, null)
) as v(title, slug, subtitle, description, category_id, price, mrp, is_free, is_published, is_featured, validity_days)
on conflict (slug) do nothing;

insert into public.test_series (title, description, price, mrp, is_free, is_published, validity_days) values
  ('AIAPGET Full Mock Series 2027', '20 full-length mocks with negative marking, detailed solutions and rank analysis.', 999, 1999, false, true, 365),
  ('BAMS 1st Prof Chapter Tests', 'Chapter-wise tests for Padartha, Sanskrit, Kriya and Rachana Sharir.', 0, null, true, true, null);

insert into public.tests (series_id, title, duration_minutes, marks_per_question, negative_marks, position)
select id, 'Sample Test — Padartha Vigyan Basics', 10, 1, 0, 1 from public.test_series where title = 'BAMS 1st Prof Chapter Tests';

insert into public.questions (test_id, question, options, correct_index, explanation, position)
select t.id, q.question, q.options::jsonb, q.correct_index, q.explanation, q.position
from public.tests t,
(values
  ('How many Padarthas are described in Vaisheshika darshana as accepted in Ayurveda?', '["5","6","7","9"]', 1, 'Ayurveda accepts six Padarthas: Dravya, Guna, Karma, Samanya, Vishesha and Samavaya.', 1),
  ('Which of the following is NOT a Karana Dravya?', '["Akasha","Kala","Guna","Manas"]', 2, 'Guna is a Padartha, not one of the nine Karana Dravyas.', 2),
  ('Pramana that is considered supreme (Pradhana) in Ayurveda is:', '["Pratyaksha","Anumana","Aptopadesha","Yukti"]', 2, 'Aptopadesha (authoritative testimony) is given the highest place.', 3)
) as q(question, options, correct_index, explanation, position)
where t.title = 'Sample Test — Padartha Vigyan Basics';

insert into public.ebooks (title, author, description, price, mrp, is_free, is_published) values
  ('High-Yield Dravyaguna Tables', 'Harshwardhan Institute Faculty', 'Quick-revision tables for 150 important dravyas.', 299, 599, false, true),
  ('Shloka Handbook for 1st Prof', 'Harshwardhan Institute Faculty', 'Important shlokas with meaning and exam context.', 0, null, true, true);

insert into public.testimonials (name, detail, quote, position) values
  ('Aarti S.', 'AIAPGET qualified', 'The mock tests felt exactly like the real exam. Detailed solutions fixed my weak areas in two months.', 1),
  ('Rohit K.', 'BAMS 2nd Prof', 'Dravyaguna finally makes sense. The identification sessions are worth the course fee on their own.', 2),
  ('Sneha P.', 'BAMS Final Year', 'Clinical case discussions changed how I approach patients in OPD.', 3);

insert into public.notifications (title, body) values
  ('Welcome to Harshwardhan Institute of Ayurveda', 'Explore our free starter course and chapter tests to begin.');

insert into public.settings (key, value) values
  ('site', '{"phone":"+91 90000 00000","whatsapp":"919000000000","email":"hello@harshwardhanayurveda.in","address":"Pune, Maharashtra","instagram":"","youtube":"","telegram":""}')
on conflict (key) do nothing;
