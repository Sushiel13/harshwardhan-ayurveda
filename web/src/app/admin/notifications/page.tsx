'use client';
import { Crud } from '@/components/admin/Crud';

export default function AdminNotifications() {
  return (
    <>
      <p className="mb-4 rounded-xl bg-brass-500/10 p-4 text-sm text-forest-900">Announcements appear on every student's dashboard and in the mobile app's Updates tab.</p>
      <Crud table="notifications" title="Announcements"
        fields={[
          { name: 'title', label: 'Title', type: 'text', required: true },
          { name: 'body', label: 'Message', type: 'textarea' },
          { name: 'link', label: 'Link (optional)', type: 'text' },
        ]}
        columns={[{ key: 'title', label: 'Title' }, { key: 'created_at', label: 'Sent', render: (r) => new Date(r.created_at).toLocaleString('en-IN') }]}
      />
    </>
  );
}
