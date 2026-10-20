'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import { BarChart3, Bell, BookOpen, CreditCard, ExternalLink, FileText, GraduationCap, Inbox, ListChecks, LogOut, Menu, Radio, Settings, Ticket, Users } from 'lucide-react';
import { Logo } from '../Logo';
import { SignOut } from '../SignOut';

const items = [
  ['/admin', 'Overview', BarChart3], ['/admin/courses', 'Courses & videos', GraduationCap],
  ['/admin/test-series', 'Test series', ListChecks], ['/admin/ebooks', 'eBooks', BookOpen],
  ['/admin/notes', 'Free notes', FileText], ['/admin/live', 'Live classes', Radio],
  ['/admin/notifications', 'Announcements', Bell], ['/admin/coupons', 'Coupons', Ticket],
  ['/admin/students', 'Students', Users], ['/admin/payments', 'Payments', CreditCard],
  ['/admin/inquiries', 'Inquiries', Inbox], ['/admin/settings', 'Settings', Settings],
] as const;

export function AdminNav({ name }: { name: string }) {
  const path = usePathname();
  const [open, setOpen] = useState(false);
  return (
    <aside className="bg-forest-950 text-ivory lg:sticky lg:top-0 lg:h-screen lg:w-64 lg:shrink-0">
      <div className="flex items-center justify-between px-5 py-5">
        <Link href="/admin"><Logo light /></Link>
        <button className="lg:hidden" onClick={() => setOpen(!open)}><Menu /></button>
      </div>
      <nav className={`${open ? 'block' : 'hidden'} px-3 pb-5 lg:block`}>
        {items.map(([href, label, Icon]) => {
          const on = href === '/admin' ? path === href : path.startsWith(href);
          return (
            <Link key={href} href={href} onClick={() => setOpen(false)}
              className={`mb-0.5 flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm transition ${on ? 'bg-ivory/10 text-ivory' : 'text-ivory/60 hover:bg-ivory/5 hover:text-ivory'}`}>
              <Icon size={17} className={on ? 'text-brass-300' : ''} /> {label}
            </Link>
          );
        })}
        <div className="mt-6 border-t border-ivory/10 pt-4 text-xs text-ivory/50">
          <p className="truncate px-3">{name}</p>
          <Link href="/" className="mt-2 flex items-center gap-2 rounded-lg px-3 py-2 hover:text-ivory"><ExternalLink size={14} /> View website</Link>
          <SignOut className="flex w-full items-center gap-2 rounded-lg px-3 py-2 hover:text-ivory"><LogOut size={14} /> Sign out</SignOut>
        </div>
      </nav>
    </aside>
  );
}
