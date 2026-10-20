import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

// ---------------- Students ----------------
class AdminStudents extends StatefulWidget {
  const AdminStudents({super.key});
  @override
  State<AdminStudents> createState() => _AdminStudentsState();
}

class _AdminStudentsState extends State<AdminStudents> {
  final q = TextEditingController();
  int _v = 0;

  Future<List<Json>> _load() {
    var query = Api.db.from('profiles').select();
    final s = q.text.trim().replaceAll(',', ' ');
    if (s.isNotEmpty) query = query.or('full_name.ilike.%$s%,email.ilike.%$s%,phone.ilike.%$s%');
    return query.order('created_at', ascending: false).limit(200);
  }

  Future<void> _toggle(Json p, String field) async {
    final v = field == 'role' ? (p['role'] == 'admin' ? 'student' : 'admin') : !(p['is_blocked'] == true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(field == 'role' ? 'Make ${p['full_name'] ?? p['email']} $v?' : '${v == true ? 'Block' : 'Unblock'} ${p['full_name'] ?? p['email']}?'),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Confirm'))],
      ),
    );
    if (ok != true) return;
    try {
      await Api.db.from('profiles').update({field: v}).eq('id', p['id']);
      setState(() => _v++);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Students')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: q,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, email or phone'),
              onSubmitted: (_) => setState(() => _v++),
            ),
          ),
          Expanded(
            child: AsyncView<List<Json>>(
              key: ValueKey(_v),
              load: _load,
              builder: (_, rows, __) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = rows[i];
                  return Card(
                    child: ListTile(
                      title: Row(children: [
                        Flexible(child: Text(p['full_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w700))),
                        if (p['role'] == 'admin') const Padding(padding: EdgeInsets.only(left: 6), child: Pill('admin')),
                        if (p['is_blocked'] == true) const Padding(padding: EdgeInsets.only(left: 6), child: Pill('blocked', bg: Color(0xFFFDECEC), fg: Color(0xFFB71C1C))),
                      ]),
                      subtitle: Text('${p['email'] ?? ''}\n${p['phone'] ?? ''}'),
                      isThreeLine: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrantAccess(profile: p))),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => v == 'grant'
                            ? Navigator.push(context, MaterialPageRoute(builder: (_) => GrantAccess(profile: p)))
                            : _toggle(p, v),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'grant', child: Text('Manage access')),
                          PopupMenuItem(value: 'role', child: Text(p['role'] == 'admin' ? 'Remove admin' : 'Make admin')),
                          PopupMenuItem(value: 'is_blocked', child: Text(p['is_blocked'] == true ? 'Unblock' : 'Block')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      );
}

class GrantAccess extends StatefulWidget {
  final Json profile;
  const GrantAccess({super.key, required this.profile});
  @override
  State<GrantAccess> createState() => _GrantAccessState();
}

class _GrantAccessState extends State<GrantAccess> {
  int _v = 0;
  String? pick;

  Future<List<dynamic>> _load() => Future.wait([
        Api.db.from('courses').select('id,title'),
        Api.db.from('ebooks').select('id,title'),
        Api.db.from('test_series').select('id,title'),
        Api.db.from('purchases').select().eq('user_id', widget.profile['id']),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.profile['full_name'] ?? widget.profile['email'] ?? 'Student')),
        body: AsyncView<List<dynamic>>(
          key: ValueKey(_v),
          load: _load,
          builder: (_, d, __) {
            final items = <(String, String, String)>[
              ...(d[0] as List).map((x) => ('course', x['id'] as String, x['title'] as String)),
              ...(d[1] as List).map((x) => ('ebook', x['id'] as String, x['title'] as String)),
              ...(d[2] as List).map((x) => ('test_series', x['id'] as String, x['title'] as String)),
            ];
            final owned = (d[3] as List).cast<Json>();
            String name(Json o) => items.firstWhere((i) => i.$2 == o['item_id'], orElse: () => ('', '', o['item_id'])).$3;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('Current access', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (owned.isEmpty) const Text('None', style: TextStyle(color: AppColors.inkMute)),
              ...owned.map((o) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(name(o)),
                      subtitle: Text('${o['item_type']} · ${o['source']}${o['expires_at'] != null ? ' · till ${o['expires_at'].toString().substring(0, 10)}' : ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.clay),
                        onPressed: () async {
                          await Api.db.from('purchases').delete().eq('id', o['id']);
                          setState(() => _v++);
                        },
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              Text('Give free access', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: pick,
                isExpanded: true,
                hint: const Text('Choose course / eBook / test series'),
                items: items.map((i) => DropdownMenuItem(value: '${i.$1}|${i.$2}', child: Text('${i.$1.replaceAll('_', ' ')} — ${i.$3}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => pick = v),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: pick == null
                    ? null
                    : () async {
                        final parts = pick!.split('|');
                        await Api.db.from('purchases').upsert(
                          {'user_id': widget.profile['id'], 'item_type': parts[0], 'item_id': parts[1], 'amount': 0, 'source': 'admin'},
                          onConflict: 'user_id,item_type,item_id',
                        );
                        setState(() {
                          pick = null;
                          _v++;
                        });
                        if (context.mounted) toast(context, 'Access granted');
                      },
                child: const Text('Grant access'),
              ),
            ]);
          },
        ),
      );
}

// ---------------- Payments ----------------
class AdminPayments extends StatefulWidget {
  const AdminPayments({super.key});
  @override
  State<AdminPayments> createState() => _AdminPaymentsState();
}

class _AdminPaymentsState extends State<AdminPayments> {
  String status = 'paid';
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Payments')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'paid', label: Text('Paid')), ButtonSegment(value: 'created', label: Text('Started')), ButtonSegment(value: 'failed', label: Text('Failed'))],
              selected: {status},
              onSelectionChanged: (s) => setState(() => status = s.first),
            ),
          ),
          Expanded(
            child: AsyncView<List<Json>>(
              key: ValueKey(status),
              load: () => Api.db.from('payments').select('*, profiles(full_name,email)').eq('status', status).order('created_at', ascending: false).limit(300),
              builder: (_, rows, __) {
                final total = rows.fold<num>(0, (a, r) => a + asNum(r['amount']));
                return ListView(padding: const EdgeInsets.all(16), children: [
                  Text('${rows.length} records · ${inr(total)}', style: const TextStyle(color: AppColors.inkMute)),
                  const SizedBox(height: 8),
                  ...rows.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text((r['profiles'] as Map?)?['full_name'] ?? (r['profiles'] as Map?)?['email'] ?? 'Student'),
                          subtitle: Text('${r['item_type']} · ${DateTime.parse(r['created_at']).toLocal().toString().substring(0, 16)}'
                              '${r['coupon_code'] != null ? ' · ${r['coupon_code']}' : ''}\n${r['razorpay_payment_id'] ?? ''}'),
                          isThreeLine: true,
                          trailing: Text(inr(asNum(r['amount'])), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.forest)),
                        ),
                      )),
                ]);
              },
            ),
          ),
        ]),
      );
}

// ---------------- Inquiries ----------------
class AdminInquiries extends StatelessWidget {
  const AdminInquiries({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Inquiries')),
        body: AsyncView<List<Json>>(
          load: () => Api.db.from('inquiries').select().order('created_at', ascending: false),
          builder: (_, rows, __) => rows.isEmpty
              ? ListView(children: const [EmptyView(title: 'No inquiries yet', icon: Icons.mail_outline)])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final phone = '${r['phone'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['name'], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
                          Text('${r['email'] ?? ''} · ${r['phone'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.inkMute)),
                          const SizedBox(height: 8),
                          Text(r['message']),
                          if (phone.isNotEmpty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => launchUrl(Uri.parse('https://wa.me/$phone'), mode: LaunchMode.externalApplication),
                                icon: const Icon(Icons.chat_outlined, size: 18),
                                label: const Text('WhatsApp'),
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
