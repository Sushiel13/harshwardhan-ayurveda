'use client';
import Link from 'next/link';
import { Crud, yesNo } from '@/components/admin/Crud';
import { inr } from '@/lib/site';

export default function AdminSeries() {
  return (
    <Crud table="test_series" title="Test series"
      fields={[
        { name: 'title', label: 'Title', type: 'text', required: true },
        { name: 'description', label: 'Description', type: 'textarea' },
        { name: 'thumbnail_url', label: 'Thumbnail', type: 'image', folder: 'thumbnails' },
        { name: 'is_free', label: 'Free?', type: 'bool' },
        { name: 'price', label: 'Price (₹)', type: 'number', default: 0 },
        { name: 'mrp', label: 'MRP (₹)', type: 'number' },
        { name: 'validity_days', label: 'Validity (days)', type: 'number', help: 'Empty = lifetime' },
        { name: 'is_published', label: 'Published', type: 'bool' },
      ]}
      beforeSave={(r) => ({ ...r, price: r.is_free ? 0 : r.price ?? 0 })}
      columns={[
        { key: 'title', label: 'Series' },
        { key: 'price', label: 'Price', render: (r) => r.is_free ? 'Free' : inr(r.price) },
        { key: 'is_published', label: 'Published', render: (r) => yesNo(r.is_published) },
      ]}
      rowLink={(r) => `/admin/test-series/${r.id}`}
      extraActions={(r) => <Link href={`/admin/test-series/${r.id}`} className="mr-2 text-xs font-semibold text-brass-600">Tests →</Link>}
    />
  );
}
