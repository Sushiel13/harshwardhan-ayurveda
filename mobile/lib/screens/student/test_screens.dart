import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/buy_button.dart';
import '../../widgets/common.dart';

class SeriesScreen extends StatefulWidget {
  final Json series;
  const SeriesScreen({super.key, required this.series});
  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  Json get s => widget.series;
  late Future<List<dynamic>> _f = _load();
  Future<List<dynamic>> _load() => Future.wait([Api.tests(s['id']), Api.owns('test_series', s['id']), Api.hasAccess('test_series', s['id'])]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Test series')),
        body: FutureBuilder<List<dynamic>>(
          future: _f,
          builder: (_, snap) {
            if (!snap.hasData) return const Loading();
            final tests = (snap.data![0] as List).cast<Json>();
            final unlocked = (snap.data![1] as bool) || ((snap.data![2] as bool) && s['is_free'] != true);
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text(s['title'], style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(s['description'] ?? '', style: const TextStyle(color: AppColors.inkSoft, height: 1.5)),
              const SizedBox(height: 18),
              if (!unlocked) ...[
                PriceTag(price: s['price'], mrp: s['mrp'], free: s['is_free'] == true),
                const SizedBox(height: 12),
                BuyButton(itemType: 'test_series', itemId: s['id'], title: s['title'], price: s['price'], free: s['is_free'] == true,
                    onUnlocked: () => setState(() => _f = _load())),
                const SizedBox(height: 20),
              ],
              ...tests.asMap().entries.map((e) {
                final t = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(backgroundColor: const Color(0x26B8893B), child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.brass, fontWeight: FontWeight.w700))),
                      title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${t['duration_minutes']} min · +${t['marks_per_question']}'
                          '${asNum(t['negative_marks']) > 0 ? ' / −${t['negative_marks']}' : ''}'),
                      trailing: unlocked ? const Icon(Icons.play_arrow_rounded, color: AppColors.forest) : const Icon(Icons.lock_outline),
                      onTap: unlocked ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => TakeTestScreen(test: t))) : null,
                    ),
                  ),
                );
              }),
              if (tests.isEmpty) const EmptyView(title: 'Tests will be added soon'),
            ]);
          },
        ),
      );
}

class TakeTestScreen extends StatefulWidget {
  final Json test;
  const TakeTestScreen({super.key, required this.test});
  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  List<Json> qs = [];
  final Map<String, int> ans = {};
  int i = 0, left = 0;
  bool started = false, busy = false, loading = true;
  String? error;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    left = (widget.test['duration_minutes'] as int) * 60;
    Api.testQuestions(widget.test['id']).then((v) => setState(() {
          qs = v;
          loading = false;
        })).catchError((e) => setState(() {
          error = '$e';
          loading = false;
        }));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void start() {
    setState(() => started = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (left <= 1) {
        timer?.cancel();
        submit();
      } else {
        setState(() => left--);
      }
    });
  }

  Future<void> submit() async {
    if (busy) return;
    timer?.cancel();
    setState(() => busy = true);
    try {
      final r = await Api.submitTest(widget.test['id'], ans);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(title: widget.test['title'], r: r)));
    } catch (e) {
      setState(() => busy = false);
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.test;
    if (loading) return const Scaffold(body: Loading());
    if (error != null) return Scaffold(appBar: AppBar(), body: EmptyView(title: 'Could not open test', text: error));
    if (!started) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Ready?'),
            const SizedBox(height: 6),
            Text(t['title'], style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            Text('• ${qs.length} questions · ${t['duration_minutes']} minutes'),
            Text('• +${t['marks_per_question']} per correct answer${asNum(t['negative_marks']) > 0 ? ', −${t['negative_marks']} per wrong answer' : ''}'),
            const Text('• Auto-submits when time runs out'),
            if (t['instructions'] != null) ...[const SizedBox(height: 12), Text(t['instructions'])],
            const Spacer(),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: qs.isEmpty ? null : start, child: const Text('Begin test'))),
          ]),
        ),
      );
    }
    final q = qs[i];
    final opts = (q['options'] as List).cast<dynamic>();
    final mm = (left ~/ 60).toString().padLeft(2, '0'), ss = (left % 60).toString().padLeft(2, '0');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text('Submit and exit?'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep going')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Submit'))],
                ));
        if (ok == true) submit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Q ${i + 1} / ${qs.length}'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: left < 60 ? const Color(0xFFFDECEC) : AppColors.forestSoft, borderRadius: BorderRadius.circular(20)),
              child: Text('$mm:$ss', style: TextStyle(fontWeight: FontWeight.w800, color: left < 60 ? Colors.red.shade800 : AppColors.forest, fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ],
        ),
        body: Column(children: [
          LinearProgressIndicator(value: ans.length / qs.length, color: AppColors.brass, backgroundColor: AppColors.ivoryDark),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Text(q['question'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.45, color: AppColors.forest)),
              const SizedBox(height: 20),
              ...opts.asMap().entries.map((e) {
                final sel = ans[q['id']] == e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => ans[q['id']] = e.key),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.forestSoft : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? AppColors.forest : AppColors.forest.withOpacity(.12), width: sel ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: sel ? AppColors.forest : AppColors.ivoryDark,
                          child: Text(String.fromCharCode(65 + e.key), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: sel ? AppColors.ivory : AppColors.inkSoft)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('${e.value}', style: const TextStyle(fontSize: 15))),
                      ]),
                    ),
                  ),
                );
              }),
            ]),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: OutlinedButton(onPressed: i == 0 ? null : () => setState(() => i--), child: const Text('Previous'))),
                const SizedBox(width: 10),
                Expanded(
                  child: i < qs.length - 1
                      ? FilledButton(onPressed: () => setState(() => i++), child: const Text('Next'))
                      : FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.brass, foregroundColor: AppColors.forestDeep),
                          onPressed: busy ? null : submit,
                          child: Text(busy ? 'Submitting…' : 'Submit'),
                        ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String title;
  final Json r;
  const ResultScreen({super.key, required this.title, required this.r});
  @override
  Widget build(BuildContext context) {
    final review = (r['review'] as List).cast<Map>();
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppColors.brassLight, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text('${r['score']} / ${r['total']}', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.ivory, fontSize: 44)),
            const SizedBox(height: 12),
            Row(children: [
              _stat('Correct', r['correct'], AppColors.brassLight),
              _stat('Wrong', r['wrong'], const Color(0xFFF2A3A3)),
              _stat('Skipped', r['unanswered'], Colors.white60),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Solutions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        ...review.asMap().entries.map((e) {
          final q = e.value;
          final opts = (q['options'] as List);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Q${e.key + 1}. ${q['question']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.forest)),
                  const SizedBox(height: 8),
                  ...opts.asMap().entries.map((o) {
                    final right = o.key == q['correct'], picked = o.key == q['selected'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Icon(right ? Icons.check_circle : (picked ? Icons.cancel : Icons.circle_outlined),
                            size: 17, color: right ? AppColors.forest : (picked ? Colors.red.shade700 : AppColors.inkMute)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${o.value}', style: TextStyle(fontWeight: right ? FontWeight.w700 : FontWeight.w400))),
                      ]),
                    );
                  }),
                  if (q['explanation'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(10)),
                      child: Text('${q['explanation']}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                    ),
                  ],
                ]),
              ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _stat(String l, dynamic v, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$v', style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(l, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      );
}
