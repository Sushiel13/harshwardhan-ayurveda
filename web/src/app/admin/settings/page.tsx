'use client';
import { useEffect, useState } from 'react';
import { Crud } from '@/components/admin/Crud';
import { supabaseBrowser } from '@/lib/supabase/client';
import { slugify } from '@/lib/site';

export default function Settings() {
  const sb = supabaseBrowser();
  const [site, setSite] = useState<Record<string, string>>({});
  const [saved, setSaved] = useState('');
  useEffect(() => { sb.from('settings').select('value').eq('key', 'site').maybeSingle().then(({ data }: any) => setSite(data?.value ?? {})); }, [sb]);
  async function save(e: React.FormEvent) {
    e.preventDefault();
    const { error } = await sb.from('settings').upsert({ key: 'site', value: site });
    setSaved(error ? error.message : 'Saved ✓');
  }
  const f = (k: string, l: string) => <div key={k}><label className="label">{l}</label><input className="input" value={site[k] ?? ''} onChange={(e) => setSite({ ...site, [k]: e.target.value })} /></div>;
  return (
    <div className="space-y-12">
      <form onSubmit={save} className="card max-w-3xl space-y-4 p-6">
        <h1 className="font-display text-3xl text-forest-900">Settings</h1>
        <p className="text-sm text-ink-mute">Contact details used in the mobile app. (Website footer values live in <code>web/src/lib/site.ts</code>.)</p>
        <div className="grid gap-4 md:grid-cols-2">
          {f('phone', 'Phone')}{f('whatsapp', 'WhatsApp number (with 91)')}{f('email', 'Email')}{f('address', 'Address')}
          {f('instagram', 'Instagram URL')}{f('youtube', 'YouTube URL')}{f('telegram', 'Telegram URL')}
        </div>
        <button className="btn-primary">Save</button> <span className="text-sm text-forest-700">{saved}</span>
      </form>
      <Crud table="categories" title="Exam categories" order="position" ascending
        fields={[{ name: 'name', label: 'Name', type: 'text', required: true }, { name: 'position', label: 'Order', type: 'number', default: 1 }]}
        beforeSave={(r) => ({ ...r, slug: r.slug || slugify(r.name) })}
        columns={[{ key: 'name', label: 'Category' }, { key: 'position', label: 'Order' }]} />
      <Crud table="testimonials" title="Testimonials" order="position" ascending
        fields={[{ name: 'name', label: 'Student name', type: 'text', required: true }, { name: 'detail', label: 'Detail (e.g. AIAPGET 2026 qualified)', type: 'text' }, { name: 'quote', label: 'Quote', type: 'textarea', required: true }, { name: 'position', label: 'Order', type: 'number', default: 1 }]}
        columns={[{ key: 'name', label: 'Name' }, { key: 'detail', label: 'Detail' }]} />
    </div>
  );
}
