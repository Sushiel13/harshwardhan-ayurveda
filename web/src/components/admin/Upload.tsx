'use client';
import { useState } from 'react';
import { Loader2, Upload as UpIcon, X } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';

/**
 * Uploads a file to Supabase Storage.
 * bucket "media"   → public, returns public URL (mode="url")
 * bucket "content" → private, returns object path (mode="path")
 */
export function Upload({ bucket, folder, accept, value, onChange, mode }: {
  bucket: 'media' | 'content'; folder: string; accept?: string; value?: string | null;
  onChange: (v: string | null) => void; mode: 'url' | 'path';
}) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  async function pick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setBusy(true); setErr('');
    const sb = supabaseBrowser();
    const safe = file.name.toLowerCase().replace(/[^a-z0-9.]+/g, '-');
    const path = `${folder}/${Date.now()}-${safe}`;
    const { error } = await sb.storage.from(bucket).upload(path, file, { upsert: false, contentType: file.type });
    setBusy(false);
    if (error) return setErr(error.message);
    onChange(mode === 'url' ? sb.storage.from(bucket).getPublicUrl(path).data.publicUrl : path);
  }
  return (
    <div>
      <div className="flex items-center gap-2">
        <label className="btn-ghost cursor-pointer !py-2">
          {busy ? <Loader2 size={15} className="animate-spin" /> : <UpIcon size={15} />} {busy ? 'Uploading…' : 'Choose file'}
          <input type="file" accept={accept} className="hidden" onChange={pick} disabled={busy} />
        </label>
        {value && <button type="button" onClick={() => onChange(null)} className="text-ink-mute hover:text-red-700"><X size={16} /></button>}
      </div>
      {value && (mode === 'url' && /\.(png|jpe?g|webp|gif)$/i.test(value)
        ? <img src={value} alt="" className="mt-2 h-20 rounded-lg object-cover" />
        : <p className="mt-1.5 truncate text-xs text-ink-mute">{value.split('/').pop()}</p>)}
      {err && <p className="mt-1 text-xs text-red-700">{err}</p>}
    </div>
  );
}
