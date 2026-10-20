'use client';
import { useRouter } from 'next/navigation';
import { supabaseBrowser } from '@/lib/supabase/client';

export function SignOut({ className, children }: { className?: string; children: React.ReactNode }) {
  const router = useRouter();
  return (
    <button className={className} onClick={async () => { await supabaseBrowser().auth.signOut(); router.replace('/'); router.refresh(); }}>
      {children}
    </button>
  );
}
