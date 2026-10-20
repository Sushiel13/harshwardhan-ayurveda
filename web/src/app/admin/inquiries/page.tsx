'use client';
import { useEffect, useState } from 'react';
import { Trash2 } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';

export default function Inquiries() {
  const sb = supabaseBrowser();
  const [rows, setRows] = useState<any[]>([]);
  const load = () => sb.from('inquiries').select('*').order('created_at', { ascending: false }).then(({ data }: any) => setRows(data ?? []));
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { load(); }, []);
  return (
    <div>
      <h1 className="font-display text-3xl text-forest-900">Inquiries</h1>
      <div className="mt-6 space-y-3">
        {rows.map((r) => (
          <div key={r.id} className="card p-5">
            <div className="flex justify-between gap-3">
              <div><p className="font-semibold text-forest-900">{r.name}</p><p className="text-xs text-ink-mute">{r.email} · {r.phone} · {new Date(r.created_at).toLocaleString('en-IN')}</p></div>
              <div className="flex items-start gap-2">
                {r.phone && <a href={`https://wa.me/${String(r.phone).replace(/\D/g, '')}`} target="_blank" className="btn-ghost !py-1.5 text-xs">WhatsApp</a>}
                <button onClick={async () => { if (confirm('Delete?')) { await sb.from('inquiries').delete().eq('id', r.id); load(); } }} className="p-2 text-ink-mute hover:text-red-700"><Trash2 size={15} /></button>
              </div>
            </div>
            <p className="mt-3 whitespace-pre-line text-sm text-ink-soft">{r.message}</p>
          </div>
        ))}
        {!rows.length && <p className="card p-8 text-center text-ink-mute">No inquiries yet.</p>}
      </div>
    </div>
  );
}
