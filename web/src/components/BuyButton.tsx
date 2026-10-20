'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2, Lock, Tag } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import type { ItemType } from '@/lib/types';
import { inr } from '@/lib/site';

declare global { interface Window { Razorpay: any } }

function loadRazorpay() {
  return new Promise<boolean>((resolve) => {
    if (window.Razorpay) return resolve(true);
    const s = document.createElement('script');
    s.src = 'https://checkout.razorpay.com/v1/checkout.js';
    s.onload = () => resolve(true);
    s.onerror = () => resolve(false);
    document.body.appendChild(s);
  });
}

export function BuyButton({ itemType, itemId, price, free, title, openHref }: {
  itemType: ItemType; itemId: string; price: number; free: boolean; title: string; openHref: string;
}) {
  const router = useRouter();
  const [owned, setOwned] = useState<boolean | null>(null);
  const [busy, setBusy] = useState(false);
  const [coupon, setCoupon] = useState('');
  const [showCoupon, setShowCoupon] = useState(false);
  const [msg, setMsg] = useState('');

  useEffect(() => {
    (async () => {
      const sb = supabaseBrowser();
      const { data: { user } } = await sb.auth.getUser();
      if (!user) return setOwned(false);
      const { data } = await sb.rpc('has_access', { p_type: itemType, p_id: itemId });
      const { data: p } = await sb.from('purchases').select('id').eq('user_id', user.id).eq('item_type', itemType).eq('item_id', itemId).maybeSingle();
      setOwned(!!p || (!!data && !free));
    })();
  }, [itemType, itemId, free]);

  async function go() {
    setMsg('');
    const sb = supabaseBrowser();
    const { data: { user } } = await sb.auth.getUser();
    if (!user) return router.push(`/login?next=${encodeURIComponent(location.pathname)}`);
    setBusy(true);
    try {
      if (free || Number(price) === 0) {
        const { error } = await sb.rpc('enroll_free', { p_type: itemType, p_id: itemId });
        if (error) throw error;
        router.push(openHref);
        return;
      }
      const res = await fetch('/api/razorpay/order', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemType, itemId, coupon: coupon.trim() || undefined }),
      });
      const order = await res.json();
      if (!res.ok) throw new Error(order.error || 'Could not start payment');
      if (order.enrolled) { router.push(openHref); return; }
      if (!(await loadRazorpay())) throw new Error('Payment gateway failed to load. Check your connection.');
      const { data: profile } = await sb.from('profiles').select('full_name, phone, email').eq('id', user.id).single();
      const rzp = new window.Razorpay({
        key: order.keyId,
        amount: order.amount,
        currency: 'INR',
        order_id: order.orderId,
        name: 'Harshwardhan Institute of Ayurveda',
        description: title,
        prefill: { name: profile?.full_name ?? '', email: profile?.email ?? user.email, contact: profile?.phone ?? '' },
        theme: { color: '#11302A' },
        handler: async (r: any) => {
          const v = await fetch('/api/razorpay/verify', {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(r),
          });
          if (v.ok) router.push(openHref);
          else setMsg('Payment received but verification failed. Contact support with your payment ID: ' + r.razorpay_payment_id);
        },
        modal: { ondismiss: () => setBusy(false) },
      });
      rzp.open();
    } catch (e: any) {
      setMsg(e.message || 'Something went wrong');
      setBusy(false);
    }
  }

  if (owned) return <a href={openHref} className="btn-primary w-full !py-3.5">Continue learning →</a>;

  return (
    <div className="space-y-3">
      <button onClick={go} disabled={busy || owned === null} className="btn-primary w-full !py-3.5 text-[15px]">
        {busy ? <Loader2 className="animate-spin" size={18} /> : !free && <Lock size={16} />}
        {free || Number(price) === 0 ? 'Enrol for free' : `Buy now · ${inr(price)}`}
      </button>
      {!free && Number(price) > 0 && (
        showCoupon ? (
          <div className="flex gap-2">
            <input className="input !py-2 uppercase" placeholder="Coupon code" value={coupon} onChange={(e) => setCoupon(e.target.value.toUpperCase())} />
          </div>
        ) : (
          <button onClick={() => setShowCoupon(true)} className="flex w-full items-center justify-center gap-1.5 text-xs font-semibold text-brass-600"><Tag size={13} /> Have a coupon?</button>
        )
      )}
      {msg && <p className="text-sm text-red-700">{msg}</p>}
    </div>
  );
}
