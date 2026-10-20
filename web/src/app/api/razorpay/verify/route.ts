import { NextResponse } from 'next/server';
import { getUserFromRequest, supabaseAdmin } from '@/lib/supabase/server';
import { grantAccess, verifySignature } from '@/lib/payments';

export async function POST(req: Request) {
  const user = await getUserFromRequest(req);
  if (!user) return NextResponse.json({ error: 'Please log in' }, { status: 401 });
  const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = await req.json();
  if (!verifySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }
  const sb = supabaseAdmin();
  const { data: p } = await sb.from('payments').select('*').eq('razorpay_order_id', razorpay_order_id).eq('user_id', user.id).single();
  if (!p) return NextResponse.json({ error: 'Order not found' }, { status: 404 });
  if (p.status !== 'paid') {
    await sb.from('payments').update({ status: 'paid', razorpay_payment_id }).eq('id', p.id);
    await grantAccess(p);
  }
  return NextResponse.json({ ok: true });
}
