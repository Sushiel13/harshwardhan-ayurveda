import { supabaseServer } from './supabase/server';
import type { Category, Course, Ebook, TestSeries } from './types';

export const configured = () => !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
async function safe<T>(fn: () => Promise<T>, fallback: T): Promise<T> {
  if (!configured()) return fallback;
  try { return await fn(); } catch { return fallback; }
}

export async function getCategories(): Promise<Category[]> {
  return safe(async () => (await supabaseServer().from('categories').select('*').order('position')).data ?? [], []);
}
export async function getCourses(opts: { featured?: boolean; category?: string } = {}): Promise<Course[]> {
  return safe(async () => {
  let q = supabaseServer().from('courses').select('*').eq('is_published', true).order('created_at', { ascending: false });
  if (opts.featured) q = q.eq('is_featured', true);
  if (opts.category) q = q.eq('category_id', opts.category);
  const { data } = await q;
  return data ?? [];
  }, []);
}
export async function getEbooks(): Promise<Ebook[]> {
  return safe(async () => (await supabaseServer().from('ebooks').select('*').eq('is_published', true).order('created_at', { ascending: false })).data ?? [], []);
}
export async function getSeries(): Promise<TestSeries[]> {
  return safe(async () => (await supabaseServer().from('test_series').select('*').eq('is_published', true).order('created_at', { ascending: false })).data ?? [], []);
}
export async function getSessionProfile() {
  if (!configured()) return { user: null, profile: null };
  const sb = supabaseServer();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return { user: null, profile: null };
  const { data: profile } = await sb.from('profiles').select('*').eq('id', user.id).single();
  return { user, profile };
}
export async function getSiteSettings(): Promise<Record<string, string>> {
  return safe(async () => ((await supabaseServer().from('settings').select('value').eq('key', 'site').maybeSingle()).data?.value ?? {}) as Record<string, string>, {});
}
export async function getTestimonials(): Promise<{ id: string; name: string; detail: string | null; quote: string }[]> {
  return safe(async () => (await supabaseServer().from('testimonials').select('*').order('position')).data ?? [], []);
}
