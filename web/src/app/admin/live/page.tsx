'use client';
import { useEffect, useState } from 'react';
import { Crud, yesNo } from '@/components/admin/Crud';
import { supabaseBrowser } from '@/lib/supabase/client';

export default function AdminLive() {
  const [courses, setCourses] = useState<{ value: string; label: string }[]>([]);
  useEffect(() => { supabaseBrowser().from('courses').select('id,title').then(({ data }: any) => setCourses((data ?? []).map((c: any) => ({ value: c.id, label: c.title })))); }, []);
  return (
    <Crud table="live_classes" title="Live classes" order="starts_at"
      fields={[
        { name: 'title', label: 'Class title', type: 'text', required: true },
        { name: 'description', label: 'Description', type: 'textarea' },
        { name: 'starts_at', label: 'Starts at', type: 'datetime', required: true },
        { name: 'duration_minutes', label: 'Duration (minutes)', type: 'number', default: 60 },
        { name: 'meeting_url', label: 'Meeting link', type: 'text', help: 'Zoom / Google Meet / YouTube Live link.' },
        { name: 'course_id', label: 'Only for students of course', type: 'select', options: courses, help: 'Leave empty to allow every logged-in student.' },
        { name: 'is_free', label: 'Open to everyone (even without login)', type: 'bool' },
      ]}
      columns={[
        { key: 'title', label: 'Class' },
        { key: 'starts_at', label: 'When', render: (r) => new Date(r.starts_at).toLocaleString('en-IN') },
        { key: 'is_free', label: 'Public', render: (r) => yesNo(r.is_free) },
      ]}
    />
  );
}
