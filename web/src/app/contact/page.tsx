'use client';
import { useState } from 'react';
import { Mail, MapPin, MessageCircle, Phone } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { PageHero } from '@/components/Cards';
import { site } from '@/lib/site';

export default function Contact() {
  const [f, setF] = useState({ name: '', email: '', phone: '', message: '' });
  const [state, setState] = useState<'idle' | 'busy' | 'ok' | 'err'>('idle');
  async function send(e: React.FormEvent) {
    e.preventDefault(); setState('busy');
    const { error } = await supabaseBrowser().from('inquiries').insert(f);
    setState(error ? 'err' : 'ok');
  }
  return (
    <>
      <PageHero eyebrow="Contact" title="We're happy to help" text="Questions about a course, payment or your account — write to us and we'll respond within one working day." />
      <div className="container-x grid gap-10 py-14 lg:grid-cols-12">
        <div className="space-y-4 lg:col-span-4">
          {[[Phone, 'Call', site.contact.phone, `tel:${site.contact.phone}`], [MessageCircle, 'WhatsApp', 'Chat with us', `https://wa.me/${site.contact.whatsapp}`], [Mail, 'Email', site.contact.email, `mailto:${site.contact.email}`], [MapPin, 'Address', site.contact.address, '#']].map(([I, t, v, h]) => {
            const Icon = I as typeof Phone;
            return <a key={t as string} href={h as string} className="card flex items-center gap-4 p-5"><span className="grid h-11 w-11 place-items-center rounded-full bg-forest-50 text-forest-700"><Icon size={18} /></span><span><span className="block text-xs uppercase tracking-wider text-ink-mute">{t as string}</span><span className="font-semibold text-forest-900">{v as string}</span></span></a>;
          })}
        </div>
        <form onSubmit={send} className="card space-y-4 p-7 lg:col-span-8">
          {state === 'ok' ? <p className="py-10 text-center font-display text-2xl text-forest-900">Thank you — we'll be in touch soon.</p> : (
            <>
              <div className="grid gap-4 md:grid-cols-2">
                <div><label className="label">Name</label><input required className="input" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></div>
                <div><label className="label">Phone</label><input className="input" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></div>
              </div>
              <div><label className="label">Email</label><input type="email" className="input" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} /></div>
              <div><label className="label">Message</label><textarea required rows={5} className="input" value={f.message} onChange={(e) => setF({ ...f, message: e.target.value })} /></div>
              {state === 'err' && <p className="text-sm text-red-700">Could not send. Please try WhatsApp instead.</p>}
              <button className="btn-primary" disabled={state === 'busy'}>Send message</button>
            </>
          )}
        </form>
      </div>
    </>
  );
}
