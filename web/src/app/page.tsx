import Link from 'next/link';
import { ArrowRight, BookOpenCheck, CalendarClock, GraduationCap, Leaf, PlayCircle, ShieldCheck, Smartphone, Star, Target } from 'lucide-react';
import { getCategories, getCourses, getEbooks, getSeries, getTestimonials } from '@/lib/data';
import { CourseCard, EbookCard, SeriesCard } from '@/components/Cards';
import { site } from '@/lib/site';

export const dynamic = 'force-dynamic';

export default async function Home() {
  const [categories, featured, series, ebooks, testimonials] = await Promise.all([
    getCategories(), getCourses({ featured: true }), getSeries(), getEbooks(), getTestimonials(),
  ]);

  return (
    <>
      {/* ---------- HERO ---------- */}
      <section className="relative overflow-hidden">
        <div className="container-x grid items-center gap-12 pb-20 pt-10 md:pt-16 lg:grid-cols-12">
          <div className="lg:col-span-6">
            <span className="inline-flex items-center gap-2 rounded-full border border-brass-500/30 bg-white px-3.5 py-1.5 text-xs font-semibold text-forest-800">
              <Leaf size={13} className="text-brass-500" /> BAMS · AIAPGET · Government exams
            </span>
            <h1 className="mt-6 font-display text-[44px] font-medium leading-[1.02] tracking-tight text-forest-900 sm:text-6xl lg:text-[68px]">
              Learn Ayurveda <em className="font-normal italic text-brass-600">the way</em> it was meant to be taught.
            </h1>
            <p className="mt-6 max-w-xl text-[16.5px] leading-relaxed text-ink-soft">
              Structured video courses, exam-grade test series and clinical insight from experienced faculty — everything a BAMS student needs, from first professional to PG entrance.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link href="/courses" className="btn-primary !px-7 !py-3.5 text-[15px]">Explore courses <ArrowRight size={17} /></Link>
              <Link href="/test-series" className="btn-ghost !px-7 !py-3.5 text-[15px]"><Target size={17} /> Take a free test</Link>
            </div>
            <dl className="mt-12 grid max-w-lg grid-cols-3 gap-6 border-t border-forest-900/10 pt-8">
              {[['10k+', 'Learners'], ['500+', 'Video lectures'], ['4.8★', 'Student rating']].map(([v, l]) => (
                <div key={l}>
                  <dt className="font-display text-3xl font-semibold text-forest-900">{v}</dt>
                  <dd className="mt-1 text-xs font-medium uppercase tracking-wider text-ink-mute">{l}</dd>
                </div>
              ))}
            </dl>
          </div>

          {/* Hero visual: original composition, no stock imagery required */}
          <div className="relative lg:col-span-6">
            <div className="relative mx-auto aspect-[4/5] max-w-md overflow-hidden rounded-[2rem] bg-forest-900 shadow-lift lg:ml-auto">
              <div className="grain absolute inset-0" />
              <svg viewBox="0 0 400 500" className="absolute inset-0 h-full w-full" aria-hidden>
                <defs>
                  <radialGradient id="glow" cx="50%" cy="38%" r="60%">
                    <stop offset="0%" stopColor="#D2AA62" stopOpacity=".35" />
                    <stop offset="100%" stopColor="#D2AA62" stopOpacity="0" />
                  </radialGradient>
                </defs>
                <rect width="400" height="500" fill="url(#glow)" />
                <g transform="translate(200 190)" fill="none" stroke="#D2AA62" strokeOpacity=".55">
                  {Array.from({ length: 12 }).map((_, i) => (
                    <ellipse key={i} rx="26" ry="110" transform={`rotate(${i * 15})`} strokeWidth=".8" />
                  ))}
                  <circle r="128" strokeOpacity=".25" />
                  <circle r="150" strokeOpacity=".15" strokeDasharray="2 6" />
                </g>
                <g transform="translate(200 190)">
                  <path d="M0-46c-14 13-14 34 0 47 14-13 14-34 0-47Z" fill="#E2C48A" />
                  <path d="M-42-22c4 19 20 31 40 29-4-19-20-31-40-29Z" fill="#B8893B" />
                  <path d="M42-22c-4 19-20 31-40 29 4-19 20-31 40-29Z" fill="#B8893B" />
                </g>
              </svg>
              <div className="absolute inset-x-6 bottom-6 rounded-2xl bg-ivory/95 p-5 backdrop-blur">
                <p className="eyebrow">Now enrolling</p>
                <p className="mt-1 font-display text-xl font-semibold text-forest-900">AIAPGET 2027 Foundation Batch</p>
                <div className="mt-3 flex items-center justify-between text-sm text-ink-soft">
                  <span className="flex items-center gap-1.5"><CalendarClock size={15} className="text-brass-600" /> Live + recorded</span>
                  <Link href="/courses" className="font-semibold text-forest-800">Details →</Link>
                </div>
              </div>
            </div>
            <div className="absolute -left-2 top-10 hidden rounded-2xl bg-white p-4 shadow-lift sm:block">
              <div className="flex items-center gap-3">
                <span className="grid h-10 w-10 place-items-center rounded-full bg-forest-50 text-forest-700"><PlayCircle size={20} /></span>
                <div><p className="text-sm font-semibold text-forest-900">HD lectures</p><p className="text-xs text-ink-mute">Watch on web & app</p></div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ---------- EXAM PATHS ---------- */}
      {categories.length > 0 && (
        <section className="border-y border-forest-900/[0.06] bg-white">
          <div className="container-x py-12">
            <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
              <div><p className="eyebrow">Choose your path</p><h2 className="mt-2 font-display text-3xl text-forest-900">What are you preparing for?</h2></div>
              <Link href="/courses" className="text-sm font-semibold text-forest-800">All courses →</Link>
            </div>
            <div className="mt-8 grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-6">
              {categories.map((c, i) => (
                <Link key={c.id} href={`/courses?category=${c.slug}`}
                  className="group rounded-2xl border border-forest-900/10 bg-ivory-50 p-4 transition hover:border-brass-500 hover:bg-white">
                  <span className="font-display text-sm text-brass-600">0{i + 1}</span>
                  <p className="mt-6 text-[14px] font-semibold leading-snug text-forest-900">{c.name}</p>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ---------- FEATURED COURSES ---------- */}
      <section className="container-x py-20">
        <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
          <div>
            <p className="eyebrow">Flagship programmes</p>
            <h2 className="mt-2 max-w-xl font-display text-4xl leading-tight text-forest-900">Courses students recommend to their juniors</h2>
          </div>
          <Link href="/courses" className="btn-ghost">Browse all <ArrowRight size={16} /></Link>
        </div>
        <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {featured.slice(0, 4).map((c) => <CourseCard key={c.id} c={c} />)}
          {featured.length === 0 && <p className="text-ink-soft">Courses will appear here once published from the Admin panel.</p>}
        </div>
      </section>

      {/* ---------- WHY US ---------- */}
      <section className="relative overflow-hidden bg-forest-900 text-ivory">
        <div className="grain absolute inset-0 opacity-50" />
        <div className="container-x relative grid gap-14 py-20 lg:grid-cols-12">
          <div className="lg:col-span-5">
            <p className="eyebrow !text-brass-300">The Harshwardhan method</p>
            <h2 className="mt-3 font-display text-4xl leading-tight">Shastra-rooted. Exam-ready. Clinic-relevant.</h2>
            <p className="mt-5 text-ivory/70 leading-relaxed">
              We teach the classical texts with the respect they deserve, then show you exactly how they are tested and how they are practised. No shortcuts, no filler.
            </p>
          </div>
          <div className="grid gap-px overflow-hidden rounded-2xl bg-ivory/10 sm:grid-cols-2 lg:col-span-7">
            {[
              [BookOpenCheck, 'Syllabus-complete', 'Every NCISM topic, chapter by chapter, with downloadable notes.'],
              [Target, 'Real exam practice', 'Timed tests with negative marking and explained solutions.'],
              [GraduationCap, 'Experienced faculty', 'Taught by practising vaidyas and PG-qualified educators.'],
              [Smartphone, 'Learn anywhere', 'Same account on web and the mobile app — progress stays in sync.'],
            ].map(([Icon, t, d]) => {
              const I = Icon as typeof Leaf;
              return (
                <div key={t as string} className="bg-forest-900 p-7">
                  <I className="text-brass-400" size={24} />
                  <h3 className="mt-5 font-display text-xl">{t as string}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-ivory/65">{d as string}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ---------- TEST SERIES ---------- */}
      {series.length > 0 && (
        <section className="container-x py-20">
          <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
            <div><p className="eyebrow">Test series</p><h2 className="mt-2 font-display text-4xl text-forest-900">Practise under real exam pressure</h2></div>
            <Link href="/test-series" className="btn-ghost">All test series <ArrowRight size={16} /></Link>
          </div>
          <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {series.slice(0, 3).map((s) => <SeriesCard key={s.id} s={s} />)}
          </div>
        </section>
      )}

      {/* ---------- EBOOKS ---------- */}
      {ebooks.length > 0 && (
        <section className="bg-ivory-200/60">
          <div className="container-x py-20">
            <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
              <div><p className="eyebrow">Library</p><h2 className="mt-2 font-display text-4xl text-forest-900">eBooks for quick revision</h2></div>
              <Link href="/ebooks" className="btn-ghost">Visit library <ArrowRight size={16} /></Link>
            </div>
            <div className="mt-10 grid grid-cols-2 gap-6 md:grid-cols-4 lg:grid-cols-5">
              {ebooks.slice(0, 5).map((e) => <EbookCard key={e.id} e={e} />)}
            </div>
          </div>
        </section>
      )}

      {/* ---------- TESTIMONIALS ---------- */}
      {testimonials.length > 0 && (
        <section className="container-x py-20">
          <p className="eyebrow text-center">Student voices</p>
          <h2 className="mt-2 text-center font-display text-4xl text-forest-900">Results that speak quietly, but clearly</h2>
          <div className="mt-12 grid gap-6 md:grid-cols-3">
            {testimonials.map((t) => (
              <figure key={t.id} className="card p-7">
                <div className="flex gap-0.5 text-brass-500">{Array.from({ length: 5 }).map((_, i) => <Star key={i} size={14} fill="currentColor" />)}</div>
                <blockquote className="mt-4 font-display text-[17px] leading-relaxed text-forest-900">“{t.quote}”</blockquote>
                <figcaption className="mt-6 border-t border-forest-900/10 pt-4 text-sm">
                  <span className="font-semibold text-forest-900">{t.name}</span>
                  {t.detail && <span className="text-ink-mute"> · {t.detail}</span>}
                </figcaption>
              </figure>
            ))}
          </div>
        </section>
      )}

      {/* ---------- APP CTA ---------- */}
      <section className="container-x">
        <div className="relative overflow-hidden rounded-[2rem] bg-gradient-to-br from-brass-500 to-brass-600 px-8 py-14 md:px-14">
          <div className="relative grid items-center gap-8 md:grid-cols-2">
            <div>
              <p className="text-[11px] font-bold uppercase tracking-[0.22em] text-forest-900/70">Mobile app</p>
              <h2 className="mt-2 font-display text-4xl leading-tight text-forest-950">Your classroom, in your pocket.</h2>
              <p className="mt-3 max-w-md text-forest-950/75">Stream lectures, attempt tests and get class reminders on the {site.short} app.</p>
              <div className="mt-6 flex flex-wrap gap-3">
                <a href={site.playStoreUrl} className="btn bg-forest-950 text-ivory hover:bg-forest-800"><Smartphone size={16} /> Google Play</a>
                <a href={site.appStoreUrl} className="btn border border-forest-950/30 text-forest-950 hover:bg-forest-950/5">App Store</a>
              </div>
            </div>
            <ul className="space-y-3 text-forest-950">
              {['Same login as the website', 'Secure HD video streaming', 'Instant test results & solutions', 'Live class reminders'].map((f) => (
                <li key={f} className="flex items-center gap-3 rounded-xl bg-white/40 px-4 py-3 text-sm font-semibold"><ShieldCheck size={17} /> {f}</li>
              ))}
            </ul>
          </div>
        </div>
      </section>
    </>
  );
}
