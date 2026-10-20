'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { supabaseBrowser } from '@/lib/supabase/client';
import { inr } from '@/lib/site';

export default function AdminHome() {
  const sb = supabaseBrowser();
  const [s, setS] = useState<any>(null);
  const [recent, setRecent] = useState<any[]>([]);
  useEffect(() => {
    sb.rpc('admin_stats').then(({ data }: any) => setS(data));
    sb.from('payments').select('*, profiles(full_name, email)').eq('status', 'paid').order('created_at', { ascending: false }).limit(8)
      .then(({ data }: any) => setRecent(data ?? []));
  }, [sb]);
  const tiles = [
    ['Revenue (all time)', s ? inr(s.revenue) : '—'], ['Revenue (30 days)', s ? inr(s.revenue_30d) : '—'],
    ['Students', s?.students ?? '—'], ['Paid orders', s?.sales ?? '—'], ['Enrolments', s?.enrollments ?? '—'], ['Courses', s?.courses ?? '—'],
  ];
  return (
    <div>
      <h1 className="font-display text-3xl text-forest-900">Overview</h1>
      <div className="mt-6 grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-6">
        {tiles.map(([l, v]) => (
          <div key={l as string} className="card p-5"><p className="text-xs font-semibold uppercase tracking-wider text-ink-mute">{l}</p><p className="mt-2 font-display text-2xl text-forest-900">{v}</p></div>
        ))}
      </div>
      <div className="mt-8 grid gap-6 lg:grid-cols-3">
        <div className="card p-6 lg:col-span-2">
          <h2 className="font-display text-xl text-forest-900">Latest sales</h2>
          <table className="mt-4 w-full text-sm">
            <tbody>
              {recent.map((p) => (
                <tr key={p.id} className="border-b border-forest-900/5 last:border-0">
                  <td className="py-2.5">{p.profiles?.full_name || p.profiles?.email}</td>
                  <td className="py-2.5 text-ink-mute">{p.item_type.replace('_', ' ')}</td>
                  <td className="py-2.5 text-ink-mute">{new Date(p.created_at).toLocaleDateString('en-IN')}</td>
                  <td className="py-2.5 text-right font-semibold">{inr(p.amount)}</td>
                </tr>
              ))}
              {!recent.length && <tr><td className="py-4 text-ink-mute">No sales yet.</td></tr>}
            </tbody>
          </table>
        </div>
        <div className="card p-6">
          <h2 className="font-display text-xl text-forest-900">Quick actions</h2>
          <div className="mt-4 grid gap-2">
            <Link href="/admin/courses" className="btn-primary">+ New course</Link>
            <Link href="/admin/live" className="btn-ghost">Schedule live class</Link>
            <Link href="/admin/notifications" className="btn-ghost">Send announcement</Link>
            <Link href="/admin/coupons" className="btn-ghost">Create coupon</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
