import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_crud.dart';
import 'admin_people.dart';

String _slug(String s) =>
    s.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'(^-|-$)'), '');

class AdminShell extends StatelessWidget {
  final VoidCallback onStudentView;
  const AdminShell({super.key, required this.onStudentView});

  @override
  Widget build(BuildContext context) {
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final tiles = <(IconData, String, String, VoidCallback)>[
      (Icons.school_outlined, 'Courses & videos', 'Create courses, upload lessons, set prices', () => go(const AdminCourses())),
      (Icons.fact_check_outlined, 'Test series', 'Tests, questions, marking', () => go(const AdminSeries())),
      (Icons.menu_book_outlined, 'eBooks', 'Upload PDFs and set prices', () => go(adminEbooks())),
      (Icons.description_outlined, 'Free notes', 'Public PDF downloads', () => go(adminNotes())),
      (Icons.videocam_outlined, 'Live classes', 'Schedule and share links', () => go(const AdminLive())),
      (Icons.campaign_outlined, 'Announcements', 'Message every student', () => go(adminAnnouncements())),
      (Icons.local_offer_outlined, 'Coupons', 'Discount codes', () => go(adminCoupons())),
      (Icons.people_outline, 'Students', 'Search, grant access, block', () => go(const AdminStudents())),
      (Icons.receipt_long_outlined, 'Payments', 'Every sale and its status', () => go(const AdminPayments())),
      (Icons.mail_outline, 'Inquiries', 'Messages from the contact form', () => go(const AdminInquiries())),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(),
        toolbarHeight: 70,
        actions: [
          IconButton(tooltip: 'Student view', onPressed: onStudentView, icon: const Icon(Icons.visibility_outlined)),
          IconButton(tooltip: 'Sign out', onPressed: () => Api.auth.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: AsyncView<Json>(
        load: Api.adminStats,
        builder: (_, s, __) => ListView(padding: const EdgeInsets.all(16), children: [
          const Eyebrow('Admin panel'),
          const SizedBox(height: 4),
          Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.9,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _stat('Revenue (30 days)', inr(asNum(s['revenue_30d'])), dark: true),
              _stat('Revenue (all time)', inr(asNum(s['revenue']))),
              _stat('Students', '${s['students']}'),
              _stat('Paid orders', '${s['sales']}'),
            ],
          ),
          const SizedBox(height: 20),
          ...tiles.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.forestSoft, child: Icon(t.$1, color: AppColors.forest)),
                    title: Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(t.$3),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: t.$4,
                  ),
                ),
              )),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, {bool dark = false}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? AppColors.forest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.forest.withOpacity(.07)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: dark ? AppColors.brassLight : AppColors.inkMute, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: dark ? AppColors.ivory : AppColors.forest)),
        ]),
      );
}

String _priceLabel(Json r) => r['is_free'] == true ? 'Free' : inr(asNum(r['price']));
String _pub(Json r) => r['is_published'] == true ? 'Published' : 'Draft';
Json _fixPrice(Json r) => {...r, 'price': r['is_free'] == true ? 0 : (r['price'] ?? 0)};

// ---------------- Courses ----------------
class AdminCourses extends StatelessWidget {
  const AdminCourses({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Json>>(
        future: Api.categories(),
        builder: (_, s) {
          if (!s.hasData) return const Scaffold(body: Loading());
          final cats = s.data!.map((c) => MapEntry(c['id'] as String, c['name'] as String)).toList();
          return AdminCrudScreen(
            table: 'courses',
            title: 'Courses',
            banner: 'Tap a course to manage its sections and videos. Use ⋮ to edit price, details or publish it.',
            titleOf: (r) => r['title'],
            subtitleOf: (r) => '${_priceLabel(r)} · ${_pub(r)}${r['is_featured'] == true ? ' · Featured' : ''}',
            onOpen: (ctx, r) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => AdminLessons(course: r))),
            beforeSave: (r) => _fixPrice({...r, 'slug': r['slug'] ?? '${_slug(r['title'])}-${(r['id'] as String).substring(0, 4)}'}),
            fields: () => [
              const FieldSpec('title', 'Title', F.text, required: true),
              const FieldSpec('subtitle', 'Short subtitle', F.text),
              const FieldSpec('description', 'Description', F.multiline),
              FieldSpec('category_id', 'Category / exam', F.select, options: cats),
              const FieldSpec('thumbnail_url', 'Thumbnail image (16:10)', F.image),
              const FieldSpec('instructor', 'Instructor', F.text, initial: 'Harshwardhan Institute Faculty'),
              const FieldSpec('language', 'Language', F.text, initial: 'Hindi + English'),
              const FieldSpec('is_free', 'Free course', F.toggle),
              const FieldSpec('price', 'Selling price (₹)', F.number, initial: 0),
              const FieldSpec('mrp', 'MRP / strike-through price (₹)', F.number, help: 'Optional — shows a discount badge'),
              const FieldSpec('validity_days', 'Access validity (days)', F.number, help: 'Leave empty for lifetime access'),
              const FieldSpec('is_featured', 'Show on home page', F.toggle),
              const FieldSpec('is_published', 'Published (visible to students)', F.toggle),
            ],
          );
        },
      );
}

