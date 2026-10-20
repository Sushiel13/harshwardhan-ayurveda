import { NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase/server';
import { grantAccess, verifyWebhook } from '@/lib/payments';

// Safety net: if a student closes the browser before /verify runs, Razorpay
// still calls this webhook and access is granted. Configure in Razorpay
// Dashboard → Webhooks → URL: https://YOUR-DOMAIN/api/razorpay/webhook, event: payment.captured
export async function POST(req: Request) {
  const body = await req.text();
  if (!verifyWebhook(body, req.headers.get('x-razorpay-signature') || '')) {
    return NextResponse.json({ error: 'bad signature' }, { status: 400 });
  }
  const evt = JSON.parse(body);
  if (evt.event === 'payment.captured' || evt.event === 'order.paid') {
    const pay = evt.payload.payment.entity;
    const sb = supabaseAdmin();
    const { data: p } = await sb.from('payments').select('*').eq('razorpay_order_id', pay.order_id).single();
    if (p && p.status !== 'paid') {
      await sb.from('payments').update({ status: 'paid', razorpay_payment_id: pay.id }).eq('id', p.id);
      await grantAccess(p);
    }
  }
  return NextResponse.json({ ok: true });
}
