import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/buy_button.dart';
import '../../widgets/common.dart';

class CourseDetailScreen extends StatefulWidget {
  final Json course;
  const CourseDetailScreen({super.key, required this.course});
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<_CourseData> _f = _load();
  Json get c => widget.course;

  Future<_CourseData> _load() async {
    final r = await Future.wait([
      Api.sections(c['id']),
      Api.lessons(c['id']),
      Api.owns('course', c['id']),
      Api.hasAccess('course', c['id']),
      Api.completedLessons(),
    ]);
    final owns = r[2] as bool, access = r[3] as bool;
    return _CourseData(r[0] as List<Json>, r[1] as List<Json>, owns || (access && c['is_free'] != true), r[4] as Set<String>);
  }

  void _refresh() => setState(() => _f = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_CourseData>(
        future: _f,
        builder: (context, s) {
          if (!s.hasData) return const Loading();
          final d = s.data!;
          final done = d.lessons.where((l) => d.completed.contains(l['id'])).length;
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.ivory,
              flexibleSpace: FlexibleSpaceBar(background: Cover(url: c['thumbnail_url'], title: '')),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Eyebrow('Course'),
                  const SizedBox(height: 6),
                  Text(c['title'], style: Theme.of(context).textTheme.headlineMedium),
                  if (c['subtitle'] != null) ...[const SizedBox(height: 6), Text(c['subtitle'], style: const TextStyle(color: AppColors.inkSoft, fontSize: 15))],
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Pill('${d.lessons.length} lessons'),
                    Pill(c['validity_days'] == null ? 'Lifetime access' : '${c['validity_days']} days access'),
                    if (c['language'] != null) Pill(c['language']),
                  ]),
                  const SizedBox(height: 18),
                  if (d.unlocked) ...[
                    LinearProgressIndicator(
                      value: d.lessons.isEmpty ? 0 : done / d.lessons.length,
                      color: AppColors.brass,
                      backgroundColor: AppColors.ivoryDark,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 6),
                    Text('$done of ${d.lessons.length} completed', style: const TextStyle(fontSize: 12, color: AppColors.inkMute)),
                  ] else ...[
                    PriceTag(price: c['price'], mrp: c['mrp'], free: c['is_free'] == true),
                    const SizedBox(height: 12),
                    BuyButton(itemType: 'course', itemId: c['id'], title: c['title'], price: c['price'], free: c['is_free'] == true, onUnlocked: _refresh),
                  ],
                  if ((c['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('About this course', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(c['description'], style: const TextStyle(color: AppColors.inkSoft, height: 1.5)),
                  ],
                  const SizedBox(height: 24),
                  Text('Curriculum', style: Theme.of(context).textTheme.titleLarge),
                ]),
              ),
            ),
            ...d.groups().map((g) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        Container(
                          width: double.infinity,
                          color: AppColors.ivory,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(g.key, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
                        ),
                        ...g.value.map((l) {
                          final can = d.unlocked || l['is_preview'] == true;
                          final isDone = d.completed.contains(l['id']);
                          return ListTile(
                            enabled: can,
                            leading: Icon(
                              isDone ? Icons.check_circle : (!can ? Icons.lock_outline : (l['kind'] == 'pdf' ? Icons.description_outlined : Icons.play_circle_outline)),
                              color: isDone ? AppColors.brass : AppColors.forest,
                            ),
                            title: Text(l['title'], style: const TextStyle(fontSize: 14)),
                            subtitle: l['duration_minutes'] != null ? Text('${l['duration_minutes']} min') : null,
                            trailing: (l['is_preview'] == true && !d.unlocked) ? const Pill('Preview', bg: Color(0x33B8893B), fg: AppColors.brass) : null,
                            onTap: !can
                                ? null
                                : () async {
                                    await Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => PlayerScreen(lessons: d.lessons.where((x) => d.unlocked || x['is_preview'] == true).toList(), startId: l['id'], canTrack: d.unlocked)));
                                    _refresh();
                                  },
                          );
                        }),
                      ]),
                    ),
                  ),
                )),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]);
        },
      ),
    );
  }
}

class _CourseData {
  final List<Json> sections, lessons;
  final bool unlocked;
  final Set<String> completed;
  _CourseData(this.sections, this.lessons, this.unlocked, this.completed);

  List<MapEntry<String, List<Json>>> groups() {
    final out = <MapEntry<String, List<Json>>>[];
    for (final s in sections) {
      final items = lessons.where((l) => l['section_id'] == s['id']).toList();
      if (items.isNotEmpty) out.add(MapEntry(s['title'], items));
    }
    final ids = sections.map((s) => s['id']).toSet();
    final rest = lessons.where((l) => l['section_id'] == null || !ids.contains(l['section_id'])).toList();
    if (rest.isNotEmpty) out.add(MapEntry(sections.isEmpty ? 'Lessons' : 'More lessons', rest));
    return out;
  }
}

