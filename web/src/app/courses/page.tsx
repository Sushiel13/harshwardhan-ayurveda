import Link from 'next/link';
import { getCategories, getCourses } from '@/lib/data';
import { CourseCard, Empty, PageHero } from '@/components/Cards';

export const dynamic = 'force-dynamic';
export const metadata = { title: 'Courses' };

export default async function CoursesPage({ searchParams }: { searchParams: { category?: string; type?: string } }) {
  const categories = await getCategories();
  const active = categories.find((c) => c.slug === searchParams.category);
  let courses = await getCourses({ category: active?.id });
  if (searchParams.type === 'free') courses = courses.filter((c) => c.is_free);
  if (searchParams.type === 'paid') courses = courses.filter((c) => !c.is_free);

  const pill = (href: string, label: string, on: boolean) => (
    <Link key={href} href={href} className={`whitespace-nowrap rounded-full px-4 py-2 text-sm font-medium transition ${on ? 'bg-forest-800 text-ivory' : 'bg-white text-ink-soft hover:text-forest-900 border border-forest-900/10'}`}>{label}</Link>
  );

  return (
    <>
      <PageHero eyebrow="Courses" title="Structured programmes for every stage of BAMS" text="Recorded lectures, notes and doubt support — learn at your pace on the web or the app." />
      <div className="container-x py-10">
        <div className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-2">
          {pill('/courses', 'All', !active && !searchParams.type)}
          {pill('/courses?type=free', 'Free', searchParams.type === 'free')}
          {categories.map((c) => pill(`/courses?category=${c.slug}`, c.name, active?.id === c.id))}
        </div>
        <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {courses.map((c) => <CourseCard key={c.id} c={c} />)}
        </div>
        {courses.length === 0 && <Empty title="No courses here yet" text="New courses are added regularly — check back soon." />}
      </div>
    </>
  );
}
