import Link from 'next/link';
import { BookOpen, Clock, FileText, Sparkles } from 'lucide-react';
import type { Course, Ebook, TestSeries } from '@/lib/types';
import { discount, inr } from '@/lib/site';

export function Price({ price, mrp, free }: { price: number; mrp: number | null; free: boolean }) {
  if (free || Number(price) === 0) return <span className="font-display text-lg font-semibold text-forest-700">Free</span>;
  const off = discount(price, mrp);
  return (
    <span className="flex items-baseline gap-2">
      <span className="font-display text-xl font-semibold text-forest-900">{inr(price)}</span>
      {mrp && off > 0 && <span className="text-sm text-ink-mute line-through">{inr(mrp)}</span>}
      {off > 0 && <span className="text-xs font-bold text-clay-500">{off}% off</span>}
    </span>
  );
}

export function Cover({ src, title, tone = 'forest', icon = 'book' }: { src?: string | null; title: string; tone?: 'forest' | 'brass' | 'clay'; icon?: 'book' | 'test' | 'ebook' }) {
  if (src) return <img src={src} alt="" className="h-full w-full object-cover transition duration-500 group-hover:scale-[1.03]" />;
  const bg = tone === 'brass' ? 'from-brass-600 to-brass-700' : tone === 'clay' ? 'from-clay-500 to-[#8A4128]' : 'from-forest-700 to-forest-950';
  const Icon = icon === 'test' ? FileText : icon === 'ebook' ? BookOpen : Sparkles;
  return (
    <div className={`relative flex h-full w-full items-end bg-gradient-to-br ${bg} p-5`}>
      <svg className="absolute right-4 top-4 h-20 w-20 opacity-15" viewBox="0 0 100 100" aria-hidden>
        {[0, 30, 60, 90, 120, 150].map((r) => (
          <ellipse key={r} cx="50" cy="50" rx="12" ry="40" fill="none" stroke="#F8F4EB" strokeWidth="1.2" transform={`rotate(${r} 50 50)`} />
        ))}
      </svg>
      <Icon className="absolute left-5 top-5 text-brass-300" size={22} />
      <span className="relative font-display text-[19px] font-medium leading-snug text-ivory line-clamp-3">{title}</span>
    </div>
  );
}

export function CourseCard({ c }: { c: Course }) {
  return (
    <Link href={`/courses/${c.slug}`} className="group card flex flex-col overflow-hidden transition hover:-translate-y-1 hover:shadow-lift">
      <div className="aspect-[16/10] overflow-hidden"><Cover src={c.thumbnail_url} title={c.title} /></div>
      <div className="flex flex-1 flex-col p-5">
        <div className="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-ink-mute">
          <Clock size={12} /> {c.validity_days ? `${c.validity_days} days access` : 'Lifetime access'}
        </div>
        <h3 className="mt-2 font-display text-lg font-semibold leading-snug text-forest-900">{c.title}</h3>
        {c.subtitle && <p className="mt-1.5 text-sm text-ink-soft line-clamp-2">{c.subtitle}</p>}
        <div className="mt-auto flex items-center justify-between pt-5">
          <Price price={c.price} mrp={c.mrp} free={c.is_free} />
          <span className="text-sm font-semibold text-brass-600 group-hover:translate-x-0.5 transition">View →</span>
        </div>
      </div>
    </Link>
  );
}

export function SeriesCard({ s }: { s: TestSeries }) {
  return (
    <Link href={`/test-series/${s.id}`} className="group card flex flex-col overflow-hidden transition hover:-translate-y-1 hover:shadow-lift">
      <div className="aspect-[16/9] overflow-hidden"><Cover src={s.thumbnail_url} title={s.title} tone="brass" icon="test" /></div>
      <div className="flex flex-1 flex-col p-5">
        <p className="text-sm text-ink-soft line-clamp-2">{s.description}</p>
        <div className="mt-auto flex items-center justify-between pt-5">
          <Price price={s.price} mrp={s.mrp} free={s.is_free} />
          <span className="text-sm font-semibold text-brass-600">Open →</span>
        </div>
      </div>
    </Link>
  );
}

export function EbookCard({ e }: { e: Ebook }) {
  return (
    <Link href={`/ebooks/${e.id}`} className="group flex flex-col">
      <div className="aspect-[3/4] overflow-hidden rounded-xl shadow-lift"><Cover src={e.cover_url} title={e.title} tone="clay" icon="ebook" /></div>
      <h3 className="mt-4 font-display text-[17px] font-semibold leading-snug text-forest-900">{e.title}</h3>
      <p className="text-xs text-ink-mute">{e.author}</p>
      <div className="mt-2"><Price price={e.price} mrp={e.mrp} free={e.is_free} /></div>
    </Link>
  );
}

export function Empty({ title, text }: { title: string; text?: string }) {
  return (
    <div className="card flex flex-col items-center px-6 py-16 text-center">
      <Sparkles className="text-brass-500" />
      <h3 className="mt-3 font-display text-xl text-forest-900">{title}</h3>
      {text && <p className="mt-1 max-w-sm text-sm text-ink-soft">{text}</p>}
    </div>
  );
}

export function PageHero({ eyebrow, title, text }: { eyebrow: string; title: string; text?: string }) {
  return (
    <section className="border-b border-forest-900/[0.06] bg-gradient-to-b from-ivory-50 to-ivory">
      <div className="container-x py-14 md:py-20">
        <p className="eyebrow">{eyebrow}</p>
        <h1 className="mt-3 max-w-3xl font-display text-4xl font-medium leading-[1.08] tracking-tight text-forest-900 md:text-[52px]">{title}</h1>
        {text && <p className="mt-4 max-w-2xl text-[15.5px] leading-relaxed text-ink-soft">{text}</p>}
      </div>
    </section>
  );
}
