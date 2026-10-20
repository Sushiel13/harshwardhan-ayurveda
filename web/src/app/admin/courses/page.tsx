'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Crud, yesNo } from '@/components/admin/Crud';
import { supabaseBrowser } from '@/lib/supabase/client';
import { inr, slugify } from '@/lib/site';

export default function AdminCourses() {
  const [cats, setCats] = useState<{ value: string; label: string }[]>([]);
  useEffect(() => { supabaseBrowser().from('categories').select('id,name').order('position').then(({ data }: any) => setCats((data ?? []).map((c: any) => ({ value: c.id, label: c.name })))); }, []);
  return (
    <>
      <p className="mb-4 rounded-xl bg-brass-500/10 p-4 text-sm text-forest-900">
        Create the course here, then click its <b>title</b> to add sections and upload videos.
      </p>
      <Crud
        table="courses" title="Courses"
        fields={[
          { name: 'title', label: 'Title', type: 'text', required: true },
          { name: 'subtitle', label: 'Short subtitle', type: 'text' },
          { name: 'description', label: 'Description', type: 'textarea' },
          { name: 'category_id', label: 'Category / exam', type: 'select', options: cats },
          { name: 'thumbnail_url', label: 'Thumbnail (16:10 image)', type: 'image', folder: 'thumbnails' },
          { name: 'instructor', label: 'Instructor', type: 'text', default: 'Harshwardhan Institute Faculty' },
          { name: 'language', label: 'Language', type: 'text', default: 'Hindi + English' },
          { name: 'is_free', label: 'Free course?', type: 'bool' },
          { name: 'price', label: 'Selling price (₹)', type: 'number', default: 0 },
          { name: 'mrp', label: 'MRP / strike-through price (₹)', type: 'number', help: 'Optional. Shows a discount badge.' },
          { name: 'validity_days', label: 'Access validity (days)', type: 'number', help: 'Leave empty for lifetime access.' },
          { name: 'is_featured', label: 'Feature on home page', type: 'bool' },
          { name: 'is_published', label: 'Published (visible to students)', type: 'bool' },
        ]}
        beforeSave={(r) => ({ ...r, slug: r.slug || slugify(r.title) + '-' + Math.random().toString(36).slice(2, 6), price: r.is_free ? 0 : r.price ?? 0 })}
        columns={[
          { key: 'title', label: 'Course' },
          { key: 'price', label: 'Price', render: (r) => r.is_free ? 'Free' : inr(r.price) },
          { key: 'is_published', label: 'Published', render: (r) => yesNo(r.is_published) },
          { key: 'is_featured', label: 'Featured', render: (r) => yesNo(r.is_featured) },
        ]}
        rowLink={(r) => `/admin/courses/${r.id}`}
        extraActions={(r) => <Link href={`/admin/courses/${r.id}`} className="mr-2 text-xs font-semibold text-brass-600">Lessons →</Link>}
      />
    </>
  );
}
