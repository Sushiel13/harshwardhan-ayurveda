import Link from 'next/link';
export default function NotFound() {
  return (
    <div className="container-x py-28 text-center">
      <p className="eyebrow">404</p>
      <h1 className="mt-3 font-display text-5xl text-forest-900">This page wandered off</h1>
      <Link href="/" className="btn-primary mt-8">Back home</Link>
    </div>
  );
}
