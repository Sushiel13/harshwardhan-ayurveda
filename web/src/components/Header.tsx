'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Menu, X, Bell, LayoutDashboard } from 'lucide-react';
import { Logo } from './Logo';
import { supabaseBrowser } from '@/lib/supabase/client';

const nav = [
  { href: '/courses', label: 'Courses' },
  { href: '/test-series', label: 'Test Series' },
  { href: '/ebooks', label: 'eBooks' },
  { href: '/notes', label: 'Free Notes' },
  { href: '/live', label: 'Live Classes' },
  { href: '/about', label: 'About' },
];

export function Header() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [role, setRole] = useState<'guest' | 'student' | 'admin'>('guest');
  const pathname = usePathname();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    if (!process.env.NEXT_PUBLIC_SUPABASE_URL) return;
    const sb = supabaseBrowser();
    const load = async () => {
      const { data: { user } } = await sb.auth.getUser();
      if (!user) return setRole('guest');
      const { data } = await sb.from('profiles').select('role').eq('id', user.id).single();
      setRole(data?.role === 'admin' ? 'admin' : 'student');
    };
    load();
    const { data: sub } = sb.auth.onAuthStateChange(() => load());
    return () => sub.subscription.unsubscribe();
  }, []);

  useEffect(() => setOpen(false), [pathname]);
  if (pathname.startsWith('/admin')) return null;

  return (
    <header className={`sticky top-0 z-40 transition-all ${scrolled ? 'bg-ivory/90 backdrop-blur-md border-b border-forest-900/[0.07]' : 'bg-ivory'}`}>
      <div className="container-x flex h-[72px] items-center justify-between">
        <Link href="/" aria-label="Home"><Logo /></Link>
        <nav className="hidden items-center gap-7 lg:flex">
          {nav.map((n) => (
            <Link key={n.href} href={n.href}
              className={`text-[13.5px] font-medium transition hover:text-forest-900 ${pathname.startsWith(n.href) ? 'text-forest-900' : 'text-ink-soft'}`}>
              {n.label}
            </Link>
          ))}
        </nav>
        <div className="hidden items-center gap-2 lg:flex">
          {role === 'guest' ? (
            <>
              <Link href="/login" className="btn text-forest-800 hover:bg-forest-50">Log in</Link>
              <Link href="/signup" className="btn-primary">Start learning</Link>
            </>
          ) : (
            <>
              <Link href="/dashboard#updates" className="btn h-10 w-10 !p-0 text-forest-800 hover:bg-forest-50" aria-label="Notifications"><Bell size={18} /></Link>
              {role === 'admin' && <Link href="/admin" className="btn-ghost">Admin</Link>}
              <Link href="/dashboard" className="btn-primary"><LayoutDashboard size={16} /> My learning</Link>
            </>
          )}
        </div>
        <button className="lg:hidden p-2 text-forest-900" onClick={() => setOpen(!open)} aria-label="Menu">
          {open ? <X /> : <Menu />}
        </button>
      </div>
      {open && (
        <div className="border-t border-forest-900/10 bg-ivory lg:hidden">
          <div className="container-x flex flex-col py-4">
            {nav.map((n) => (
              <Link key={n.href} href={n.href} className="py-3 text-[15px] font-medium text-forest-900 border-b border-forest-900/5">{n.label}</Link>
            ))}
            <Link href="/contact" className="py-3 text-[15px] font-medium text-forest-900">Contact</Link>
            <div className="mt-3 flex gap-2">
              {role === 'guest' ? (
                <>
                  <Link href="/login" className="btn-ghost flex-1">Log in</Link>
                  <Link href="/signup" className="btn-primary flex-1">Sign up</Link>
                </>
              ) : (
                <>
                  {role === 'admin' && <Link href="/admin" className="btn-ghost flex-1">Admin</Link>}
                  <Link href="/dashboard" className="btn-primary flex-1">My learning</Link>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
