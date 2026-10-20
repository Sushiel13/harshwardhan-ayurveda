'use client';
import { useEffect, useState } from 'react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { inr } from '@/lib/site';

export default function Payments() {
  const [rows, setRows] = useState<any[]>([]);
  const [status, setStatus] = useState('paid');
  useEffect(() => {
    supabaseBrowser().from('payments').select('*, profiles(full_name,email,phone)').eq('status', status).order('created_at', { ascending: false }).limit(500)
      .then(({ data }: any) => setRows(data ?? []));
  }, [status]);
  const total = rows.reduce((a, r) => a + Number(r.amount), 0);
  function exportCsv() {
    const head = 'date,name,email,phone,item_type,amount,coupon,order_id,payment_id\n';
    const body = rows.map((r) => [new Date(r.created_at).toISOString(), r.profiles?.full_name, r.profiles?.email, r.profiles?.phone, r.item_type, r.amount, r.coupon_code, r.razorpay_order_id, r.razorpay_payment_id].map((v) => `"${v ?? ''}"`).join(',')).join('\n');
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([head + body], { type: 'text/csv' })); a.download = `payments-${status}.csv`; a.click();
  }
  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl text-forest-900">Payments</h1>
        <div className="flex gap-2">
          <select className="input !w-auto" value={status} onChange={(e) => setStatus(e.target.value)}><option value="paid">Paid</option><option value="created">Started (not paid)</option><option value="failed">Failed</option></select>
          <button className="btn-ghost" onClick={exportCsv}>Export CSV</button>
        </div>
      </div>
      <p className="mt-2 text-sm text-ink-mute">{rows.length} records · {inr(total)}</p>
      <div className="card mt-5 overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-forest-900/10 bg-ivory-50 text-xs uppercase tracking-wider text-ink-mute"><tr><th className="px-4 py-3">Date</th><th className="px-4 py-3">Student</th><th className="px-4 py-3">Item</th><th className="px-4 py-3">Coupon</th><th className="px-4 py-3">Payment ID</th><th className="px-4 py-3 text-right">Amount</th></tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id} className="border-b border-forest-900/5 last:border-0">
                <td className="px-4 py-3 text-ink-mute">{new Date(r.created_at).toLocaleString('en-IN')}</td>
                <td className="px-4 py-3">{r.profiles?.full_name}<br /><span className="text-xs text-ink-mute">{r.profiles?.email}</span></td>
                <td className="px-4 py-3">{r.item_type.replace('_', ' ')}</td>
                <td className="px-4 py-3">{r.coupon_code}</td>
                <td className="px-4 py-3 font-mono text-xs">{r.razorpay_payment_id}</td>
                <td className="px-4 py-3 text-right font-semibold">{inr(r.amount)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
