'use client';
import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { Loader2, Pencil, Plus, Trash2, X } from 'lucide-react';
import { supabaseBrowser } from '@/lib/supabase/client';
import { Upload } from './Upload';

export type Field = {
  name: string; label: string;
  type: 'text' | 'textarea' | 'number' | 'bool' | 'select' | 'datetime' | 'image' | 'file' | 'private-file';
  options?: { value: string; label: string }[]; required?: boolean; help?: string; folder?: string | ((row: any) => string); accept?: string;
  default?: unknown; full?: boolean;
};
export type Column = { key: string; label: string; render?: (row: any) => React.ReactNode };

export function Crud({ table, title, fields, columns, order = 'created_at', ascending = false, filter, beforeSave, rowLink, extraActions }: {
  table: string; title: string; fields: Field[]; columns: Column[]; order?: string; ascending?: boolean;
  filter?: Record<string, unknown>; beforeSave?: (row: any) => any; rowLink?: (row: any) => string;
  extraActions?: (row: any) => React.ReactNode;
}) {
  const sb = supabaseBrowser();
  const [rows, setRows] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [edit, setEdit] = useState<any | null>(null);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    let q = sb.from(table).select('*').order(order, { ascending });
    if (filter) Object.entries(filter).forEach(([k, v]) => { q = q.eq(k, v as any); });
    const { data } = await q;
    setRows(data ?? []); setLoading(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [table, order, ascending, JSON.stringify(filter)]);
  useEffect(() => { load(); }, [load]);

  function blank() {
    const r: any = { ...(filter ?? {}), id: crypto.randomUUID(), __new: true };
    fields.forEach((f) => { r[f.name] = f.default ?? (f.type === 'bool' ? false : null); });
    return r;
  }

  async function save(e: React.FormEvent) {
    e.preventDefault(); setSaving(true); setErr('');
    let row = { ...edit };
    fields.forEach((f) => {
      if (f.type === 'number') row[f.name] = row[f.name] === '' || row[f.name] === null ? null : Number(row[f.name]);
      if (f.type === 'datetime' && row[f.name]) row[f.name] = new Date(row[f.name]).toISOString();
    });
    if (beforeSave) row = beforeSave(row);
    const { id, created_at, __new, ...data } = row;
    const res = __new ? await sb.from(table).insert({ id, ...data }) : await sb.from(table).update(data).eq('id', id);
    setSaving(false);
    if (res.error) return setErr(res.error.message);
    setEdit(null); load();
  }

  async function remove(row: any) {
    if (!confirm('Delete this item permanently?')) return;
    const { error } = await sb.from(table).delete().eq('id', row.id);
    if (error) alert(error.message); else load();
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="font-display text-3xl text-forest-900">{title}</h1>
        <button className="btn-primary" onClick={() => setEdit(blank())}><Plus size={16} /> Add new</button>
      </div>
      <div className="card mt-6 overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-forest-900/10 bg-ivory-50 text-xs uppercase tracking-wider text-ink-mute">
            <tr>{columns.map((c) => <th key={c.key} className="px-4 py-3 font-semibold">{c.label}</th>)}<th className="px-4 py-3" /></tr>
          </thead>
          <tbody>
            {loading ? <tr><td className="p-6" colSpan={99}><Loader2 className="animate-spin" /></td></tr> :
              rows.map((r) => (
                <tr key={r.id} className="border-b border-forest-900/5 last:border-0 hover:bg-ivory-50/60">
                  {columns.map((c, i) => (
                    <td key={c.key} className="px-4 py-3 align-middle">
                      {i === 0 && rowLink ? <Link href={rowLink(r)} className="font-semibold text-forest-900 hover:underline">{c.render ? c.render(r) : String(r[c.key] ?? '')}</Link>
                        : c.render ? c.render(r) : String(r[c.key] ?? '')}
                    </td>
                  ))}
                  <td className="whitespace-nowrap px-4 py-3 text-right">
                    {extraActions?.(r)}
                    <button className="p-2 text-ink-mute hover:text-forest-800" onClick={() => setEdit(toForm(r, fields))} aria-label="Edit"><Pencil size={15} /></button>
                    <button className="p-2 text-ink-mute hover:text-red-700" onClick={() => remove(r)} aria-label="Delete"><Trash2 size={15} /></button>
                  </td>
                </tr>
              ))}
            {!loading && rows.length === 0 && <tr><td className="p-8 text-center text-ink-mute" colSpan={99}>Nothing yet — click “Add new”.</td></tr>}
          </tbody>
        </table>
      </div>

      {edit && (
        <div className="fixed inset-0 z-50 flex justify-end bg-forest-950/40 backdrop-blur-sm" onClick={() => setEdit(null)}>
          <form onSubmit={save} onClick={(e) => e.stopPropagation()} className="flex h-full w-full max-w-xl flex-col bg-ivory shadow-lift">
            <div className="flex items-center justify-between border-b border-forest-900/10 px-6 py-4">
              <h2 className="font-display text-xl text-forest-900">{edit.__new ? 'Add' : 'Edit'} — {title}</h2>
              <button type="button" onClick={() => setEdit(null)}><X /></button>
            </div>
            <div className="flex-1 space-y-5 overflow-y-auto p-6">
              {fields.map((f) => <FieldInput key={f.name} f={f} row={edit} value={edit[f.name]} onChange={(v) => setEdit({ ...edit, [f.name]: v })} />)}
              {err && <p className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{err}</p>}
            </div>
            <div className="flex justify-end gap-2 border-t border-forest-900/10 px-6 py-4">
              <button type="button" className="btn-ghost" onClick={() => setEdit(null)}>Cancel</button>
              <button className="btn-primary" disabled={saving}>{saving && <Loader2 size={15} className="animate-spin" />} Save</button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

function toForm(r: any, fields: Field[]) {
  const o = { ...r };
  fields.forEach((f) => {
    if (f.type === 'datetime' && o[f.name]) {
      const d = new Date(o[f.name]);
      o[f.name] = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    }
  });
  return o;
}

export function FieldInput({ f, value, onChange, row }: { f: Field; value: any; onChange: (v: any) => void; row?: any }) {
  const folder = typeof f.folder === 'function' ? f.folder(row ?? {}) : f.folder;
  const common = { className: 'input', required: f.required };
  let el: React.ReactNode;
  switch (f.type) {
    case 'textarea': el = <textarea rows={5} {...common} value={value ?? ''} onChange={(e) => onChange(e.target.value)} />; break;
    case 'number': el = <input type="number" step="any" {...common} value={value ?? ''} onChange={(e) => onChange(e.target.value)} />; break;
    case 'datetime': el = <input type="datetime-local" {...common} value={value ?? ''} onChange={(e) => onChange(e.target.value)} />; break;
    case 'bool': el = (
      <label className="flex cursor-pointer items-center gap-3">
        <span className={`relative h-6 w-11 rounded-full transition ${value ? 'bg-forest-700' : 'bg-forest-900/15'}`}>
          <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition ${value ? 'left-[22px]' : 'left-0.5'}`} />
        </span>
        <input type="checkbox" className="hidden" checked={!!value} onChange={(e) => onChange(e.target.checked)} />
        <span className="text-sm text-ink-soft">{value ? 'Yes' : 'No'}</span>
      </label>
    ); break;
    case 'select': el = (
      <select {...common} value={value ?? ''} onChange={(e) => onChange(e.target.value || null)}>
        <option value="">—</option>
        {f.options?.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    ); break;
    case 'image': el = <Upload bucket="media" folder={folder || 'images'} accept="image/*" value={value} onChange={onChange} mode="url" />; break;
    case 'file': el = <Upload bucket="media" folder={folder || 'files'} accept={f.accept} value={value} onChange={onChange} mode="path" />; break;
    case 'private-file': el = <Upload bucket="content" folder={folder || 'misc'} accept={f.accept} value={value} onChange={onChange} mode="path" />; break;
    default: el = <input {...common} value={value ?? ''} onChange={(e) => onChange(e.target.value)} />;
  }
  return (
    <div>
      <label className="label">{f.label}{f.required && ' *'}</label>
      {el}
      {f.help && <p className="mt-1 text-xs text-ink-mute">{f.help}</p>}
    </div>
  );
}

export const yesNo = (v: boolean) => <span className={`chip ${v ? '' : '!bg-ivory-200 !text-ink-mute'}`}>{v ? 'Yes' : 'No'}</span>;
