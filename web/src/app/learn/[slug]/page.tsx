'use client';
import { useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { ArrowLeft, CheckCircle2, Circle, Download, FileText, Loader2, Lock, PlayCircle } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { embedUrl } from '@/lib/video';
import { Logo } from '@/components/Logo';
import type { Course, Lesson, Section } from '@/lib/types';

export default function LearnPage({ params }: { params: { slug: string } }) {
  const sb = supabaseBrowser();
  const search = useSearchParams();
  const [course, setCourse] = useState<Course | null>(null);
  const [sections, setSections] = useState<Section[]>([]);
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [access, setAccess] = useState(false);
  const [done, setDone] = useState<Set<string>>(new Set());
  const [current, setCurrent] = useState<string | null>(null);
  const [media, setMedia] = useState<{ video?: string; embed?: string; pdf?: string } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const { data: c } = await sb.from('courses').select('*').eq('slug', params.slug).single();
      if (!c) return setLoading(false);
      setCourse(c);
      const [{ data: s }, { data: l }, { data: a }, { data: p }] = await Promise.all([
        sb.from('course_sections').select('*').eq('course_id', c.id).order('position'),
        sb.from('lessons').select('*').eq('course_id', c.id).order('position'),
        sb.rpc('has_access', { p_type: 'course', p_id: c.id }),
        sb.from('lesson_progress').select('lesson_id'),
      ]);
      setSections(s ?? []); setLessons(l ?? []); setAccess(!!a);
      setDone(new Set((p ?? []).map((x: any) => x.lesson_id)));
      const first = search.get('lesson') || (l ?? []).find((x: Lesson) => a || x.is_preview)?.id || null;
      setCurrent(first);
      setLoading(false);
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.slug]);

  const load = useCallback(async (id: string) => {
    setMedia(null);
    const { data } = await sb.rpc('get_lesson_media', { p_lesson: id });
    const m = Array.isArray(data) ? data[0] : data;
    if (!m) return setMedia({});
    const out: { video?: string; embed?: string; pdf?: string } = {};
    if (m.video_path) {
      const { data: s } = await sb.storage.from('content').createSignedUrl(m.video_path, 60 * 60 * 3);
      out.video = s?.signedUrl;
    } else if (m.video_url) {
      const e = embedUrl(m.video_url);
      if (e) out.embed = e; else out.video = m.video_url;
    }
    if (m.pdf_path) {
      const { data: s } = await sb.storage.from('content').createSignedUrl(m.pdf_path, 60 * 60);
      out.pdf = s?.signedUrl;
    }
    setMedia(out);
  }, [sb]);

  useEffect(() => { if (current) load(current); }, [current, load]);

  const lesson = lessons.find((l) => l.id === current);
  const groups = useMemo(() => {
    const g = sections.map((s) => ({ id: s.id, title: s.title, items: lessons.filter((l) => l.section_id === s.id) }));
    const rest = lessons.filter((l) => !l.section_id || !sections.find((s) => s.id === l.section_id));
    if (rest.length) g.push({ id: 'rest', title: sections.length ? 'More lessons' : 'Lessons', items: rest });
    return g.filter((x) => x.items.length);
  }, [sections, lessons]);

  async function toggleDone() {
    if (!lesson) return;
    const { data: { user } } = await sb.auth.getUser();
    if (!user) return;
    const n = new Set(done);
    if (n.has(lesson.id)) { await sb.from('lesson_progress').delete().eq('lesson_id', lesson.id); n.delete(lesson.id); }
    else { await sb.from('lesson_progress').upsert({ user_id: user.id, lesson_id: lesson.id }); n.add(lesson.id); }
    setDone(n);
  }

  if (loading) return <div className="grid h-screen place-items-center"><Loader2 className="animate-spin text-forest-700" /></div>;
  if (!course) return <div className="container-x py-24 text-center">Course not found.</div>;
  const progress = lessons.length ? Math.round((lessons.filter((l) => done.has(l.id)).length / lessons.length) * 100) : 0;

  return (
    <div className="flex min-h-screen flex-col bg-forest-950 text-ivory lg:flex-row">
      <div className="flex-1">
        <div className="flex items-center justify-between border-b border-ivory/10 px-5 py-3">
          <Link href="/dashboard" className="flex items-center gap-2 text-sm text-ivory/70 hover:text-ivory"><ArrowLeft size={16} /> My learning</Link>
          <span className="hidden sm:block"><Logo light /></span>
        </div>
        <div className="aspect-video w-full bg-black">
          {!lesson ? <Center text={access ? 'Select a lesson' : 'Enrol to unlock this course'} />
            : media === null ? <Center spin />
            : media.embed ? <iframe src={media.embed} className="h-full w-full" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowFullScreen />
            : media.video ? <video key={media.video} src={media.video} controls controlsList="nodownload" onContextMenu={(e) => e.preventDefault()} className="h-full w-full" />
            : lesson.kind === 'pdf' && media.pdf ? <Center text="This lesson is a PDF — open it below." />
            : <Center text="This lesson is locked." lock />}
        </div>
        {lesson && (
          <div className="px-5 py-6 md:px-8">
            <div className="flex flex-col justify-between gap-4 md:flex-row md:items-start">
              <div>
                <h1 className="font-display text-2xl">{lesson.title}</h1>
                {lesson.description && <p className="mt-2 max-w-2xl text-sm text-ivory/65 whitespace-pre-line">{lesson.description}</p>}
              </div>
              <div className="flex shrink-0 gap-2">
                {media?.pdf && <a href={media.pdf} target="_blank" className="btn border border-ivory/20 text-ivory hover:bg-ivory/10"><Download size={15} /> Notes PDF</a>}
                {access && <button onClick={toggleDone} className="btn-gold">{done.has(lesson.id) ? <><CheckCircle2 size={15} /> Completed</> : 'Mark complete'}</button>}
              </div>
            </div>
          </div>
        )}
      </div>

      <aside className="w-full border-l border-ivory/10 bg-forest-900 lg:w-[380px] lg:overflow-y-auto lg:max-h-screen">
        <div className="border-b border-ivory/10 p-5">
          <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-brass-300">Course content</p>
          <h2 className="mt-1 font-display text-lg leading-snug">{course.title}</h2>
          {access && (
            <div className="mt-3">
              <div className="h-1.5 overflow-hidden rounded-full bg-ivory/10"><div className="h-full bg-brass-400" style={{ width: `${progress}%` }} /></div>
              <p className="mt-1.5 text-xs text-ivory/55">{progress}% complete</p>
            </div>
          )}
          {!access && <Link href={`/courses/${course.slug}`} className="btn-gold mt-4 w-full">Unlock full course</Link>}
        </div>
        {groups.map((g) => (
          <div key={g.id}>
            <p className="bg-forest-950/40 px-5 py-2.5 text-xs font-semibold uppercase tracking-wider text-ivory/50">{g.title}</p>
            {g.items.map((l) => {
              const can = access || l.is_preview;
              return (
                <button key={l.id} disabled={!can} onClick={() => setCurrent(l.id)}
                  className={`flex w-full items-start gap-3 px-5 py-3.5 text-left text-sm transition ${current === l.id ? 'bg-ivory/10' : 'hover:bg-ivory/5'} disabled:opacity-45`}>
                  <span className="mt-0.5">{done.has(l.id) ? <CheckCircle2 size={16} className="text-brass-400" /> : !can ? <Lock size={15} /> : l.kind === 'pdf' ? <FileText size={16} /> : current === l.id ? <PlayCircle size={16} className="text-brass-300" /> : <Circle size={16} className="text-ivory/40" />}</span>
                  <span className="flex-1">{l.title}{l.duration_minutes ? <span className="block text-xs text-ivory/45">{l.duration_minutes} min</span> : null}</span>
                  {l.is_preview && !access && <span className="rounded bg-brass-500/20 px-1.5 py-0.5 text-[10px] font-bold text-brass-300">PREVIEW</span>}
                </button>
              );
            })}
          </div>
        ))}
      </aside>
    </div>
  );
}

function Center({ text, spin, lock }: { text?: string; spin?: boolean; lock?: boolean }) {
  return (
    <div className="grid h-full place-items-center text-ivory/60">
      <div className="flex flex-col items-center gap-3 text-sm">{spin ? <Loader2 className="animate-spin" /> : lock ? <Lock /> : <PlayCircle />}{text}</div>
    </div>
  );
}
