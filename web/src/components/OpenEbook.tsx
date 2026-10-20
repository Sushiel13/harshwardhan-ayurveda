'use client';
import { useState } from 'react';
import { BookOpen, Loader2 } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';

export function OpenEbook({ path }: { path: string | null }) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  async function open() {
    if (!path) return setErr('File not uploaded yet.');
    setBusy(true);
    const { data, error } = await supabaseBrowser().storage.from('content').createSignedUrl(path, 60 * 30);
    setBusy(false);
    if (error || !data) return setErr('You need to purchase this eBook to read it.');
    window.open(data.signedUrl, '_blank');
  }
  return (
    <div>
      <button onClick={open} className="btn-ghost w-full">{busy ? <Loader2 size={15} className="animate-spin" /> : <BookOpen size={15} />} Read eBook</button>
      {err && <p className="mt-2 text-xs text-red-700">{err}</p>}
    </div>
  );
}
