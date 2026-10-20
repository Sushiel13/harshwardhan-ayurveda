import { getEbooks } from '@/lib/data';
import { EbookCard, Empty, PageHero } from '@/components/Cards';

export const dynamic = 'force-dynamic';
export const metadata = { title: 'eBooks' };

export default async function Ebooks() {
  const ebooks = await getEbooks();
  return (
    <>
      <PageHero eyebrow="Library" title="Concise eBooks for focused revision" text="Read securely in your browser or the app after purchase." />
      <div className="container-x py-12">
        <div className="grid grid-cols-2 gap-8 md:grid-cols-3 lg:grid-cols-5">{ebooks.map((e) => <EbookCard key={e.id} e={e} />)}</div>
        {ebooks.length === 0 && <Empty title="The library is being stocked" />}
      </div>
    </>
  );
}
