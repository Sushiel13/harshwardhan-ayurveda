import 'package:flutter/material.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'course_screens.dart';
import 'live_screen.dart';
import 'catalog_tabs.dart';

class HomeTab extends StatelessWidget {
  final void Function(int tab) goTo;
  const HomeTab({super.key, required this.goTo});

  Future<Map<String, dynamic>> _load() async {
    final r = await Future.wait([Api.myProfile(), Api.courses(featured: true), Api.categories(), Api.notifications()]);
    return {'profile': r[0], 'featured': r[1], 'categories': r[2], 'notifications': r[3]};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AsyncView<Map<String, dynamic>>(
        load: _load,
        builder: (context, d, _) {
          final name = ((d['profile'] as Map?)?['full_name'] as String? ?? '').split(' ').first;
          final featured = (d['featured'] as List).cast<Map<String, dynamic>>();
          final cats = (d['categories'] as List).cast<Map<String, dynamic>>();
          final notes = (d['notifications'] as List).cast<Map<String, dynamic>>();
          return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(children: [
                const BrandTitle(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(items: notes))),
                ),
              ]),
            ),
            // Hero card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  color: AppColors.forest,
                  height: 190,
                  child: Stack(children: [
                    Positioned(right: -40, top: -30, child: CustomPaint(size: const Size(230, 230), painter: PetalPainter(opacity: .35))),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Eyebrow('Namaste', color: AppColors.brassLight),
                        const SizedBox(height: 6),
                        Text(name.isEmpty ? 'Ready to learn?' : '$name, ready to learn?',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.ivory)),
                        const Spacer(),
                        Row(children: [
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.brass, foregroundColor: AppColors.forestDeep, minimumSize: const Size(0, 42)),
                            onPressed: () => goTo(1),
                            child: const Text('Explore courses'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveScreen())),
                            child: const Text('Live classes →', style: TextStyle(color: AppColors.ivory)),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            if (cats.isNotEmpty) ...[
              const SectionHeader(eyebrow: 'Choose your path', title: 'What are you preparing for?'),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, k) => InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => Scaffold(appBar: AppBar(title: Text(cats[k]['name'])), body: CourseList(categoryId: cats[k]['id'])))),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.forest.withOpacity(.08))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('0${k + 1}', style: const TextStyle(color: AppColors.brass, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(cats[k]['name'], maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
            SectionHeader(eyebrow: 'Flagship programmes', title: 'Featured courses', onMore: () => goTo(1)),
            if (featured.isEmpty) const EmptyView(title: 'Courses coming soon'),
            SizedBox(
              height: 270,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, k) => SizedBox(width: 240, child: CourseCard(c: featured[k])),
              ),
            ),
            SectionHeader(eyebrow: 'Practice', title: 'Test yourself', onMore: () => goTo(2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: const CircleAvatar(backgroundColor: AppColors.forestSoft, child: Icon(Icons.timer_outlined, color: AppColors.forest)),
                  title: const Text('Timed tests with solutions', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Start with a free chapter test'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => goTo(2),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const NotificationsScreen({super.key, required this.items});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Updates')),
        body: items.isEmpty
            ? const EmptyView(title: 'No updates yet', icon: Icons.notifications_none)
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, k) {
                  final n = items[k];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n['title'], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
                        if (n['body'] != null) ...[const SizedBox(height: 4), Text(n['body'], style: const TextStyle(color: AppColors.inkSoft))],
                        const SizedBox(height: 6),
                        Text(DateTime.parse(n['created_at']).toLocal().toString().substring(0, 16),
                            style: const TextStyle(fontSize: 11, color: AppColors.inkMute)),
                      ]),
                    ),
                  );
                },
              ),
      );
}
