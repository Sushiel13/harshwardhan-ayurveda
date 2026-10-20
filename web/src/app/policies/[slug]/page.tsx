import { notFound } from 'next/navigation';
import { PageHero } from '@/components/Cards';
import { site } from '@/lib/site';

// Template policies — review with a legal adviser before going live.
const policies: Record<string, { title: string; body: string[] }> = {
  terms: { title: 'Terms & Conditions', body: [
    `By creating an account on ${site.name} you agree to use the platform for personal, non-commercial learning only.`,
    'Course videos, notes, tests and eBooks are licensed to the purchasing account. Sharing logins, screen-recording, downloading or redistributing content is prohibited and may lead to account suspension without refund.',
    'Access duration is shown on each product page. Access ends automatically after the validity period.',
    'We may update course content, schedules and these terms from time to time. Continued use means you accept the updated terms.',
  ]},
  privacy: { title: 'Privacy Policy', body: [
    'We collect your name, email, phone number and learning activity to provide the service, process payments and send class updates.',
    'Payments are processed by Razorpay; we never see or store your card or UPI credentials.',
    'We do not sell your personal data. You may request deletion of your account by contacting us.',
  ]},
  refund: { title: 'Refund Policy', body: [
    'Because digital content is accessible immediately after purchase, fees are generally non-refundable.',
    'If you were charged twice or could not access a product due to a technical fault on our side, contact us within 7 days with your payment ID and we will resolve it or refund in full.',
    'Approved refunds are returned to the original payment method within 5–7 working days.',
  ]},
};

export function generateStaticParams() { return Object.keys(policies).map((slug) => ({ slug })); }

export default function Policy({ params }: { params: { slug: string } }) {
  const p = policies[params.slug];
  if (!p) notFound();
  return (
    <>
      <PageHero eyebrow="Policies" title={p.title} />
      <div className="container-x max-w-3xl space-y-5 py-12 leading-relaxed text-ink-soft">
        {p.body.map((t, i) => <p key={i}>{t}</p>)}
        <p className="pt-4 text-sm">Questions? Email {site.contact.email}.</p>
      </div>
    </>
  );
}
