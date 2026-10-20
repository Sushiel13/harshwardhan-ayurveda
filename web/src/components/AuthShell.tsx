import Link from 'next/link';
import { Emblem } from './Logo';

export function AuthShell({ title, sub, children }: { title: string; sub: string; children: React.ReactNode }) {
  return (
    <div className="grid min-h-[calc(100vh-72px)] lg:grid-cols-2">
      <div className="relative hidden overflow-hidden bg-forest-900 lg:block">
        <div className="grain absolute inset-0" />
        <div className="relative flex h-full flex-col justify-between p-14 text-ivory">
          <Emblem className="h-14 w-14" />
          <div>
            <p className="font-display text-4xl leading-tight">“Swasthasya swasthya rakshanam, aturasya vikara prashamanam.”</p>
            <p className="mt-4 text-sm text-ivory/60">Preserve the health of the healthy; relieve the disease of the sick.</p>
          </div>
          <p className="text-xs text-ivory/40">Harshwardhan Institute of Ayurveda</p>
        </div>
      </div>
      <div className="flex items-center justify-center px-5 py-14">
        <div className="w-full max-w-md">
          <h1 className="font-display text-4xl text-forest-900">{title}</h1>
          <p className="mt-2 text-ink-soft">{sub}</p>
          <div className="mt-8">{children}</div>
          <p className="mt-8 text-center text-xs text-ink-mute">By continuing you agree to our <Link href="/policies/terms" className="underline">Terms</Link> and <Link href="/policies/privacy" className="underline">Privacy Policy</Link>.</p>
        </div>
      </div>
    </div>
  );
}
