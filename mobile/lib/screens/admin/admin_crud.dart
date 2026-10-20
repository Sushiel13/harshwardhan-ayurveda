import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

enum F { text, multiline, number, toggle, select, datetime, image, publicFile, privateFile }

class FieldSpec {
  final String name, label;
  final F type;
  final bool required;
  final String? help;
  final dynamic initial;
  final List<MapEntry<String, String>> options; // value → label
  final String Function(Json row)? folder;
  final FileType fileType;
  const FieldSpec(this.name, this.label, this.type,
      {this.required = false, this.help, this.initial, this.options = const [], this.folder, this.fileType = FileType.any});
}

/// Generic list + add/edit/delete screen for one table.
class AdminCrudScreen extends StatefulWidget {
  final String table, title;
  final List<FieldSpec> Function() fields;
  final String Function(Json) titleOf;
  final String Function(Json)? subtitleOf;
  final String orderBy;
  final bool ascending;
  final Map<String, dynamic>? filter;
  final Json Function(Json)? beforeSave;
  final void Function(BuildContext, Json)? onOpen;
  final String? banner;
  const AdminCrudScreen({
    super.key,
    required this.table,
    required this.title,
    required this.fields,
    required this.titleOf,
    this.subtitleOf,
    this.orderBy = 'created_at',
    this.ascending = false,
    this.filter,
    this.beforeSave,
    this.onOpen,
    this.banner,
  });
  @override
  State<AdminCrudScreen> createState() => _AdminCrudScreenState();
}

class _AdminCrudScreenState extends State<AdminCrudScreen> {
  int _v = 0;

  Future<List<Json>> _load() async {
    var q = Api.db.from(widget.table).select();
    widget.filter?.forEach((k, v) => q = q.eq(k, v));
    return await q.order(widget.orderBy, ascending: widget.ascending);
  }

  Future<void> _edit([Json? row]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminForm(table: widget.table, title: widget.title, fields: widget.fields(), row: row, filter: widget.filter, beforeSave: widget.beforeSave)),
    );
    if (saved == true) setState(() => _v++);
  }

  Future<void> _delete(Json row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(widget.titleOf(row)),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
      ),
    );
    if (ok != true) return;
    try {
      await Api.db.from(widget.table).delete().eq('id', row['id']);
      setState(() => _v++);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.ivory,
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
        body: AsyncView<List<Json>>(
          key: ValueKey(_v),
          load: _load,
          builder: (_, rows, __) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
            if (widget.banner != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x1FB8893B), borderRadius: BorderRadius.circular(12)),
                child: Text(widget.banner!, style: const TextStyle(fontSize: 13)),
              ),
            if (rows.isEmpty) const EmptyView(title: 'Nothing yet', text: 'Tap “Add” to create the first one.'),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text(widget.titleOf(r), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: widget.subtitleOf != null ? Text(widget.subtitleOf!(r)) : null,
                      onTap: widget.onOpen != null ? () => widget.onOpen!(context, r) : () => _edit(r),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => v == 'edit' ? _edit(r) : _delete(r),
                        itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                      ),
                    ),
                  ),
                )),
          ]),
        ),
      );
}

