import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Clock, ListChecks, MinusCircle } from 'lucide-react';
import { supabaseServer } from '@/lib/supabase/server';
import { configured } from '@/lib/data';
import { BuyButton } from '@/components/BuyButton';
import { Price } from '@/components/Cards';
import type { Test, TestSeries } from '@/lib/types';

export const dynamic = 'force-dynamic';

export default async function SeriesPage({ params }: { params: { id: string } }) {
  if (!configured()) notFound();
  const sb = supabaseServer();
  const { data: s } = await sb.from('test_series').select('*').eq('id', params.id).maybeSingle<TestSeries>();
  if (!s) notFound();
  const { data: tests } = await sb.from('tests').select('*').eq('series_id', s.id).order('position');
  const { data: access } = await sb.rpc('has_access', { p_type: 'test_series', p_id: s.id });

  return (
    <div className="container-x grid gap-10 py-12 lg:grid-cols-12">
      <div className="lg:col-span-8">
        <p className="eyebrow">Test series</p>
        <h1 className="mt-3 font-display text-4xl text-forest-900 md:text-5xl">{s.title}</h1>
        <p className="mt-4 text-lg text-ink-soft">{s.description}</p>
        <div className="mt-10 space-y-3">
          {(tests as Test[] ?? []).map((t, i) => (
            <div key={t.id} className="card flex flex-col justify-between gap-4 p-5 sm:flex-row sm:items-center">
              <div className="flex items-start gap-4">
                <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-brass-500/15 font-display text-brass-700">{i + 1}</span>
                <div>
                  <h3 className="font-semibold text-forest-900">{t.title}</h3>
                  <div className="mt-1 flex flex-wrap gap-4 text-xs text-ink-mute">
                    <span className="flex items-center gap-1"><Clock size={12} /> {t.duration_minutes} min</span>
                    <span className="flex items-center gap-1"><ListChecks size={12} /> +{t.marks_per_question} per correct</span>
                    {Number(t.negative_marks) > 0 && <span className="flex items-center gap-1"><MinusCircle size={12} /> −{t.negative_marks} per wrong</span>}
                  </div>
                </div>
              </div>
              {access ? <Link href={`/test/${t.id}`} className="btn-primary">Start test</Link> : <span className="chip">Locked</span>}
            </div>
          ))}
          {(!tests || tests.length === 0) && <p className="text-sm text-ink-soft">Tests will be added soon.</p>}
        </div>
      </div>
      <aside className="lg:col-span-4">
        <div className="card sticky top-24 p-6">
          <Price price={s.price} mrp={s.mrp} free={s.is_free} />
          <p className="mt-1 text-xs text-ink-mute">{s.validity_days ? `Valid for ${s.validity_days} days` : 'Lifetime access'}</p>
          <div className="mt-5"><BuyButton itemType="test_series" itemId={s.id} price={s.price} free={s.is_free} title={s.title} openHref={`/test-series/${s.id}`} /></div>
        </div>
      </aside>
    </div>
  );
}
