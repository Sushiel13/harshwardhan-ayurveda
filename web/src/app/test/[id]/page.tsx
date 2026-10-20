'use client';
import { useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { CheckCircle2, Clock, Loader2, XCircle } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import type { Test } from '@/lib/types';

type Q = { id: string; question: string; options: string[] };
type Result = { correct: number; wrong: number; unanswered: number; score: number; total: number;
  review: { id: string; question: string; options: string[]; selected: number | null; correct: number; explanation: string | null }[] };

export default function TakeTest({ params }: { params: { id: string } }) {
  const sb = supabaseBrowser();
  const [test, setTest] = useState<Test | null>(null);
  const [qs, setQs] = useState<Q[]>([]);
  const [i, setI] = useState(0);
  const [ans, setAns] = useState<Record<string, number>>({});
  const [left, setLeft] = useState(0);
  const [started, setStarted] = useState(false);
  const [result, setResult] = useState<Result | null>(null);
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);
  const submitted = useRef(false);

  useEffect(() => {
    (async () => {
      const { data: t } = await sb.from('tests').select('*').eq('id', params.id).single();
      setTest(t);
      const { data, error } = await sb.rpc('get_test_questions', { p_test: params.id });
      if (error) setErr(error.message); else setQs(data ?? []);
      if (t) setLeft(t.duration_minutes * 60);
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.id]);

  useEffect(() => {
    if (!started || result) return;
    if (left <= 0) { submit(); return; }
    const t = setTimeout(() => setLeft((x) => x - 1), 1000);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [started, left, result]);

  async function submit() {
    if (submitted.current) return;
    submitted.current = true; setBusy(true);
    const { data, error } = await sb.rpc('submit_test', { p_test: params.id, p_answers: ans });
    setBusy(false);
    if (error) { setErr(error.message); submitted.current = false; } else setResult(data as Result);
  }

  const answered = useMemo(() => Object.keys(ans).length, [ans]);
  const mm = String(Math.floor(left / 60)).padStart(2, '0'), ss = String(left % 60).padStart(2, '0');

  if (err) return <Shell><p className="text-red-700">{err}</p><Link href="/test-series" className="btn-ghost mt-6">Back to test series</Link></Shell>;
  if (!test) return <Shell><Loader2 className="animate-spin" /></Shell>;

  if (result) {
    const pct = result.total ? Math.round((result.score / result.total) * 100) : 0;
    return (
      <div className="container-x max-w-3xl py-12">
        <div className="card overflow-hidden">
          <div className="bg-forest-900 p-8 text-ivory">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brass-300">Result</p>
            <h1 className="mt-2 font-display text-3xl">{test.title}</h1>
            <p className="mt-6 font-display text-6xl">{result.score}<span className="text-2xl text-ivory/50"> / {result.total}</span></p>
            <p className="mt-1 text-ivory/60">{pct}% score</p>
          </div>
          <div className="grid grid-cols-3 divide-x divide-forest-900/10 text-center">
            <Stat n={result.correct} l="Correct" c="text-forest-700" />
            <Stat n={result.wrong} l="Wrong" c="text-red-700" />
            <Stat n={result.unanswered} l="Skipped" c="text-ink-mute" />
          </div>
        </div>
        <h2 className="mt-10 font-display text-2xl text-forest-900">Solutions</h2>
        <div className="mt-4 space-y-4">
          {result.review.map((r, n) => (
            <div key={r.id} className="card p-5">
              <p className="font-medium text-forest-900"><span className="text-brass-600">Q{n + 1}.</span> {r.question}</p>
              <ul className="mt-3 space-y-2">
                {r.options.map((o, k) => (
                  <li key={k} className={`flex items-center gap-2 rounded-lg px-3 py-2 text-sm ${k === r.correct ? 'bg-forest-50 text-forest-800 font-semibold' : k === r.selected ? 'bg-red-50 text-red-800' : 'text-ink-soft'}`}>
                    {k === r.correct ? <CheckCircle2 size={15} /> : k === r.selected ? <XCircle size={15} /> : <span className="w-[15px]" />} {o}
                  </li>
                ))}
              </ul>
              {r.explanation && <p className="mt-3 rounded-lg bg-ivory-100 p-3 text-sm text-ink-soft"><b className="text-forest-900">Explanation:</b> {r.explanation}</p>}
            </div>
          ))}
        </div>
        <Link href={`/test-series/${test.series_id}`} className="btn-primary mt-8">Back to series</Link>
      </div>
    );
  }

  if (!started) return (
    <Shell>
      <p className="eyebrow">Ready?</p>
      <h1 className="mt-2 font-display text-3xl text-forest-900">{test.title}</h1>
      <ul className="mt-6 space-y-2 text-sm text-ink-soft">
        <li>• {qs.length} questions · {test.duration_minutes} minutes</li>
        <li>• +{test.marks_per_question} for each correct answer{Number(test.negative_marks) > 0 ? `, −${test.negative_marks} for each wrong answer` : ''}</li>
        <li>• The test submits automatically when time runs out</li>
      </ul>
      {test.instructions && <p className="mt-4 whitespace-pre-line text-sm text-ink-soft">{test.instructions}</p>}
      <button className="btn-primary mt-8 !px-8" onClick={() => setStarted(true)} disabled={!qs.length}>Begin test</button>
    </Shell>
  );

  const q = qs[i];
  return (
    <div className="container-x grid max-w-6xl gap-8 py-8 lg:grid-cols-12">
      <div className="lg:col-span-8">
        <div className="card p-6 md:p-8">
          <div className="flex items-center justify-between text-sm">
            <span className="font-semibold text-brass-600">Question {i + 1} of {qs.length}</span>
            <span className={`flex items-center gap-1.5 rounded-full px-3 py-1 font-mono font-semibold ${left < 60 ? 'bg-red-50 text-red-700' : 'bg-forest-50 text-forest-800'}`}><Clock size={14} /> {mm}:{ss}</span>
          </div>
          <p className="mt-6 text-lg font-medium leading-relaxed text-forest-900">{q.question}</p>
          <div className="mt-6 space-y-3">
            {q.options.map((o, k) => (
              <button key={k} onClick={() => setAns({ ...ans, [q.id]: k })}
                className={`flex w-full items-center gap-3 rounded-xl border px-4 py-3.5 text-left text-[15px] transition ${ans[q.id] === k ? 'border-forest-700 bg-forest-50 text-forest-900' : 'border-forest-900/10 hover:border-forest-900/30'}`}>
                <span className={`grid h-7 w-7 shrink-0 place-items-center rounded-full text-xs font-bold ${ans[q.id] === k ? 'bg-forest-800 text-ivory' : 'bg-ivory-200 text-ink-soft'}`}>{String.fromCharCode(65 + k)}</span>
                {o}
              </button>
            ))}
          </div>
          <div className="mt-8 flex justify-between">
            <button className="btn-ghost" disabled={i === 0} onClick={() => setI(i - 1)}>← Previous</button>
            {i < qs.length - 1 ? <button className="btn-primary" onClick={() => setI(i + 1)}>Next →</button>
              : <button className="btn-gold" onClick={submit} disabled={busy}>{busy && <Loader2 size={15} className="animate-spin" />} Submit test</button>}
          </div>
        </div>
      </div>
      <aside className="lg:col-span-4">
        <div className="card p-5">
          <p className="text-sm font-semibold text-forest-900">{answered} of {qs.length} answered</p>
          <div className="mt-4 grid grid-cols-6 gap-2">
            {qs.map((x, k) => (
              <button key={x.id} onClick={() => setI(k)}
                className={`h-9 rounded-lg text-xs font-bold ${k === i ? 'ring-2 ring-brass-500' : ''} ${ans[x.id] !== undefined ? 'bg-forest-800 text-ivory' : 'bg-ivory-200 text-ink-soft'}`}>{k + 1}</button>
            ))}
          </div>
          <button className="btn-gold mt-6 w-full" onClick={() => confirm('Submit the test now?') && submit()} disabled={busy}>Submit test</button>
        </div>
      </aside>
    </div>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return <div className="container-x max-w-2xl py-20"><div className="card p-8 md:p-10">{children}</div></div>;
}
function Stat({ n, l, c }: { n: number; l: string; c: string }) {
  return <div className="p-5"><p className={`font-display text-3xl ${c}`}>{n}</p><p className="text-xs uppercase tracking-wider text-ink-mute">{l}</p></div>;
}
