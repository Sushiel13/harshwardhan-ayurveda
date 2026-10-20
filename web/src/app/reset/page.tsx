'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabaseBrowser } from '@/lib/supabase/client';
import { AuthShell } from '@/components/AuthShell';

export default function Reset() {
  const sb = supabaseBrowser();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [pw, setPw] = useState('');
  const [recovery, setRecovery] = useState(false);
  const [msg, setMsg] = useState('');
  useEffect(() => {
    const { data } = sb.auth.onAuthStateChange((e) => { if (e === 'PASSWORD_RECOVERY') setRecovery(true); });
    return () => data.subscription.unsubscribe();
  }, [sb]);
  async function sendLink(e: React.FormEvent) {
    e.preventDefault();
    const { error } = await sb.auth.resetPasswordForEmail(email, { redirectTo: `${location.origin}/reset` });
    setMsg(error ? error.message : 'If that email is registered, a reset link is on its way.');
  }
  async function setNew(e: React.FormEvent) {
    e.preventDefault();
    const { error } = await sb.auth.updateUser({ password: pw });
    if (error) setMsg(error.message); else router.replace('/dashboard');
  }
  return (
    <AuthShell title={recovery ? 'Choose a new password' : 'Reset password'} sub={recovery ? 'Enter a new password for your account.' : "We'll email you a secure link."}>
      {recovery ? (
        <form onSubmit={setNew} className="space-y-4"><input type="password" minLength={6} required className="input" placeholder="New password" value={pw} onChange={(e) => setPw(e.target.value)} /><button className="btn-primary w-full">Save password</button></form>
      ) : (
        <form onSubmit={sendLink} className="space-y-4"><input type="email" required className="input" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} /><button className="btn-primary w-full">Send reset link</button></form>
      )}
      {msg && <p className="mt-4 text-sm text-ink-soft">{msg}</p>}
    </AuthShell>
  );
}