class AdminLessons extends StatefulWidget {
  final Json course;
  const AdminLessons({super.key, required this.course});
  @override
  State<AdminLessons> createState() => _AdminLessonsState();
}

class _AdminLessonsState extends State<AdminLessons> {
  int _v = 0;
  String get cid => widget.course['id'];

  Future<List<dynamic>> _load() => Future.wait([Api.sections(cid), Api.lessons(cid)]);

  Future<void> _section([Json? s]) async {
    final c = TextEditingController(text: s?['title'] ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(s == null ? 'New section' : 'Rename section'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Chapter 1 — Introduction')),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Save'))],
      ),
    );
    if (name == null || name.isEmpty) return;
    if (s == null) {
      final count = (await Api.sections(cid)).length;
      await Api.db.from('course_sections').insert({'course_id': cid, 'title': name, 'position': count + 1});
    } else {
      await Api.db.from('course_sections').update({'title': name}).eq('id', s['id']);
    }
    setState(() => _v++);
  }

  Future<void> _lesson(List<Json> sections, int count, [Json? l]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminForm(
          table: 'lessons',
          title: 'Lesson',
          row: l,
          filter: {'course_id': cid},
          beforeSave: (r) => {...r, 'kind': r['kind'] ?? 'video', 'position': r['position'] ?? count + 1},
          fields: [
            const FieldSpec('title', 'Lesson title', F.text, required: true),
            FieldSpec('section_id', 'Section', F.select, options: sections.map((s) => MapEntry(s['id'] as String, s['title'] as String)).toList()),
            const FieldSpec('kind', 'Type', F.select, initial: 'video', options: [MapEntry('video', 'Video'), MapEntry('pdf', 'PDF only')]),
            FieldSpec('video_path', 'Upload video (MP4)', F.privateFile, fileType: FileType.video, folder: (_) => 'courses/$cid',
                help: 'Stored privately — only enrolled students can stream it.'),
            const FieldSpec('video_url', '…or video link', F.text, help: 'Bunny Stream / Vimeo / unlisted YouTube. Used only if no file is uploaded.'),
            FieldSpec('pdf_path', 'Attach notes PDF', F.privateFile, fileType: FileType.any, folder: (_) => 'courses/$cid'),
            const FieldSpec('description', 'Description', F.multiline),
            const FieldSpec('duration_minutes', 'Duration (minutes)', F.number),
            const FieldSpec('is_preview', 'Free preview (anyone can watch)', F.toggle),
          ],
        ),
      ),
    );
    if (saved == true) setState(() => _v++);
  }

  Future<void> _move(List<Json> lessons, int i, int dir) async {
    final j = i + dir;
    if (j < 0 || j >= lessons.length) return;
    await Api.db.from('lessons').update({'position': j + 1}).eq('id', lessons[i]['id']);
    await Api.db.from('lessons').update({'position': i + 1}).eq('id', lessons[j]['id']);
    setState(() => _v++);
  }

  Future<void> _deleteLesson(Json l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete lesson?'),
        content: Text(l['title']),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete'))],
      ),
    );
    if (ok != true) return;
    final files = [l['video_path'], l['pdf_path']].whereType<String>().toList();
    if (files.isNotEmpty) await Api.db.storage.from('content').remove(files);
    await Api.db.from('lessons').delete().eq('id', l['id']);
    setState(() => _v++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.course['title'], maxLines: 1)),
        body: AsyncView<List<dynamic>>(
          key: ValueKey(_v),
          load: _load,
          builder: (_, d, __) {
            final sections = (d[0] as List).cast<Json>();
            final lessons = (d[1] as List).cast<Json>();
            return Stack(children: [
              ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [
                Text('${lessons.length} lessons · ${sections.length} sections', style: const TextStyle(color: AppColors.inkMute)),
                const SizedBox(height: 12),
                ...[...sections.map((s) => s), null].map((s) {
                  final items = lessons.where((l) => s == null ? (l['section_id'] == null || !sections.any((x) => x['id'] == l['section_id'])) : l['section_id'] == s['id']).toList();
                  if (s == null && items.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        Container(
                          color: AppColors.ivory,
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(children: [
                            Expanded(child: Text(s?['title'] ?? 'Unsectioned', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest))),
                            if (s != null) ...[
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _section(s)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () async {
                                  await Api.db.from('course_sections').delete().eq('id', s['id']);
                                  setState(() => _v++);
                                },
                              ),
                            ],
                          ]),
                        ),
                        if (items.isEmpty) const Padding(padding: EdgeInsets.all(14), child: Text('No lessons yet', style: TextStyle(color: AppColors.inkMute))),
                        ...items.map((l) {
                          final idx = lessons.indexOf(l);
                          final missing = l['kind'] != 'pdf' && l['video_path'] == null && l['video_url'] == null;
                          return ListTile(
                            dense: true,
                            leading: Icon(l['kind'] == 'pdf' ? Icons.description_outlined : Icons.play_circle_outline, color: AppColors.brass),
                            title: Text(l['title']),
                            subtitle: Text([if (missing) '⚠ no video', if (l['is_preview'] == true) 'preview'].join(' · ')),
                            onTap: () => _lesson(sections, lessons.length, l),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'up') _move(lessons, idx, -1);
                                if (v == 'down') _move(lessons, idx, 1);
                                if (v == 'delete') _deleteLesson(l);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'up', child: Text('Move up')),
                                PopupMenuItem(value: 'down', child: Text('Move down')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          );
                        }),
                      ]),
                    ),
                  );
                }),
              ]),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Row(children: [
                  Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(backgroundColor: Colors.white), onPressed: () => _section(), icon: const Icon(Icons.create_new_folder_outlined), label: const Text('Section'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton.icon(onPressed: () => _lesson(sections, lessons.length), icon: const Icon(Icons.add), label: const Text('Lesson'))),
                ]),
              ),
            ]);
          },
        ),
      );
}

