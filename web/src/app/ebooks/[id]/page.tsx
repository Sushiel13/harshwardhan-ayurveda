import { notFound } from 'next/navigation';
import { supabaseServer } from '@/lib/supabase/server';
import { configured } from '@/lib/data';
import { BuyButton } from '@/components/BuyButton';
import { Cover, Price } from '@/components/Cards';
import { OpenEbook } from '@/components/OpenEbook';
import type { Ebook } from '@/lib/types';

export const dynamic = 'force-dynamic';

export default async function EbookPage({ params }: { params: { id: string } }) {
  if (!configured()) notFound();
  const sb = supabaseServer();
  const { data: e } = await sb.from('ebooks').select('*').eq('id', params.id).maybeSingle<Ebook>();
  if (!e) notFound();
  return (
    <div className="container-x grid gap-12 py-14 md:grid-cols-12">
      <div className="md:col-span-4"><div className="aspect-[3/4] overflow-hidden rounded-2xl shadow-lift"><Cover src={e.cover_url} title={e.title} tone="clay" icon="ebook" /></div></div>
      <div className="md:col-span-8">
        <p className="eyebrow">eBook</p>
        <h1 className="mt-3 font-display text-4xl text-forest-900 md:text-5xl">{e.title}</h1>
        <p className="mt-2 text-ink-mute">{e.author}</p>
        <p className="mt-6 max-w-2xl whitespace-pre-line leading-relaxed text-ink-soft">{e.description}</p>
        <div className="mt-8 max-w-sm space-y-3">
          <Price price={e.price} mrp={e.mrp} free={e.is_free} />
          <BuyButton itemType="ebook" itemId={e.id} price={e.price} free={e.is_free} title={e.title} openHref={`/ebooks/${e.id}`} />
          <OpenEbook path={e.file_path} />
        </div>
      </div>
    </div>
  );
}
