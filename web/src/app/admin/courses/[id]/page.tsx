'use client';
import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowDown, ArrowLeft, ArrowUp, Eye, FileText, Loader2, Pencil, PlayCircle, Plus, Trash2, X } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { FieldInput, type Field } from '@/components/admin/Crud';
import type { Course, Lesson, Section } from '@/lib/types';

export default function CourseLessons({ params }: { params: { id: string } }) {
  const sb = supabaseBrowser();
  const [course, setCourse] = useState<Course | null>(null);
  const [sections, setSections] = useState<Section[]>([]);
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [edit, setEdit] = useState<any | null>(null);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    const [{ data: c }, { data: s }, { data: l }] = await Promise.all([
      sb.from('courses').select('*').eq('id', params.id).single(),
      sb.from('course_sections').select('*').eq('course_id', params.id).order('position'),
      sb.from('lessons').select('*').eq('course_id', params.id).order('position'),
    ]);
    setCourse(c); setSections(s ?? []); setLessons(l ?? []);
  }, [sb, params.id]);
  useEffect(() => { load(); }, [load]);

  const folder = `courses/${params.id}`;
  const fields: Field[] = [
    { name: 'title', label: 'Lesson title', type: 'text', required: true },
    { name: 'section_id', label: 'Section', type: 'select', options: sections.map((s) => ({ value: s.id, label: s.title })) },
    { name: 'kind', label: 'Type', type: 'select', options: [{ value: 'video', label: 'Video' }, { value: 'pdf', label: 'PDF only' }], default: 'video' },
    { name: 'video_path', label: 'Upload video (MP4)', type: 'private-file', folder, accept: 'video/*', help: 'Stored privately; only enrolled students can stream it.' },
    { name: 'video_url', label: '…or video link', type: 'text', help: 'Bunny Stream / Vimeo / YouTube (unlisted) link. Used only if no file is uploaded.' },
    { name: 'pdf_path', label: 'Attach notes PDF', type: 'private-file', folder, accept: 'application/pdf' },
    { name: 'description', label: 'Description', type: 'textarea' },
    { name: 'duration_minutes', label: 'Duration (minutes)', type: 'number' },
    { name: 'is_preview', label: 'Free preview (anyone can watch)', type: 'bool' },
  ];

  async function save(e: React.FormEvent) {
    e.preventDefault(); setSaving(true); setErr('');
    const { id, created_at, ...data } = edit;
    data.duration_minutes = data.duration_minutes ? Number(data.duration_minutes) : null;
    data.kind = data.kind || 'video';
    const res = id ? await sb.from('lessons').update(data).eq('id', id)
      : await sb.from('lessons').insert({ ...data, course_id: params.id, position: lessons.length + 1 });
    setSaving(false);
    if (res.error) return setErr(res.error.message);
    setEdit(null); load();
  }
  async function del(l: Lesson) {
    if (!confirm(`Delete "${l.title}"?`)) return;
    const paths = [l.video_path, l.pdf_path].filter(Boolean) as string[];
    if (paths.length) await sb.storage.from('content').remove(paths);
    await sb.from('lessons').delete().eq('id', l.id); load();
  }
  async function move(l: Lesson, dir: -1 | 1) {
    const i = lessons.findIndex((x) => x.id === l.id), j = i + dir;
    if (j < 0 || j >= lessons.length) return;
    const other = lessons[j];
    await Promise.all([
      sb.from('lessons').update({ position: j + 1 }).eq('id', l.id),
      sb.from('lessons').update({ position: i + 1 }).eq('id', other.id),
    ]);
    load();
  }
  async function addSection() {
    const title = prompt('Section name (e.g. "Chapter 1 — Introduction")');
    if (!title) return;
    await sb.from('course_sections').insert({ course_id: params.id, title, position: sections.length + 1 }); load();
  }
  async function renameSection(s: Section) {
    const title = prompt('Rename section', s.title);
    if (title) { await sb.from('course_sections').update({ title }).eq('id', s.id); load(); }
  }
  async function deleteSection(s: Section) {
    if (confirm(`Delete section "${s.title}"? Lessons in it will be kept.`)) { await sb.from('course_sections').delete().eq('id', s.id); load(); }
  }

  if (!course) return <Loader2 className="animate-spin" />;
  const groups = [...sections.map((s) => ({ s, items: lessons.filter((l) => l.section_id === s.id) })),
    { s: null as Section | null, items: lessons.filter((l) => !l.section_id) }];

  return (
    <div>
      <Link href="/admin/courses" className="flex items-center gap-1.5 text-sm text-ink-mute"><ArrowLeft size={15} /> All courses</Link>
      <div className="mt-3 flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div><h1 className="font-display text-3xl text-forest-900">{course.title}</h1><p className="text-sm text-ink-mute">{lessons.length} lessons · {course.is_published ? 'Published' : 'Draft'}</p></div>
        <div className="flex gap-2">
          <Link href={`/courses/${course.slug}`} target="_blank" className="btn-ghost"><Eye size={15} /> Preview</Link>
          <button className="btn-ghost" onClick={addSection}><Plus size={15} /> Section</button>
          <button className="btn-primary" onClick={() => setEdit({ kind: 'video', is_preview: false })}><Plus size={15} /> Lesson</button>
        </div>
      </div>

      <div className="mt-6 space-y-5">
        {groups.filter((g) => g.s || g.items.length).map((g) => (
          <div key={g.s?.id ?? 'none'} className="card overflow-hidden">
            <div className="flex items-center justify-between border-b border-forest-900/5 bg-ivory-50 px-5 py-3">
              <span className="font-semibold text-forest-900">{g.s?.title ?? 'Unsectioned lessons'}</span>
              {g.s && <span className="flex gap-1"><button onClick={() => renameSection(g.s!)} className="p-1.5 text-ink-mute"><Pencil size={14} /></button><button onClick={() => deleteSection(g.s!)} className="p-1.5 text-ink-mute hover:text-red-700"><Trash2 size={14} /></button></span>}
            </div>
            {g.items.map((l) => (
              <div key={l.id} className="flex items-center gap-3 border-b border-forest-900/5 px-5 py-3 text-sm last:border-0">
                {l.kind === 'pdf' ? <FileText size={16} className="text-brass-600" /> : <PlayCircle size={16} className="text-brass-600" />}
                <span className="flex-1 text-forest-900">{l.title}
                  {!l.video_path && !l.video_url && l.kind === 'video' && <span className="ml-2 chip !bg-red-50 !text-red-700">no video</span>}
                  {l.is_preview && <span className="ml-2 chip">preview</span>}</span>
                <button onClick={() => move(l, -1)} className="p-1.5 text-ink-mute"><ArrowUp size={14} /></button>
                <button onClick={() => move(l, 1)} className="p-1.5 text-ink-mute"><ArrowDown size={14} /></button>
                <button onClick={() => setEdit(l)} className="p-1.5 text-ink-mute hover:text-forest-800"><Pencil size={14} /></button>
                <button onClick={() => del(l)} className="p-1.5 text-ink-mute hover:text-red-700"><Trash2 size={14} /></button>
              </div>
            ))}
            {g.items.length === 0 && <p className="px-5 py-4 text-sm text-ink-mute">No lessons in this section yet.</p>}
          </div>
        ))}
        {lessons.length === 0 && sections.length === 0 && <p className="card p-8 text-center text-ink-mute">Add a section (optional), then add your first lesson.</p>}
      </div>

      {edit && (
        <div className="fixed inset-0 z-50 flex justify-end bg-forest-950/40 backdrop-blur-sm" onClick={() => setEdit(null)}>
          <form onSubmit={save} onClick={(e) => e.stopPropagation()} className="flex h-full w-full max-w-xl flex-col bg-ivory">
            <div className="flex items-center justify-between border-b border-forest-900/10 px-6 py-4"><h2 className="font-display text-xl">{edit.id ? 'Edit lesson' : 'New lesson'}</h2><button type="button" onClick={() => setEdit(null)}><X /></button></div>
            <div className="flex-1 space-y-5 overflow-y-auto p-6">
              {fields.map((f) => <FieldInput key={f.name} f={f} value={edit[f.name]} onChange={(v) => setEdit({ ...edit, [f.name]: v })} />)}
              {err && <p className="text-sm text-red-700">{err}</p>}
            </div>
            <div className="flex justify-end gap-2 border-t border-forest-900/10 px-6 py-4"><button type="button" className="btn-ghost" onClick={() => setEdit(null)}>Cancel</button><button className="btn-primary" disabled={saving}>{saving && <Loader2 size={15} className="animate-spin" />} Save lesson</button></div>
          </form>
        </div>
      )}
    </div>
  );
}