// ---------------- Test series → tests → questions ----------------
class AdminSeries extends StatelessWidget {
  const AdminSeries({super.key});
  @override
  Widget build(BuildContext context) => AdminCrudScreen(
        table: 'test_series',
        title: 'Test series',
        banner: 'Tap a series to add tests and questions.',
        titleOf: (r) => r['title'],
        subtitleOf: (r) => '${_priceLabel(r)} · ${_pub(r)}',
        beforeSave: _fixPrice,
        onOpen: (ctx, r) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => AdminTests(series: r))),
        fields: () => const [
          FieldSpec('title', 'Title', F.text, required: true),
          FieldSpec('description', 'Description', F.multiline),
          FieldSpec('thumbnail_url', 'Thumbnail', F.image),
          FieldSpec('is_free', 'Free', F.toggle),
          FieldSpec('price', 'Price (₹)', F.number, initial: 0),
          FieldSpec('mrp', 'MRP (₹)', F.number),
          FieldSpec('validity_days', 'Validity (days)', F.number, help: 'Empty = lifetime'),
          FieldSpec('is_published', 'Published', F.toggle),
        ],
      );
}

class AdminTests extends StatelessWidget {
  final Json series;
  const AdminTests({super.key, required this.series});
  @override
  Widget build(BuildContext context) => AdminCrudScreen(
        table: 'tests',
        title: 'Tests',
        filter: {'series_id': series['id']},
        orderBy: 'position',
        ascending: true,
        banner: series['title'],
        titleOf: (r) => r['title'],
        subtitleOf: (r) => '${r['duration_minutes']} min · −${r['negative_marks']} negative',
        onOpen: (ctx, r) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => AdminQuestions(test: r))),
        fields: () => const [
          FieldSpec('title', 'Test name', F.text, required: true),
          FieldSpec('instructions', 'Instructions', F.multiline),
          FieldSpec('duration_minutes', 'Duration (minutes)', F.number, initial: 30, required: true),
          FieldSpec('marks_per_question', 'Marks per correct answer', F.number, initial: 1),
          FieldSpec('negative_marks', 'Negative marks per wrong answer', F.number, initial: 0),
          FieldSpec('position', 'Order', F.number, initial: 1),
          FieldSpec('is_published', 'Published', F.toggle, initial: true),
        ],
      );
}

