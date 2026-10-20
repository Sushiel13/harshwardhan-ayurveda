'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Mail, MapPin, Phone } from 'lucide-react';
import { Logo } from './Logo';
import { site } from '@/lib/site';

export function Footer() {
  const pathname = usePathname();
  if (pathname.startsWith('/admin') || pathname.startsWith('/learn') || pathname.startsWith('/test/')) return null;
  return (
    <footer className="relative mt-24 overflow-hidden bg-forest-950 text-ivory/80">
      <div className="grain absolute inset-0 opacity-40" />
      <div className="container-x relative grid gap-12 py-16 md:grid-cols-12">
        <div className="md:col-span-4">
          <Logo light />
          <p className="mt-5 max-w-xs text-sm leading-relaxed text-ivory/60">
            Rigorous, compassionate teaching for BAMS students and Ayurveda aspirants — from the first shloka to the PG entrance.
          </p>
          <div className="mt-6 flex gap-3">
            <a href={site.playStoreUrl} className="rounded-lg border border-ivory/15 px-3.5 py-2 text-xs hover:border-brass-400">Get it on Google Play</a>
            <a href={site.appStoreUrl} className="rounded-lg border border-ivory/15 px-3.5 py-2 text-xs hover:border-brass-400">App Store</a>
          </div>
        </div>
        <FooterCol title="Learn" links={[['/courses','All courses'],['/test-series','Test series'],['/ebooks','eBooks'],['/notes','Free notes'],['/live','Live classes']]} />
        <FooterCol title="Institute" links={[['/about','About us'],['/contact','Contact'],['/signup','Create account'],['/login','Student login']]} />
        <FooterCol title="Policies" links={[['/policies/terms','Terms & conditions'],['/policies/privacy','Privacy policy'],['/policies/refund','Refund policy']]} />
        <div className="md:col-span-2">
          <h4 className="eyebrow !text-brass-300">Reach us</h4>
          <ul className="mt-4 space-y-3 text-sm">
            <li className="flex gap-2"><Phone size={15} className="mt-0.5 text-brass-400" /> {site.contact.phone}</li>
            <li className="flex gap-2"><Mail size={15} className="mt-0.5 text-brass-400" /> <span className="break-all">{site.contact.email}</span></li>
            <li className="flex gap-2"><MapPin size={15} className="mt-0.5 text-brass-400" /> {site.contact.address}</li>
          </ul>
        </div>
      </div>
      <div className="relative border-t border-ivory/10">
        <div className="container-x flex flex-col gap-2 py-6 text-xs text-ivory/45 sm:flex-row sm:justify-between">
          <span>© {new Date().getFullYear()} {site.name}. All rights reserved.</span>
          <span>Made with care in India</span>
        </div>
      </div>
    </footer>
  );
}

function FooterCol({ title, links }: { title: string; links: [string, string][] }) {
  return (
    <div className="md:col-span-2">
      <h4 className="eyebrow !text-brass-300">{title}</h4>
      <ul className="mt-4 space-y-2.5 text-sm">
        {links.map(([href, label]) => (
          <li key={href}><Link href={href} className="hover:text-brass-300">{label}</Link></li>
        ))}
      </ul>
    </div>
  );
}
