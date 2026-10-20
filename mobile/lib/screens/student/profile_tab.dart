import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'course_screens.dart';
import 'test_screens.dart';
import 'ebook_screen.dart';
import 'live_screen.dart';
import 'home_tab.dart';

class ProfileTab extends StatelessWidget {
  final VoidCallback? onAdminView;
  const ProfileTab({super.key, this.onAdminView});

  Future<Map<String, dynamic>> _load() async {
    final purchases = await Api.myPurchases();
    List<String> ids(String t) => purchases.where((p) => p['item_type'] == t).map((p) => p['item_id'] as String).toList();
    final r = await Future.wait([
      Api.myProfile(),
      Api.byIds('courses', ids('course')),
      Api.byIds('test_series', ids('test_series')),
      Api.byIds('ebooks', ids('ebook')),
      Api.myAttempts(),
      Api.db.from('settings').select('value').eq('key', 'site').maybeSingle(),
    ]);
    return {'profile': r[0], 'courses': r[1], 'series': r[2], 'ebooks': r[3], 'attempts': r[4], 'site': (r[5] as Map?)?['value'] ?? {}};
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My learning')),
        body: AsyncView<Map<String, dynamic>>(
          load: _load,
          builder: (context, d, _) {
            final p = (d['profile'] as Map?) ?? {};
            final courses = (d['courses'] as List).cast<Json>();
            final series = (d['series'] as List).cast<Json>();
            final ebooks = (d['ebooks'] as List).cast<Json>();
            final attempts = (d['attempts'] as List).cast<Json>();
            final site = Map<String, dynamic>.from(d['site'] as Map);
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.forest,
                    child: Text(((p['full_name'] ?? 'S') as String).isNotEmpty ? (p['full_name'] as String)[0].toUpperCase() : 'S',
                        style: const TextStyle(color: AppColors.brassLight, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  title: Text(p['full_name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${p['email'] ?? ''}\n${p['phone'] ?? ''}'),
                  isThreeLine: true,
                ),
              ),
              if (onAdminView != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.brass, foregroundColor: AppColors.forestDeep),
                  onPressed: onAdminView,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Back to admin panel'),
                ),
              ],
              _section(context, 'My courses', courses, (c) => CourseDetailScreen(course: c)),
              _section(context, 'My test series', series, (s) => SeriesScreen(series: s)),
              _section(context, 'My eBooks', ebooks, (e) => EbookScreen(ebook: e)),
              if (attempts.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Recent scores', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: attempts
                        .map((a) => ListTile(
                              dense: true,
                              title: Text((a['tests'] as Map?)?['title'] ?? 'Test'),
                              trailing: Text('${a['score']} / ${a['total']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ))
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Card(
                child: Column(children: [
                  _tile(Icons.videocam_outlined, 'Live classes', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveScreen()))),
                  _tile(Icons.notifications_none, 'Updates', () async {
                    final n = await Api.notifications();
                    if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(items: n)));
                  }),
                  if ((site['whatsapp'] ?? '').toString().isNotEmpty)
                    _tile(Icons.chat_outlined, 'Chat with us on WhatsApp',
                        () => launchUrl(Uri.parse('https://wa.me/${site['whatsapp']}'), mode: LaunchMode.externalApplication)),
                  if ((site['phone'] ?? '').toString().isNotEmpty)
                    _tile(Icons.call_outlined, 'Call ${site['phone']}', () => launchUrl(Uri.parse('tel:${site['phone']}'))),
                  _tile(Icons.logout, 'Sign out', () => Api.auth.signOut()),
                ]),
              ),
            ]);
          },
        ),
      );

  Widget _tile(IconData i, String t, VoidCallback onTap) =>
      ListTile(leading: Icon(i, color: AppColors.forest), title: Text(t), trailing: const Icon(Icons.chevron_right), onTap: onTap);

  Widget _section(BuildContext context, String title, List<Json> items, Widget Function(Json) page) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Nothing here yet.', style: TextStyle(color: AppColors.inkMute))
          else
            ...items.map((x) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text(x['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page(x))),
                    ),
                  ),
                )),
        ]),
      );
}