class AdminForm extends StatefulWidget {
  final String table, title;
  final List<FieldSpec> fields;
  final Json? row;
  final Map<String, dynamic>? filter;
  final Json Function(Json)? beforeSave;
  const AdminForm({super.key, required this.table, required this.title, required this.fields, this.row, this.filter, this.beforeSave});
  @override
  State<AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends State<AdminForm> {
  late final bool isNew = widget.row == null;
  late final Json data;
  final Map<String, TextEditingController> ctl = {};
  final Set<String> uploading = {};
  bool saving = false;

  @override
  void initState() {
    super.initState();
    data = Map<String, dynamic>.from(widget.row ?? {...?widget.filter});
    if (isNew) {
      data['id'] = _uuid();
      for (final f in widget.fields) {
        data[f.name] ??= f.initial ?? (f.type == F.toggle ? false : null);
      }
    }
    for (final f in widget.fields) {
      if ([F.text, F.multiline, F.number].contains(f.type)) {
        ctl[f.name] = TextEditingController(text: data[f.name] == null ? '' : '${data[f.name]}');
      }
    }
  }

  @override
  void dispose() {
    for (final c in ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // RFC4122 v4 UUID from a secure random source (no extra package needed)
  static final _rng = Random.secure();
  String _uuid() {
    final r = List<int>.generate(16, (_) => _rng.nextInt(256));
    r[6] = (r[6] & 0x0f) | 0x40;
    r[8] = (r[8] & 0x3f) | 0x80;
    final h = r.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> _pick(FieldSpec f) async {
    final res = await FilePicker.platform.pickFiles(type: f.type == F.image ? FileType.image : f.fileType);
    final path = res?.files.single.path;
    if (path == null) return;
    setState(() => uploading.add(f.name));
    try {
      final bucket = f.type == F.privateFile ? 'content' : 'media';
      final folder = f.folder?.call(data) ?? (f.type == F.image ? 'images' : 'files');
      final stored = await Api.upload(bucket, folder, File(path));
      data[f.name] = f.type == F.image ? Api.publicUrl(stored) : stored;
    } catch (e) {
      if (mounted) toast(context, 'Upload failed: $e');
    }
    if (mounted) setState(() => uploading.remove(f.name));
  }

  Future<void> _save() async {
    for (final f in widget.fields) {
      final c = ctl[f.name];
      if (c != null) {
        final t = c.text.trim();
        data[f.name] = f.type == F.number ? (t.isEmpty ? null : num.tryParse(t)) : (t.isEmpty ? null : t);
      }
      if (f.required && (data[f.name] == null || '${data[f.name]}'.isEmpty)) {
        toast(context, '${f.label} is required');
        return;
      }
    }
    setState(() => saving = true);
    try {
      var row = Map<String, dynamic>.from(data)..remove('created_at');
      if (widget.beforeSave != null) row = widget.beforeSave!(row);
      if (isNew) {
        await Api.db.from(widget.table).insert(row);
      } else {
        final id = row.remove('id');
        await Api.db.from(widget.table).update(row).eq('id', id);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) toast(context, '$e');
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${isNew ? 'Add' : 'Edit'} · ${widget.title}')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ...widget.fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _field(f))),
          FilledButton(onPressed: saving || uploading.isNotEmpty ? null : _save, child: Text(saving ? 'Saving…' : 'Save')),
          const SizedBox(height: 40),
        ]),
      );

  Widget _field(FieldSpec f) {
    final help = f.help == null ? null : Text(f.help!, style: const TextStyle(fontSize: 12, color: AppColors.inkMute));
    switch (f.type) {
      case F.text:
      case F.multiline:
      case F.number:
        return TextField(
          controller: ctl[f.name],
          maxLines: f.type == F.multiline ? 5 : 1,
          keyboardType: f.type == F.number ? const TextInputType.numberWithOptions(decimal: true) : null,
          decoration: InputDecoration(labelText: f.label + (f.required ? ' *' : ''), helperText: f.help, helperMaxLines: 3),
        );
      case F.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.forest,
          title: Text(f.label),
          subtitle: help,
          value: data[f.name] == true,
          onChanged: (v) => setState(() => data[f.name] = v),
        );
      case F.select:
        return DropdownButtonFormField<String>(
          value: f.options.any((o) => o.key == data[f.name]) ? data[f.name] as String : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: f.label, helperText: f.help, helperMaxLines: 3),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('—')),
            ...f.options.map((o) => DropdownMenuItem(value: o.key, child: Text(o.value, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setState(() => data[f.name] = v),
        );
      case F.datetime:
        final cur = data[f.name] == null ? null : DateTime.parse(data[f.name]).toLocal();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label + (f.required ? ' *' : '')),
          subtitle: Text(cur == null ? 'Not set' : cur.toString().substring(0, 16)),
          trailing: const Icon(Icons.event),
          onTap: () async {
            final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: cur ?? DateTime.now());
            if (d == null || !mounted) return;
            final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(cur ?? DateTime.now()));
            if (t == null) return;
            setState(() => data[f.name] = DateTime(d.year, d.month, d.day, t.hour, t.minute).toUtc().toIso8601String());
          },
        );
      case F.image:
      case F.publicFile:
      case F.privateFile:
        final v = data[f.name] as String?;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (help != null) help,
          const SizedBox(height: 8),
          Row(children: [
            OutlinedButton.icon(
              onPressed: uploading.contains(f.name) ? null : () => _pick(f),
              icon: uploading.contains(f.name)
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file, size: 18),
              label: Text(uploading.contains(f.name) ? 'Uploading…' : (v == null ? 'Choose file' : 'Replace')),
            ),
            if (v != null) IconButton(onPressed: () => setState(() => data[f.name] = null), icon: const Icon(Icons.close)),
          ]),
          if (v != null)
            f.type == F.image
                ? Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v, height: 90)))
                : Text(v.split('/').last, style: const TextStyle(fontSize: 12, color: AppColors.inkMute)),
        ]);
    }
  }
}
