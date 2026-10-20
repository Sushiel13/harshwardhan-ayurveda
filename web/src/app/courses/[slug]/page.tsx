import { notFound } from 'next/navigation';
import { CheckCircle2, Clock, FileText, Globe, Lock, PlayCircle, UserRound } from 'lucide-react';
import { supabaseServer } from '@/lib/supabase/server';
import { configured } from '@/lib/data';
import { BuyButton } from '@/components/BuyButton';
import { Cover, Price } from '@/components/Cards';
import type { Course, Lesson, Section } from '@/lib/types';

export const dynamic = 'force-dynamic';

export default async function CoursePage({ params }: { params: { slug: string } }) {
  if (!configured()) notFound();
  const sb = supabaseServer();
  const { data: course } = await sb.from('courses').select('*').eq('slug', params.slug).maybeSingle<Course>();
  if (!course) notFound();
  const [{ data: sections }, { data: lessons }] = await Promise.all([
    sb.from('course_sections').select('*').eq('course_id', course.id).order('position'),
    sb.from('lessons').select('id,title,kind,duration_minutes,is_preview,section_id,position').eq('course_id', course.id).order('position'),
  ]);
  const ls = (lessons ?? []) as Lesson[];
  const secs = (sections ?? []) as Section[];
  const groups = [...secs.map((s) => ({ title: s.title, items: ls.filter((l) => l.section_id === s.id) })),
    { title: secs.length ? 'More lessons' : 'Lessons', items: ls.filter((l) => !l.section_id || !secs.find((s) => s.id === l.section_id)) }]
    .filter((g) => g.items.length);
  const totalMin = ls.reduce((a, l) => a + (l.duration_minutes ?? 0), 0);

  return (
    <div className="bg-gradient-to-b from-ivory-50 to-ivory">
      <div className="container-x grid gap-10 py-12 lg:grid-cols-12">
        <div className="lg:col-span-8">
          <p className="eyebrow">Course</p>
          <h1 className="mt-3 font-display text-4xl font-medium leading-tight text-forest-900 md:text-5xl">{course.title}</h1>
          {course.subtitle && <p className="mt-4 text-lg text-ink-soft">{course.subtitle}</p>}
          <div className="mt-6 flex flex-wrap gap-x-6 gap-y-2 text-sm text-ink-soft">
            <span className="flex items-center gap-1.5"><UserRound size={15} /> {course.instructor}</span>
            <span className="flex items-center gap-1.5"><Globe size={15} /> {course.language}</span>
            <span className="flex items-center gap-1.5"><PlayCircle size={15} /> {ls.length} lessons{totalMin ? ` · ${Math.round(totalMin / 60)}h ${totalMin % 60}m` : ''}</span>
            <span className="flex items-center gap-1.5"><Clock size={15} /> {course.validity_days ? `${course.validity_days} days access` : 'Lifetime access'}</span>
          </div>

          <div className="mt-10 card p-7">
            <h2 className="font-display text-2xl text-forest-900">About this course</h2>
            <p className="mt-3 whitespace-pre-line leading-relaxed text-ink-soft">{course.description}</p>
          </div>

          <div className="mt-8">
            <h2 className="font-display text-2xl text-forest-900">Curriculum</h2>
            <div className="mt-4 space-y-4">
              {groups.map((g) => (
                <div key={g.title} className="card overflow-hidden">
                  <div className="border-b border-forest-900/5 bg-ivory-50 px-5 py-3.5 text-sm font-semibold text-forest-900">{g.title} <span className="font-normal text-ink-mute">· {g.items.length}</span></div>
                  <ul>
                    {g.items.map((l) => (
                      <li key={l.id} className="flex items-center justify-between gap-3 border-b border-forest-900/5 px-5 py-3.5 text-sm last:border-0">
                        <span className="flex items-center gap-3 text-forest-900">
                          {l.kind === 'pdf' ? <FileText size={16} className="text-brass-600" /> : <PlayCircle size={16} className="text-brass-600" />}
                          {l.title}
                        </span>
                        <span className="flex shrink-0 items-center gap-3 text-xs text-ink-mute">
                          {l.duration_minutes ? `${l.duration_minutes} min` : ''}
                          {l.is_preview ? <a href={`/learn/${course.slug}?lesson=${l.id}`} className="chip">Preview</a> : <Lock size={13} />}
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
              {groups.length === 0 && <p className="text-sm text-ink-soft">Lessons are being uploaded.</p>}
            </div>
          </div>
        </div>

        <aside className="lg:col-span-4">
          <div className="card sticky top-24 overflow-hidden">
            <div className="aspect-[16/10]"><Cover src={course.thumbnail_url} title={course.title} /></div>
            <div className="p-6">
              <Price price={course.price} mrp={course.mrp} free={course.is_free} />
              <div className="mt-5">
                <BuyButton itemType="course" itemId={course.id} price={course.price} free={course.is_free} title={course.title} openHref={`/learn/${course.slug}`} />
              </div>
              <ul className="mt-6 space-y-2.5 text-sm text-ink-soft">
                {['HD video lectures', 'Downloadable notes', 'Watch on web & mobile app', 'Secure payment via Razorpay'].map((f) => (
                  <li key={f} className="flex items-center gap-2"><CheckCircle2 size={15} className="text-forest-500" /> {f}</li>
                ))}
              </ul>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
