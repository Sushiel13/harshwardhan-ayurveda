import { getSeries } from '@/lib/data';
import { Empty, PageHero, SeriesCard } from '@/components/Cards';

export const dynamic = 'force-dynamic';
export const metadata = { title: 'Test Series' };

export default async function SeriesList() {
  const series = await getSeries();
  return (
    <>
      <PageHero eyebrow="Test series" title="Exam-grade practice with honest feedback" text="Timed tests, negative marking where the real exam has it, and explanations for every question." />
      <div className="container-x py-12">
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">{series.map((s) => <SeriesCard key={s.id} s={s} />)}</div>
        {series.length === 0 && <Empty title="Test series coming soon" />}
      </div>
    </>
  );
}
