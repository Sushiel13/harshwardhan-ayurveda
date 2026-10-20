import { Download, FileText } from 'lucide-react';
import { supabaseServer } from '@/lib/supabase/server';
import { configured } from '@/lib/data';
import { Empty, PageHero } from '@/components/Cards';
import type { Note } from '@/lib/types';

export const dynamic = 'force-dynamic';
export const metadata = { title: 'Free Notes' };

export default async function Notes() {
  let notes: Note[] = [];
  let base = '';
  if (configured()) {
    const sb = supabaseServer();
    notes = (await sb.from('notes').select('*').eq('is_published', true).order('created_at', { ascending: false })).data ?? [];
    base = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/media/`;
  }
  const subjects = Array.from(new Set(notes.map((n) => n.subject || 'General')));
  return (
    <>
      <PageHero eyebrow="Free notes" title="Notes we wish we had as students" text="Free to download — no purchase required." />
      <div className="container-x space-y-10 py-12">
        {subjects.map((s) => (
          <section key={s}>
            <h2 className="font-display text-2xl text-forest-900">{s}</h2>
            <div className="mt-4 grid gap-3 md:grid-cols-2">
              {notes.filter((n) => (n.subject || 'General') === s).map((n) => (
                <a key={n.id} href={base + n.file_path} target="_blank" className="card group flex items-center gap-4 p-4 transition hover:shadow-lift">
                  <span className="grid h-11 w-11 place-items-center rounded-xl bg-clay-500/10 text-clay-500"><FileText size={20} /></span>
                  <span className="flex-1"><span className="block font-semibold text-forest-900">{n.title}</span>{n.description && <span className="text-xs text-ink-mute">{n.description}</span>}</span>
                  <Download size={17} className="text-ink-mute group-hover:text-forest-800" />
                </a>
              ))}
            </div>
          </section>
        ))}
        {notes.length === 0 && <Empty title="Notes coming soon" />}
      </div>
    </>
  );
}
