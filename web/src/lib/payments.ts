import crypto from 'crypto';
import { supabaseAdmin } from './supabase/server';

const TABLE: Record<string, string> = { course: 'courses', ebook: 'ebooks', test_series: 'test_series' };

export async function priceFor(itemType: string, itemId: string, coupon?: string) {
  const table = TABLE[itemType];
  if (!table) throw new Error('Invalid item');
  const sb = supabaseAdmin();
  const { data: item } = await sb.from(table).select('id, title, price, is_free, is_published, validity_days').eq('id', itemId).single();
  if (!item || !item.is_published) throw new Error('Item not available');
  let amount = Number(item.price);
  let couponCode: string | null = null;
  if (coupon) {
    const { data: c } = await sb.from('coupons').select('*').eq('code', coupon.toUpperCase()).eq('is_active', true).maybeSingle();
    if (!c || (c.expires_at && new Date(c.expires_at) < new Date()) || (c.max_uses && c.used_count >= c.max_uses)) throw new Error('Invalid or expired coupon');
    amount = Math.round(amount * (100 - c.discount_percent)) / 100;
    couponCode = c.code;
  }
  return { item, amount, couponCode };
}

export async function grantAccess(paymentRow: { user_id: string; item_type: string; item_id: string; amount: number; coupon_code: string | null }) {
  const sb = supabaseAdmin();
  const table = TABLE[paymentRow.item_type];
  const { data: item } = await sb.from(table).select('validity_days').eq('id', paymentRow.item_id).single();
  const expires = item?.validity_days ? new Date(Date.now() + item.validity_days * 86400_000).toISOString() : null;
  await sb.from('purchases').upsert({
    user_id: paymentRow.user_id, item_type: paymentRow.item_type, item_id: paymentRow.item_id,
    amount: paymentRow.amount, source: 'razorpay', expires_at: expires,
  }, { onConflict: 'user_id,item_type,item_id' });
  if (paymentRow.coupon_code) {
    const { data: c } = await sb.from('coupons').select('used_count').eq('code', paymentRow.coupon_code).single();
    if (c) await sb.from('coupons').update({ used_count: c.used_count + 1 }).eq('code', paymentRow.coupon_code);
  }
}

export function verifySignature(orderId: string, paymentId: string, signature: string) {
  const expected = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET!).update(`${orderId}|${paymentId}`).digest('hex');
  return safeEqual(expected, signature);
}
export function verifyWebhook(body: string, signature: string) {
  const expected = crypto.createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET!).update(body).digest('hex');
  return safeEqual(expected, signature);
}
function safeEqual(a: string, b: string) {
  const x = Buffer.from(a), y = Buffer.from(b || '');
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}
