'use client';
import { Suspense, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { AuthShell } from '@/components/AuthShell';

function SignupForm() {
  const router = useRouter();
  const next = useSearchParams().get('next') || '/dashboard';
  const [f, setF] = useState({ full_name: '', phone: '', email: '', password: '' });
  const [err, setErr] = useState('');
  const [info, setInfo] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault(); setBusy(true); setErr('');
    const { data, error } = await supabaseBrowser().auth.signUp({
      email: f.email, password: f.password,
      options: { data: { full_name: f.full_name, phone: f.phone }, emailRedirectTo: `${location.origin}/dashboard` },
    });
    setBusy(false);
    if (error) return setErr(error.message);
    if (!data.session) return setInfo('Check your inbox to confirm your email, then log in.');
    router.replace(next); router.refresh();
  }
  if (info) return <p className="rounded-xl bg-forest-50 p-5 text-forest-800">{info}</p>;
  return (
    <form onSubmit={submit} className="space-y-4">
      <div><label className="label">Full name</label><input required className="input" value={f.full_name} onChange={(e) => setF({ ...f, full_name: e.target.value })} /></div>
      <div><label className="label">Mobile number</label><input required pattern="[0-9+ ]{10,15}" className="input" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></div>
      <div><label className="label">Email</label><input type="email" required className="input" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} /></div>
      <div><label className="label">Password</label><input type="password" minLength={6} required className="input" value={f.password} onChange={(e) => setF({ ...f, password: e.target.value })} /></div>
      {err && <p className="text-sm text-red-700">{err}</p>}
      <button className="btn-primary w-full !py-3" disabled={busy}>{busy && <Loader2 size={16} className="animate-spin" />} Create account</button>
      <p className="text-center text-sm text-ink-soft">Already registered? <Link href="/login" className="font-semibold text-forest-800">Log in</Link></p>
    </form>
  );
}

export default function Signup() {
  return <AuthShell title="Begin your journey" sub="One account for the website and the mobile app."><Suspense><SignupForm /></Suspense></AuthShell>;
}
