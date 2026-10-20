'use client';
import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, ClipboardPaste, Loader2, Pencil, Plus, Trash2, X } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { Crud } from '@/components/admin/Crud';
import type { Question, Test, TestSeries } from '@/lib/types';

export default function SeriesTests({ params }: { params: { id: string } }) {
  const sb = supabaseBrowser();
  const [series, setSeries] = useState<TestSeries | null>(null);
  const [test, setTest] = useState<Test | null>(null);
  useEffect(() => { sb.from('test_series').select('*').eq('id', params.id).single().then(({ data }: any) => setSeries(data)); }, [sb, params.id]);
  if (!series) return <Loader2 className="animate-spin" />;
  return (
    <div>
      <Link href="/admin/test-series" className="flex items-center gap-1.5 text-sm text-ink-mute"><ArrowLeft size={15} /> All test series</Link>
      <p className="mt-2 text-sm text-ink-mute">{series.title}</p>
      {test ? <Questions test={test} back={() => setTest(null)} /> : (
        <Crud table="tests" title="Tests" filter={{ series_id: params.id }} order="position" ascending
          fields={[
            { name: 'title', label: 'Test name', type: 'text', required: true },
            { name: 'instructions', label: 'Instructions', type: 'textarea' },
            { name: 'duration_minutes', label: 'Duration (minutes)', type: 'number', default: 30, required: true },
            { name: 'marks_per_question', label: 'Marks per correct answer', type: 'number', default: 1 },
            { name: 'negative_marks', label: 'Negative marks per wrong answer', type: 'number', default: 0 },
            { name: 'position', label: 'Order', type: 'number', default: 1 },
            { name: 'is_published', label: 'Published', type: 'bool', default: true },
          ]}
          columns={[{ key: 'title', label: 'Test' }, { key: 'duration_minutes', label: 'Minutes' }, { key: 'negative_marks', label: 'Negative' }]}
          extraActions={(r) => <button onClick={() => setTest(r)} className="mr-2 text-xs font-semibold text-brass-600">Questions →</button>}
        />
      )}
    </div>
  );
}

