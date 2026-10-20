import { NextResponse } from 'next/server';
import { getUserFromRequest, supabaseAdmin } from '@/lib/supabase/server';
import { grantAccess, priceFor } from '@/lib/payments';

// Creates a Razorpay order. Used by both the website and the mobile app
// (the app sends `Authorization: Bearer <supabase access token>`).
export async function POST(req: Request) {
  try {
    const user = await getUserFromRequest(req);
    if (!user) return NextResponse.json({ error: 'Please log in' }, { status: 401 });
    const { itemType, itemId, coupon } = await req.json();
    const { item, amount, couponCode } = await priceFor(itemType, itemId, coupon);
    const sb = supabaseAdmin();

    // 100% coupon or free item → enrol directly
    if (item.is_free || amount <= 0) {
      await grantAccess({ user_id: user.id, item_type: itemType, item_id: itemId, amount: 0, coupon_code: couponCode });
      return NextResponse.json({ enrolled: true });
    }

    const auth = Buffer.from(`${process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID}:${process.env.RAZORPAY_KEY_SECRET}`).toString('base64');
    const r = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount: Math.round(amount * 100), currency: 'INR', receipt: `hia_${Date.now()}`,
        notes: { user_id: user.id, item_type: itemType, item_id: itemId },
      }),
    });
    const order = await r.json();
    if (!r.ok) return NextResponse.json({ error: order?.error?.description || 'Payment gateway error' }, { status: 502 });

    await sb.from('payments').insert({
      user_id: user.id, item_type: itemType, item_id: itemId, amount, coupon_code: couponCode,
      razorpay_order_id: order.id, status: 'created',
    });
    return NextResponse.json({ orderId: order.id, amount: order.amount, keyId: process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID, title: item.title });
  } catch (e: any) {
    return NextResponse.json({ error: e.message || 'Error' }, { status: 400 });
  }
}
