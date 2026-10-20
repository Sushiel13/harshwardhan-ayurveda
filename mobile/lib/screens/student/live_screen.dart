import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  Future<List<Json>> _load() async {
    final rows = await Api.liveClasses();
    for (final l in rows) {
      var can = l['is_free'] == true || l['course_id'] == null;
      if (!can) can = await Api.hasAccess('course', l['course_id']);
      l['_can'] = can;
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Live classes')),
        body: AsyncView<List<Json>>(
          load: _load,
          builder: (_, list, __) => list.isEmpty
              ? ListView(children: const [EmptyView(title: 'No upcoming live classes', icon: Icons.videocam_outlined)])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final l = list[i];
                    final start = DateTime.parse(l['starts_at']).toLocal();
                    final dur = Duration(minutes: (l['duration_minutes'] ?? 60) as int);
                    final now = DateTime.now();
                    final live = now.isAfter(start.subtract(const Duration(minutes: 10))) && now.isBefore(start.add(dur));
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 62,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(12)),
                            child: Column(children: [
                              Text(DateFormat('MMM').format(start).toUpperCase(), style: const TextStyle(color: AppColors.brassLight, fontSize: 11, fontWeight: FontWeight.w700)),
                              Text('${start.day}', style: const TextStyle(color: AppColors.ivory, fontSize: 24, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (live) const Pill('● LIVE', bg: Color(0xFFD32F2F), fg: Colors.white),
                              Text(l['title'], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest, fontSize: 15)),
                              Text('${DateFormat('EEE, h:mm a').format(start)} · ${dur.inMinutes} min', style: const TextStyle(color: AppColors.inkMute, fontSize: 12)),
                              const SizedBox(height: 10),
                              if (l['_can'] == true && l['meeting_url'] != null)
                                FilledButton.icon(
                                  style: live ? FilledButton.styleFrom(backgroundColor: AppColors.brass, foregroundColor: AppColors.forestDeep, minimumSize: const Size(0, 40)) : FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                  onPressed: () => launchUrl(Uri.parse(l['meeting_url']), mode: LaunchMode.externalApplication),
                                  icon: const Icon(Icons.videocam_rounded, size: 18),
                                  label: Text(live ? 'Join now' : 'Class link'),
                                )
                              else
                                const Text('For enrolled students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkMute)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      );
}