function Questions({ test, back }: { test: Test; back: () => void }) {
  const sb = supabaseBrowser();
  const [qs, setQs] = useState<Question[]>([]);
  const [edit, setEdit] = useState<any | null>(null);
  const [bulk, setBulk] = useState<string | null>(null);
  const [msg, setMsg] = useState('');
  const load = useCallback(async () => {
    const { data } = await sb.from('questions').select('*').eq('test_id', test.id).order('position');
    setQs(data ?? []);
  }, [sb, test.id]);
  useEffect(() => { load(); }, [load]);

  async function save(e: React.FormEvent) {
    e.preventDefault();
    const options = (edit.options as string[]).map((o) => o.trim()).filter(Boolean);
    const row = { test_id: test.id, question: edit.question, options, correct_index: Number(edit.correct_index), explanation: edit.explanation || null, position: edit.position ?? qs.length + 1 };
    const res = edit.id ? await sb.from('questions').update(row).eq('id', edit.id) : await sb.from('questions').insert(row);
    if (res.error) return alert(res.error.message);
    setEdit(null); load();
  }

  /** Bulk format (blank line between questions):
   *  Q: question text
   *  A) option   B) option   C) option   D) option   (each on its own line)
   *  ANS: B
   *  EXP: optional explanation */
  async function importBulk() {
    const blocks = (bulk ?? '').split(/\n\s*\n/).map((b) => b.trim()).filter(Boolean);
    const rows: any[] = [];
    for (const [n, b] of blocks.entries()) {
      const lines = b.split('\n').map((l) => l.trim());
      const q = lines.find((l) => /^q[:.]/i.test(l))?.replace(/^q[:.]\s*/i, '');
      const opts = lines.filter((l) => /^[A-F][).]/.test(l)).map((l) => l.replace(/^[A-F][).]\s*/, ''));
      const ans = lines.find((l) => /^ans[:.]/i.test(l))?.replace(/^ans[:.]\s*/i, '').trim().toUpperCase();
      const exp = lines.find((l) => /^exp[:.]/i.test(l))?.replace(/^exp[:.]\s*/i, '');
      if (!q || opts.length < 2 || !ans) { setMsg(`Block ${n + 1} is missing Q:, options or ANS:`); return; }
      rows.push({ test_id: test.id, question: q, options: opts, correct_index: ans.charCodeAt(0) - 65, explanation: exp ?? null, position: qs.length + n + 1 });
    }
    const { error } = await sb.from('questions').insert(rows);
    if (error) return setMsg(error.message);
    setBulk(null); setMsg(`Imported ${rows.length} questions.`); load();
  }

  return (
    <div className="mt-3">
      <button onClick={back} className="flex items-center gap-1.5 text-sm text-ink-mute"><ArrowLeft size={15} /> Tests</button>
      <div className="mt-2 flex flex-col justify-between gap-3 md:flex-row md:items-center">
        <h1 className="font-display text-3xl text-forest-900">{test.title} <span className="text-lg text-ink-mute">· {qs.length} questions</span></h1>
        <div className="flex gap-2">
          <button className="btn-ghost" onClick={() => setBulk('')}><ClipboardPaste size={15} /> Bulk import</button>
          <button className="btn-primary" onClick={() => setEdit({ question: '', options: ['', '', '', ''], correct_index: 0, explanation: '' })}><Plus size={15} /> Question</button>
        </div>
      </div>
      {msg && <p className="mt-3 text-sm text-forest-700">{msg}</p>}
      <div className="mt-6 space-y-3">
        {qs.map((q, i) => (
          <div key={q.id} className="card p-5">
            <div className="flex justify-between gap-4">
              <p className="font-medium text-forest-900"><span className="text-brass-600">{i + 1}.</span> {q.question}</p>
              <span className="flex shrink-0"><button onClick={() => setEdit({ ...q, options: [...q.options, '', ''].slice(0, Math.max(4, q.options.length)) })} className="p-1.5 text-ink-mute"><Pencil size={14} /></button>
                <button onClick={async () => { if (confirm('Delete question?')) { await sb.from('questions').delete().eq('id', q.id); load(); } }} className="p-1.5 text-ink-mute hover:text-red-700"><Trash2 size={14} /></button></span>
            </div>
            <ol className="mt-2 grid gap-1 text-sm sm:grid-cols-2">
              {q.options.map((o, k) => <li key={k} className={k === q.correct_index ? 'font-semibold text-forest-700' : 'text-ink-soft'}>{String.fromCharCode(65 + k)}) {o}</li>)}
            </ol>
          </div>
        ))}
      </div>

      {edit && (
        <Modal title={edit.id ? 'Edit question' : 'New question'} close={() => setEdit(null)}>
          <form onSubmit={save} className="space-y-4">
            <div><label className="label">Question</label><textarea required rows={3} className="input" value={edit.question} onChange={(e) => setEdit({ ...edit, question: e.target.value })} /></div>
            {(edit.options as string[]).map((o, k) => (
              <div key={k} className="flex items-center gap-2">
                <input type="radio" name="correct" checked={Number(edit.correct_index) === k} onChange={() => setEdit({ ...edit, correct_index: k })} />
                <input className="input" placeholder={`Option ${String.fromCharCode(65 + k)}`} value={o} onChange={(e) => { const n = [...edit.options]; n[k] = e.target.value; setEdit({ ...edit, options: n }); }} />
              </div>
            ))}
            <p className="text-xs text-ink-mute">Select the radio button next to the correct answer.</p>
            <div><label className="label">Explanation</label><textarea rows={3} className="input" value={edit.explanation ?? ''} onChange={(e) => setEdit({ ...edit, explanation: e.target.value })} /></div>
            <button className="btn-primary">Save question</button>
          </form>
        </Modal>
      )}
      {bulk !== null && (
        <Modal title="Bulk import questions" close={() => setBulk(null)}>
          <p className="text-sm text-ink-soft">Paste questions in this format, with a blank line between questions:</p>
          <pre className="mt-2 rounded-lg bg-ivory-200 p-3 text-xs">{`Q: Which dosha is dominant in old age?\nA) Kapha\nB) Pitta\nC) Vata\nD) None\nANS: C\nEXP: Vriddhavastha is Vata-predominant.`}</pre>
          <textarea rows={14} className="input mt-4 font-mono text-xs" value={bulk} onChange={(e) => setBulk(e.target.value)} />
          <button className="btn-primary mt-4" onClick={importBulk}>Import</button>
        </Modal>
      )}
    </div>
  );
}

function Modal({ title, close, children }: { title: string; close: () => void; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-forest-950/40 backdrop-blur-sm" onClick={close}>
      <div onClick={(e) => e.stopPropagation()} className="h-full w-full max-w-xl overflow-y-auto bg-ivory p-6">
        <div className="mb-5 flex items-center justify-between"><h2 className="font-display text-xl">{title}</h2><button onClick={close}><X /></button></div>
        {children}
      </div>
    </div>
  );
}
