'use client';
import { Crud, yesNo } from '@/components/admin/Crud';
import { inr } from '@/lib/site';

export default function AdminEbooks() {
  return (
    <Crud table="ebooks" title="eBooks"
      fields={[
        { name: 'title', label: 'Title', type: 'text', required: true },
        { name: 'author', label: 'Author', type: 'text' },
        { name: 'description', label: 'Description', type: 'textarea' },
        { name: 'cover_url', label: 'Cover image (3:4)', type: 'image', folder: 'covers' },
        { name: 'file_path', label: 'eBook PDF (private)', type: 'private-file', folder: (r) => `ebooks/${r.id}`, accept: 'application/pdf', help: 'Stored privately; only buyers can open it.' },
        { name: 'is_free', label: 'Free?', type: 'bool' },
        { name: 'price', label: 'Price (₹)', type: 'number', default: 0 },
        { name: 'mrp', label: 'MRP (₹)', type: 'number' },
        { name: 'is_published', label: 'Published', type: 'bool' },
      ]}
      beforeSave={(r) => ({ ...r, price: r.is_free ? 0 : r.price ?? 0 })}
      columns={[
        { key: 'title', label: 'eBook' },
        { key: 'price', label: 'Price', render: (r) => r.is_free ? 'Free' : inr(r.price) },
        { key: 'file_path', label: 'PDF', render: (r) => yesNo(!!r.file_path) },
        { key: 'is_published', label: 'Published', render: (r) => yesNo(r.is_published) },
      ]}
    />
  );
}
