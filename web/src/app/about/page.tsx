import Link from 'next/link';
import { PageHero } from '@/components/Cards';
import { site } from '@/lib/site';

export const metadata = { title: 'About' };

export default function About() {
  return (
    <>
      <PageHero eyebrow="About us" title={`About ${site.name}`} text="An online institute built by Ayurveda educators, for Ayurveda students." />
      <div className="container-x grid gap-12 py-14 lg:grid-cols-12">
        <div className="space-y-5 text-[16px] leading-relaxed text-ink-soft lg:col-span-7">
          <p>We started {site.name} with a simple belief: every BAMS student deserves clear, honest teaching — whether they study in a metro or a small town.</p>
          <p>Our courses follow the NCISM syllabus closely, connect the Samhitas to what you will actually see in practice, and prepare you thoroughly for university exams, AIAPGET and government recruitment.</p>
          <p>Everything you buy works on both the website and our mobile app with a single login.</p>
          <Link href="/courses" className="btn-primary mt-4">Explore courses</Link>
        </div>
        <div className="grid grid-cols-2 gap-4 lg:col-span-5">
          {[['Clarity', 'Concepts before cramming'], ['Integrity', 'No inflated promises'], ['Access', 'Fair pricing, lifetime notes'], ['Care', 'Doubts answered by teachers']].map(([t, d]) => (
            <div key={t} className="card p-6"><p className="font-display text-2xl text-forest-900">{t}</p><p className="mt-1 text-sm text-ink-soft">{d}</p></div>
          ))}
        </div>
      </div>
    </>
  );
}
