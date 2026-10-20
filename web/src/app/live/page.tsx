'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { CalendarClock, Lock, Radio, Video } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { PageHero } from '@/components/Cards';
import type { LiveClass } from '@/lib/types';

export default function Live() {
  const [items, setItems] = useState<(LiveClass & { can: boolean })[]>([]);
  const [user, setUser] = useState<boolean | null>(null);
  useEffect(() => {
    (async () => {
      const sb = supabaseBrowser();
      const { data: { user } } = await sb.auth.getUser();
      setUser(!!user);
      const since = new Date(Date.now() - 3 * 3600_000).toISOString();
      const { data } = await sb.from('live_classes').select('*').gte('starts_at', since).order('starts_at');
      const rows = await Promise.all((data ?? []).map(async (l: LiveClass) => {
        let can = l.is_free || (!!user && !l.course_id);
        if (!can && l.course_id && user) can = !!(await sb.rpc('has_access', { p_type: 'course', p_id: l.course_id })).data;
        return { ...l, can };
      }));
      setItems(rows);
    })();
  }, []);

  return (
    <>
      <PageHero eyebrow="Live classes" title="Learn live with your teacher" text="Join scheduled classes, ask doubts in real time and get recordings afterwards." />
      <div className="container-x py-12">
        {user === false && <p className="mb-6 rounded-xl bg-brass-500/10 p-4 text-sm text-forest-900"><Link href="/login?next=/live" className="font-semibold underline">Log in</Link> to see the classes you can join.</p>}
        <div className="grid gap-4 md:grid-cols-2">
          {items.map((l) => {
            const start = new Date(l.starts_at);
            const isLive = Date.now() >= start.getTime() - 10 * 60_000 && Date.now() <= start.getTime() + (l.duration_minutes ?? 60) * 60_000;
            return (
              <div key={l.id} className="card flex gap-5 p-5">
                <div className="w-20 shrink-0 rounded-xl bg-forest-900 p-3 text-center text-ivory">
                  <p className="text-xs uppercase text-brass-300">{start.toLocaleString('en-IN', { month: 'short' })}</p>
                  <p className="font-display text-3xl">{start.getDate()}</p>
                </div>
                <div className="flex flex-1 flex-col">
                  <div className="flex items-center gap-2">
                    {isLive && <span className="flex items-center gap-1 rounded-full bg-red-600 px-2 py-0.5 text-[10px] font-bold text-white"><Radio size={10} /> LIVE</span>}
                    <h3 className="font-semibold text-forest-900">{l.title}</h3>
                  </div>
                  <p className="mt-1 flex items-center gap-1.5 text-xs text-ink-mute"><CalendarClock size={12} /> {start.toLocaleString('en-IN', { weekday: 'short', hour: 'numeric', minute: '2-digit' })} · {l.duration_minutes} min</p>
                  {l.description && <p className="mt-2 text-sm text-ink-soft">{l.description}</p>}
                  <div className="mt-auto pt-4">
                    {l.can && l.meeting_url ? <a href={l.meeting_url} target="_blank" className={isLive ? 'btn-gold' : 'btn-ghost'}><Video size={15} /> {isLive ? 'Join now' : 'Class link'}</a>
                      : <span className="flex items-center gap-1.5 text-xs font-semibold text-ink-mute"><Lock size={13} /> For enrolled students</span>}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
        {items.length === 0 && <p className="text-ink-soft">No upcoming live classes right now.</p>}
      </div>
    </>
  );
}