class AdminQuestions extends StatefulWidget {
  final Json test;
  const AdminQuestions({super.key, required this.test});
  @override
  State<AdminQuestions> createState() => _AdminQuestionsState();
}

class _AdminQuestionsState extends State<AdminQuestions> {
  int _v = 0;
  Future<List<Json>> _load() => Api.db.from('questions').select().eq('test_id', widget.test['id']).order('position');

  Future<void> _edit(int count, [Json? q]) async {
    final question = TextEditingController(text: q?['question'] ?? '');
    final explanation = TextEditingController(text: q?['explanation'] ?? '');
    final existing = (q?['options'] as List?)?.map((e) => '$e').toList() ?? [];
    final opts = List.generate(existing.length > 4 ? existing.length : 4, (i) => TextEditingController(text: i < existing.length ? existing[i] : ''));
    var correct = (q?['correct_index'] as int?) ?? 0;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (c) => StatefulBuilder(
          builder: (c, set) => Scaffold(
            appBar: AppBar(title: Text(q == null ? 'New question' : 'Edit question')),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              TextField(controller: question, maxLines: 4, decoration: const InputDecoration(labelText: 'Question')),
              const SizedBox(height: 14),
              const Text('Options — select the correct one', style: TextStyle(fontWeight: FontWeight.w600)),
              ...List.generate(opts.length, (i) => Row(children: [
                    Radio<int>(value: i, groupValue: correct, activeColor: AppColors.forest, onChanged: (v) => set(() => correct = v!)),
                    Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: TextField(controller: opts[i], decoration: InputDecoration(hintText: 'Option ${String.fromCharCode(65 + i)}')))),
                  ])),
              const SizedBox(height: 10),
              TextField(controller: explanation, maxLines: 3, decoration: const InputDecoration(labelText: 'Explanation (shown after submit)')),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final o = opts.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
                  if (question.text.trim().isEmpty || o.length < 2) return toast(c, 'Add a question and at least 2 options');
                  final row = {
                    'test_id': widget.test['id'],
                    'question': question.text.trim(),
                    'options': o,
                    'correct_index': correct.clamp(0, o.length - 1),
                    'explanation': explanation.text.trim().isEmpty ? null : explanation.text.trim(),
                    'position': q?['position'] ?? count + 1,
                  };
                  if (q == null) {
                    await Api.db.from('questions').insert(row);
                  } else {
                    await Api.db.from('questions').update(row).eq('id', q['id']);
                  }
                  if (c.mounted) Navigator.pop(c, true);
                },
                child: const Text('Save question'),
              ),
            ]),
          ),
        ),
      ),
    );
    if (saved == true) setState(() => _v++);
  }

  @override
  Widget build(BuildContext context) => AsyncView<List<Json>>(
        key: ValueKey(_v),
        load: _load,
        builder: (_, qs, __) => Scaffold(
          appBar: AppBar(title: Text('${widget.test['title']} (${qs.length})', maxLines: 1)),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.forest,
            foregroundColor: AppColors.ivory,
            onPressed: () => _edit(qs.length),
            icon: const Icon(Icons.add),
            label: const Text('Question'),
          ),
          body: qs.isEmpty
              ? const EmptyView(title: 'No questions yet', text: 'Tip: bulk-import many questions at once from the website admin panel.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: qs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final q = qs[i];
                    final o = (q['options'] as List);
                    return Card(
                      child: ListTile(
                        title: Text('${i + 1}. ${q['question']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('✓ ${o[q['correct_index'] as int]}', style: const TextStyle(color: AppColors.forest)),
                        onTap: () => _edit(qs.length, q),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await Api.db.from('questions').delete().eq('id', q['id']);
                            setState(() => _v++);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}

// ---------------- Other content ----------------
Widget adminEbooks() => AdminCrudScreen(
      table: 'ebooks',
      title: 'eBooks',
      titleOf: (r) => r['title'],
      subtitleOf: (r) => '${_priceLabel(r)} · ${_pub(r)}${r['file_path'] == null ? ' · ⚠ no PDF' : ''}',
      beforeSave: _fixPrice,
      fields: () => [
        const FieldSpec('title', 'Title', F.text, required: true),
        const FieldSpec('author', 'Author', F.text),
        const FieldSpec('description', 'Description', F.multiline),
        const FieldSpec('cover_url', 'Cover image (3:4)', F.image),
        FieldSpec('file_path', 'eBook PDF (private)', F.privateFile, folder: (r) => 'ebooks/${r['id']}', help: 'Only buyers can open it.'),
        const FieldSpec('is_free', 'Free', F.toggle),
        const FieldSpec('price', 'Price (₹)', F.number, initial: 0),
        const FieldSpec('mrp', 'MRP (₹)', F.number),
        const FieldSpec('is_published', 'Published', F.toggle),
      ],
    );

Widget adminNotes() => AdminCrudScreen(
      table: 'notes',
      title: 'Free notes',
      titleOf: (r) => r['title'],
      subtitleOf: (r) => r['subject'] ?? 'General',
      fields: () => [
        const FieldSpec('title', 'Title', F.text, required: true),
        const FieldSpec('subject', 'Subject', F.text, help: 'Notes are grouped by subject'),
        const FieldSpec('description', 'Short description', F.text),
        FieldSpec('file_path', 'PDF file (public)', F.publicFile, required: true, folder: (_) => 'notes'),
        const FieldSpec('is_published', 'Published', F.toggle, initial: true),
      ],
    );

class AdminLive extends StatelessWidget {
  const AdminLive({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Json>>(
        future: Api.db.from('courses').select('id,title'),
        builder: (_, s) {
          if (!s.hasData) return const Scaffold(body: Loading());
          final courses = s.data!.map((c) => MapEntry(c['id'] as String, c['title'] as String)).toList();
          return AdminCrudScreen(
            table: 'live_classes',
            title: 'Live classes',
            orderBy: 'starts_at',
            titleOf: (r) => r['title'],
            subtitleOf: (r) => DateTime.parse(r['starts_at']).toLocal().toString().substring(0, 16),
            fields: () => [
              const FieldSpec('title', 'Class title', F.text, required: true),
              const FieldSpec('description', 'Description', F.multiline),
              const FieldSpec('starts_at', 'Starts at', F.datetime, required: true),
              const FieldSpec('duration_minutes', 'Duration (minutes)', F.number, initial: 60),
              const FieldSpec('meeting_url', 'Meeting link', F.text, help: 'Zoom / Google Meet / YouTube Live'),
              FieldSpec('course_id', 'Only for students of course', F.select, options: courses, help: 'Empty = every logged-in student'),
              const FieldSpec('is_free', 'Open to everyone', F.toggle),
            ],
          );
        },
      );
}

Widget adminAnnouncements() => AdminCrudScreen(
      table: 'notifications',
      title: 'Announcements',
      banner: 'Announcements show on every student’s dashboard and the app’s Updates screen.',
      titleOf: (r) => r['title'],
      subtitleOf: (r) => r['body'] ?? '',
      fields: () => const [
        FieldSpec('title', 'Title', F.text, required: true),
        FieldSpec('body', 'Message', F.multiline),
        FieldSpec('link', 'Link (optional)', F.text),
      ],
    );

Widget adminCoupons() => AdminCrudScreen(
      table: 'coupons',
      title: 'Coupons',
      orderBy: 'code',
      ascending: true,
      titleOf: (r) => r['code'],
      subtitleOf: (r) => '${r['discount_percent']}% off · used ${r['used_count'] ?? 0}${r['max_uses'] != null ? '/${r['max_uses']}' : ''} · ${r['is_active'] == true ? 'active' : 'inactive'}',
      beforeSave: (r) => {...r, 'code': '${r['code']}'.toUpperCase().replaceAll(' ', '')},
      fields: () => const [
        FieldSpec('code', 'Code', F.text, required: true, help: 'e.g. DIWALI25'),
        FieldSpec('discount_percent', 'Discount %', F.number, required: true),
        FieldSpec('max_uses', 'Maximum uses', F.number, help: 'Empty = unlimited'),
        FieldSpec('expires_at', 'Expires at', F.datetime),
        FieldSpec('is_active', 'Active', F.toggle, initial: true),
      ],
    );