/// Turns YouTube / Vimeo share links into embeddable player URLs. Returns null for direct video files.
String? embedUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return null;
  if (u.host.contains('youtu.be')) return 'https://www.youtube-nocookie.com/embed/${u.pathSegments.first}?rel=0&modestbranding=1&playsinline=1';
  if (u.host.contains('youtube.com')) {
    final id = u.queryParameters['v'] ?? u.pathSegments.last;
    return 'https://www.youtube-nocookie.com/embed/$id?rel=0&modestbranding=1&playsinline=1';
  }
  if (u.host.contains('vimeo.com') && !u.host.startsWith('player.')) return 'https://player.vimeo.com/video/${u.pathSegments.first}';
  if (u.host.startsWith('player.') || u.host.contains('mediadelivery.net') || u.path.contains('/embed')) return url;
  return null;
}

class PlayerScreen extends StatefulWidget {
  final List<Json> lessons;
  final String startId;
  final bool canTrack;
  const PlayerScreen({super.key, required this.lessons, required this.startId, required this.canTrack});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late String current = widget.startId;
  VideoPlayerController? _video;
  ChewieController? _chewie;
  WebViewController? _web;
  String? _pdf;
  String? _error;
  bool _loading = true;
  Set<String> _done = {};

  Json get lesson => widget.lessons.firstWhere((l) => l['id'] == current);

  @override
  void initState() {
    super.initState();
    Api.completedLessons().then((v) => mounted ? setState(() => _done = v) : null);
    _open();
  }

  Future<void> _disposePlayers() async {
    _chewie?.dispose();
    await _video?.dispose();
    _chewie = null;
    _video = null;
    _web = null;
  }

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
      _pdf = null;
    });
    await _disposePlayers();
    try {
      final m = await Api.lessonMedia(current);
      if (m == null) throw Exception('This lesson is locked.');
      if (m['pdf_path'] != null) _pdf = await Api.signedUrl(m['pdf_path'], seconds: 3600);
      String? src;
      if (m['video_path'] != null) {
        src = await Api.signedUrl(m['video_path']);
      } else if (m['video_url'] != null) {
        final e = embedUrl(m['video_url']);
        if (e != null) {
          _web = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.black)
            ..loadHtmlString('<html><body style="margin:0;background:#000"><iframe src="$e" style="border:0;width:100%;height:100%" allow="autoplay; encrypted-media; fullscreen" allowfullscreen></iframe></body></html>');
        } else {
          src = m['video_url'];
        }
      }
      if (src != null) {
        _video = VideoPlayerController.networkUrl(Uri.parse(src));
        await _video!.initialize();
        _chewie = ChewieController(
          videoPlayerController: _video!,
          autoPlay: true,
          allowedScreenSleep: false,
          playbackSpeeds: const [0.75, 1, 1.25, 1.5, 2],
          materialProgressColors: ChewieProgressColors(playedColor: AppColors.brass, handleColor: AppColors.brassLight),
        );
      }
    } catch (e) {
      _error = '$e'.replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  Future<void> _toggleDone() async {
    final d = !_done.contains(current);
    await Api.setCompleted(current, d);
    setState(() => d ? _done.add(current) : _done.remove(current));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      appBar: AppBar(backgroundColor: AppColors.forestDeep, foregroundColor: AppColors.ivory, title: Text(lesson['title'], maxLines: 1)),
      body: Column(children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: _loading
                ? const Loading()
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.ivory)))
                    : _chewie != null
                        ? Chewie(controller: _chewie!)
                        : _web != null
                            ? WebViewWidget(controller: _web!)
                            : const Center(child: Text('Notes-only lesson — open the PDF below.', style: TextStyle(color: AppColors.ivory))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (_pdf != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.ivory, side: const BorderSide(color: Colors.white24)),
                  onPressed: () => launchUrl(Uri.parse(_pdf!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Notes PDF'),
                ),
              ),
            if (_pdf != null && widget.canTrack) const SizedBox(width: 10),
            if (widget.canTrack)
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.brass, foregroundColor: AppColors.forestDeep),
                  onPressed: _toggleDone,
                  icon: Icon(_done.contains(current) ? Icons.check_circle : Icons.check, size: 18),
                  label: Text(_done.contains(current) ? 'Completed' : 'Mark complete'),
                ),
              ),
          ]),
        ),
        Expanded(
          child: ListView(
            children: widget.lessons.map((l) {
              final on = l['id'] == current;
              return ListTile(
                tileColor: on ? Colors.white10 : null,
                leading: Icon(_done.contains(l['id']) ? Icons.check_circle : Icons.play_circle_outline,
                    color: on || _done.contains(l['id']) ? AppColors.brassLight : Colors.white38),
                title: Text(l['title'], style: TextStyle(color: on ? AppColors.ivory : Colors.white70, fontSize: 14)),
                subtitle: l['duration_minutes'] != null ? Text('${l['duration_minutes']} min', style: const TextStyle(color: Colors.white38)) : null,
                onTap: on
                    ? null
                    : () {
                        setState(() => current = l['id']);
                        _open();
                      },
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}
