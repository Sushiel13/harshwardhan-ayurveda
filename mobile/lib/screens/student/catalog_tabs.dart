import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'course_screens.dart';
import 'test_screens.dart';
import 'ebook_screen.dart';

// ---------------- Courses ----------------
class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});
  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  String? cat;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Courses')),
        body: Column(children: [
          FutureBuilder<List<Json>>(
            future: Api.categories(),
            builder: (_, s) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('All', cat == null, () => setState(() => cat = null)),
                  ...(s.data ?? []).map((c) => _chip(c['name'], cat == c['id'], () => setState(() => cat = c['id']))),
                ],
              ),
            ),
          ),
          Expanded(child: CourseList(key: ValueKey(cat), categoryId: cat)),
        ]),
      );

  Widget _chip(String label, bool on, VoidCallback tap) => Padding(
        padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          onSelected: (_) => tap(),
          selectedColor: AppColors.forest,
          labelStyle: TextStyle(color: on ? AppColors.ivory : AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
          showCheckmark: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}

class CourseList extends StatelessWidget {
  final String? categoryId;
  const CourseList({super.key, this.categoryId});
  @override
  Widget build(BuildContext context) => AsyncView<List<Json>>(
        load: () => Api.courses(categoryId: categoryId),
        builder: (_, list, __) => list.isEmpty
            ? ListView(children: const [EmptyView(title: 'No courses here yet')])
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisExtent: 270, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: list.length,
                itemBuilder: (_, i) => CourseCard(c: list[i]),
              ),
      );
}

class CourseCard extends StatelessWidget {
  final Json c;
  const CourseCard({super.key, required this.c});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: c))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: 16 / 10, child: Cover(url: c['thumbnail_url'], title: c['title'])),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15.5)),
                  const SizedBox(height: 4),
                  Text(c['subtitle'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  const Spacer(),
                  PriceTag(price: c['price'], mrp: c['mrp'], free: c['is_free'] == true),
                ]),
              ),
            ),
          ]),
        ),
      );
}

// ---------------- Test series ----------------
class TestsTab extends StatelessWidget {
  const TestsTab({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Test series')),
        body: AsyncView<List<Json>>(
          load: Api.testSeries,
          builder: (_, list, __) => list.isEmpty
              ? ListView(children: const [EmptyView(title: 'Test series coming soon')])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesScreen(series: s))),
                        child: Row(children: [
                          SizedBox(width: 110, height: 110, child: Cover(url: s['thumbnail_url'], title: '', tone: AppColors.brass, icon: Icons.fact_check_outlined)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s['title'], maxLines: 2, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15.5)),
                                const SizedBox(height: 4),
                                Text(s['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                                const SizedBox(height: 8),
                                PriceTag(price: s['price'], mrp: s['mrp'], free: s['is_free'] == true),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      );
}

// ---------------- Library: eBooks + free notes ----------------
class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Library'),
            bottom: const TabBar(
              labelColor: AppColors.forest,
              indicatorColor: AppColors.brass,
              tabs: [Tab(text: 'eBooks'), Tab(text: 'Free notes')],
            ),
          ),
          body: TabBarView(children: [
            AsyncView<List<Json>>(
              load: Api.ebooks,
              builder: (_, list, __) => list.isEmpty
                  ? ListView(children: const [EmptyView(title: 'Library is being stocked')])
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, mainAxisExtent: 300, crossAxisSpacing: 14, mainAxisSpacing: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EbookScreen(ebook: e))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Cover(url: e['cover_url'], title: e['title'], tone: AppColors.clay, icon: Icons.menu_book)),
                            ),
                            const SizedBox(height: 8),
                            Text(e['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
                            PriceTag(price: e['price'], mrp: e['mrp'], free: e['is_free'] == true),
                          ]),
                        );
                      },
                    ),
            ),
            AsyncView<List<Json>>(
              load: Api.notes,
              builder: (_, list, __) => list.isEmpty
                  ? ListView(children: const [EmptyView(title: 'Notes coming soon')])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = list[i];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0x1AB5603F), child: Icon(Icons.description_outlined, color: AppColors.clay)),
                            title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(n['subject'] ?? 'General'),
                            trailing: const Icon(Icons.download_rounded),
                            onTap: () => launchUrl(Uri.parse(Api.publicUrl(n['file_path'])), mode: LaunchMode.externalApplication),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      );
}
