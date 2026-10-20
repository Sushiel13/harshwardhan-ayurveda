import Link from 'next/link';
import { redirect } from 'next/navigation';
import { Bell, BookOpen, FileText, LogOut, PlayCircle, Receipt } from 'lucide-react';
import { supabaseServer } from '@/lib/supabase/server';
import { getSessionProfile } from '@/lib/data';
import { Cover } from '@/components/Cards';
import { inr } from '@/lib/site';
import { SignOut } from '@/components/SignOut';

export const dynamic = 'force-dynamic';
export const metadata = { title: 'My learning' };

export default async function Dashboard() {
  const { user, profile } = await getSessionProfile();
  if (!user) redirect('/login?next=/dashboard');
  const sb = supabaseServer();
  const { data: purchases } = await sb.from('purchases').select('*').eq('user_id', user.id).order('created_at', { ascending: false });
  const ids = (t: string) => (purchases ?? []).filter((p) => p.item_type === t).map((p) => p.item_id);
  const [courses, series, ebooks, notifs, attempts, payments] = await Promise.all([
    ids('course').length ? sb.from('courses').select('*').in('id', ids('course')) : Promise.resolve({ data: [] as any[] }),
    ids('test_series').length ? sb.from('test_series').select('*').in('id', ids('test_series')) : Promise.resolve({ data: [] as any[] }),
    ids('ebook').length ? sb.from('ebooks').select('*').in('id', ids('ebook')) : Promise.resolve({ data: [] as any[] }),
    sb.from('notifications').select('*').order('created_at', { ascending: false }).limit(8),
    sb.from('test_attempts').select('*, tests(title)').eq('user_id', user.id).order('created_at', { ascending: false }).limit(5),
    sb.from('payments').select('*').eq('user_id', user.id).eq('status', 'paid').order('created_at', { ascending: false }),
  ]);

  return (
    <div className="container-x py-10">
      <div className="flex flex-col justify-between gap-4 rounded-3xl bg-forest-900 p-8 text-ivory md:flex-row md:items-center">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brass-300">My learning</p>
          <h1 className="mt-1 font-display text-3xl">Namaste, {profile?.full_name?.split(' ')[0] || 'Student'}</h1>
        </div>
        <div className="flex gap-2">
          {profile?.role === 'admin' && <Link href="/admin" className="btn-gold">Open admin panel</Link>}
          <SignOut className="btn border border-ivory/20 text-ivory hover:bg-ivory/10"><LogOut size={15} /> Sign out</SignOut>
        </div>
      </div>

      <div className="mt-10 grid gap-10 lg:grid-cols-12">
        <div className="space-y-10 lg:col-span-8">
          <Block title="My courses" icon={PlayCircle} empty={!courses.data?.length} emptyHref="/courses" emptyText="Browse courses">
            <div className="grid gap-4 sm:grid-cols-2">
              {courses.data?.map((c: any) => (
                <Link key={c.id} href={`/learn/${c.slug}`} className="card group flex overflow-hidden transition hover:shadow-lift">
                  <div className="w-28 shrink-0"><Cover src={c.thumbnail_url} title="" /></div>
                  <div className="p-4"><p className="font-semibold leading-snug text-forest-900">{c.title}</p><p className="mt-2 text-xs font-semibold text-brass-600">Resume →</p></div>
                </Link>
              ))}
            </div>
          </Block>
          <Block title="My test series" icon={FileText} empty={!series.data?.length} emptyHref="/test-series" emptyText="Find a test series">
            <div className="grid gap-3 sm:grid-cols-2">
              {series.data?.map((s: any) => <Link key={s.id} href={`/test-series/${s.id}`} className="card p-4 font-semibold text-forest-900 hover:shadow-lift">{s.title}</Link>)}
            </div>
          </Block>
          <Block title="My eBooks" icon={BookOpen} empty={!ebooks.data?.length} emptyHref="/ebooks" emptyText="Visit the library">
            <div className="grid gap-3 sm:grid-cols-2">
              {ebooks.data?.map((e: any) => <Link key={e.id} href={`/ebooks/${e.id}`} className="card p-4 font-semibold text-forest-900 hover:shadow-lift">{e.title}</Link>)}
            </div>
          </Block>
          {!!attempts.data?.length && (
            <div>
              <h2 className="font-display text-2xl text-forest-900">Recent test scores</h2>
              <div className="card mt-4 divide-y divide-forest-900/5">
                {attempts.data.map((a: any) => (
                  <div key={a.id} className="flex justify-between px-5 py-3.5 text-sm"><span className="text-forest-900">{a.tests?.title}</span><span className="font-semibold">{a.score} / {a.total}</span></div>
                ))}
              </div>
            </div>
          )}
        </div>
        <aside className="space-y-8 lg:col-span-4">
          <div id="updates" className="card p-6">
            <h2 className="flex items-center gap-2 font-display text-xl text-forest-900"><Bell size={18} className="text-brass-600" /> Updates</h2>
            <ul className="mt-4 space-y-4">
              {notifs.data?.map((n: any) => (
                <li key={n.id} className="border-l-2 border-brass-400 pl-3">
                  <p className="text-sm font-semibold text-forest-900">{n.title}</p>
                  {n.body && <p className="text-xs text-ink-soft">{n.body}</p>}
                  <p className="mt-1 text-[11px] text-ink-mute">{new Date(n.created_at).toLocaleDateString('en-IN')}</p>
                </li>
              ))}
            </ul>
          </div>
          <div className="card p-6">
            <h2 className="flex items-center gap-2 font-display text-xl text-forest-900"><Receipt size={18} className="text-brass-600" /> Payments</h2>
            <ul className="mt-4 space-y-2 text-sm">
              {payments.data?.map((p: any) => <li key={p.id} className="flex justify-between"><span className="text-ink-soft">{new Date(p.created_at).toLocaleDateString('en-IN')} · {p.item_type.replace('_', ' ')}</span><span className="font-semibold">{inr(p.amount)}</span></li>)}
              {!payments.data?.length && <li className="text-ink-mute">No payments yet.</li>}
            </ul>
          </div>
        </aside>
      </div>
    </div>
  );
}

function Block({ title, icon: Icon, empty, emptyHref, emptyText, children }: { title: string; icon: typeof Bell; empty: boolean; emptyHref: string; emptyText: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="flex items-center gap-2 font-display text-2xl text-forest-900"><Icon size={20} className="text-brass-600" /> {title}</h2>
      <div className="mt-4">{empty ? <div className="card p-6 text-sm text-ink-soft">Nothing here yet. <Link href={emptyHref} className="font-semibold text-forest-800">{emptyText} →</Link></div> : children}</div>
    </section>
  );
}
