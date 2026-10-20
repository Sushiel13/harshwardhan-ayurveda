'use client';
import { Suspense, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { AuthShell } from '@/components/AuthShell';

function LoginForm() {
  const router = useRouter();
  const next = useSearchParams().get('next') || '/dashboard';
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault(); setBusy(true); setErr('');
    const { error } = await supabaseBrowser().auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) return setErr(error.message);
    router.replace(next); router.refresh();
  }
  return (
    <form onSubmit={submit} className="space-y-4">
      <div><label className="label">Email</label><input type="email" required className="input" value={email} onChange={(e) => setEmail(e.target.value)} /></div>
      <div>
        <div className="flex justify-between"><label className="label">Password</label><Link href="/reset" className="text-xs font-semibold text-brass-600">Forgot?</Link></div>
        <input type="password" required className="input" value={password} onChange={(e) => setPassword(e.target.value)} />
      </div>
      {err && <p className="text-sm text-red-700">{err}</p>}
      <button className="btn-primary w-full !py-3" disabled={busy}>{busy && <Loader2 size={16} className="animate-spin" />} Log in</button>
      <p className="text-center text-sm text-ink-soft">New here? <Link href={`/signup?next=${encodeURIComponent(next)}`} className="font-semibold text-forest-800">Create an account</Link></p>
    </form>
  );
}

export default function Login() {
  return <AuthShell title="Welcome back" sub="Log in to continue your learning."><Suspense><LoginForm /></Suspense></AuthShell>;
}
