'use client';
import { useCallback, useEffect, useState } from 'react';
import { Gift, Loader2, Search, ShieldCheck, Ban, X } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import type { Profile } from '@/lib/types';

export default function Students() {
  const sb = supabaseBrowser();
  const [rows, setRows] = useState<Profile[]>([]);
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(true);
  const [sel, setSel] = useState<Profile | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    let query = sb.from('profiles').select('*').order('created_at', { ascending: false }).limit(200);
    if (q) query = query.or(`full_name.ilike.%${q}%,email.ilike.%${q}%,phone.ilike.%${q}%`);
    const { data } = await query;
    setRows(data ?? []); setLoading(false);
  }, [sb, q]);
  useEffect(() => { const t = setTimeout(load, 300); return () => clearTimeout(t); }, [load]);

  async function toggle(p: Profile, field: 'is_blocked' | 'role') {
    const v = field === 'role' ? (p.role === 'admin' ? 'student' : 'admin') : !p.is_blocked;
    if (!confirm(field === 'role' ? `Make ${p.full_name || p.email} ${v}?` : `${v ? 'Block' : 'Unblock'} ${p.full_name || p.email}?`)) return;
    const { error } = await sb.from('profiles').update({ [field]: v }).eq('id', p.id);
    if (error) alert(error.message); else load();
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-forest-900">Students</h1>
      <div className="relative mt-6 max-w-md"><Search size={16} className="absolute left-3.5 top-3 text-ink-mute" /><input className="input !pl-10" placeholder="Search name, email or phone" value={q} onChange={(e) => setQ(e.target.value)} /></div>
      <div className="card mt-5 overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-forest-900/10 bg-ivory-50 text-xs uppercase tracking-wider text-ink-mute"><tr><th className="px-4 py-3">Name</th><th className="px-4 py-3">Contact</th><th className="px-4 py-3">Joined</th><th className="px-4 py-3">Role</th><th /></tr></thead>
          <tbody>
            {loading ? <tr><td className="p-6"><Loader2 className="animate-spin" /></td></tr> : rows.map((p) => (
              <tr key={p.id} className="border-b border-forest-900/5 last:border-0">
                <td className="px-4 py-3 font-semibold text-forest-900">{p.full_name || '—'} {p.is_blocked && <span className="chip !bg-red-50 !text-red-700">blocked</span>}</td>
                <td className="px-4 py-3 text-ink-soft">{p.email}<br /><span className="text-xs">{p.phone}</span></td>
                <td className="px-4 py-3 text-ink-mute">{new Date(p.created_at).toLocaleDateString('en-IN')}</td>
                <td className="px-4 py-3">{p.role === 'admin' ? <span className="chip">admin</span> : 'student'}</td>
                <td className="whitespace-nowrap px-4 py-3 text-right">
                  <button title="Grant access" onClick={() => setSel(p)} className="p-2 text-ink-mute hover:text-forest-800"><Gift size={15} /></button>
                  <button title="Toggle admin" onClick={() => toggle(p, 'role')} className="p-2 text-ink-mute hover:text-forest-800"><ShieldCheck size={15} /></button>
                  <button title="Block / unblock" onClick={() => toggle(p, 'is_blocked')} className="p-2 text-ink-mute hover:text-red-700"><Ban size={15} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {sel && <Grant p={sel} close={() => setSel(null)} />}
    </div>
  );
}

function Grant({ p, close }: { p: Profile; close: () => void }) {
  const sb = supabaseBrowser();
  const [items, setItems] = useState<{ type: string; id: string; title: string }[]>([]);
  const [owned, setOwned] = useState<any[]>([]);
  const [pick, setPick] = useState('');
  const load = useCallback(async () => {
    const [c, e, t, o] = await Promise.all([
      sb.from('courses').select('id,title'), sb.from('ebooks').select('id,title'), sb.from('test_series').select('id,title'),
      sb.from('purchases').select('*').eq('user_id', p.id),
    ]);
    setItems([...(c.data ?? []).map((x: any) => ({ type: 'course', ...x })), ...(e.data ?? []).map((x: any) => ({ type: 'ebook', ...x })), ...(t.data ?? []).map((x: any) => ({ type: 'test_series', ...x }))]);
    setOwned(o.data ?? []);
  }, [sb, p.id]);
  useEffect(() => { load(); }, [load]);
  const name = (o: any) => items.find((i) => i.id === o.item_id)?.title ?? o.item_id;
  async function grant() {
    const [type, id] = pick.split('|');
    if (!id) return;
    const { error } = await sb.from('purchases').upsert({ user_id: p.id, item_type: type, item_id: id, amount: 0, source: 'admin' }, { onConflict: 'user_id,item_type,item_id' });
    if (error) alert(error.message); else { setPick(''); load(); }
  }
  async function revoke(o: any) {
    if (confirm('Remove this access?')) { await sb.from('purchases').delete().eq('id', o.id); load(); }
  }
  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-forest-950/40" onClick={close}>
      <div className="h-full w-full max-w-lg overflow-y-auto bg-ivory p-6" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between"><h2 className="font-display text-xl">{p.full_name || p.email}</h2><button onClick={close}><X /></button></div>
        <h3 className="label mt-6">Current access</h3>
        <ul className="space-y-2">
          {owned.map((o) => <li key={o.id} className="card flex items-center justify-between p-3 text-sm"><span>{name(o)} <span className="text-xs text-ink-mute">· {o.source}{o.expires_at ? ` · till ${new Date(o.expires_at).toLocaleDateString('en-IN')}` : ''}</span></span><button onClick={() => revoke(o)} className="text-xs text-red-700">Remove</button></li>)}
          {!owned.length && <li className="text-sm text-ink-mute">None</li>}
        </ul>
        <h3 className="label mt-6">Give free access</h3>
        <div className="flex gap-2">
          <select className="input" value={pick} onChange={(e) => setPick(e.target.value)}>
            <option value="">Choose…</option>
            {items.map((i) => <option key={i.id} value={`${i.type}|${i.id}`}>{i.type.replace('_', ' ')} — {i.title}</option>)}
          </select>
          <button className="btn-primary" onClick={grant}>Grant</button>
        </div>
      </div>
    </div>
  );
}
