'use client';
import { Crud, yesNo } from '@/components/admin/Crud';

export default function AdminNotes() {
  return (
    <Crud table="notes" title="Free notes"
      fields={[
        { name: 'title', label: 'Title', type: 'text', required: true },
        { name: 'subject', label: 'Subject', type: 'text', help: 'Notes are grouped by subject on the website.' },
        { name: 'description', label: 'Short description', type: 'text' },
        { name: 'file_path', label: 'PDF file (public)', type: 'file', folder: 'notes', accept: 'application/pdf', required: true },
        { name: 'is_published', label: 'Published', type: 'bool', default: true },
      ]}
      columns={[{ key: 'title', label: 'Title' }, { key: 'subject', label: 'Subject' }, { key: 'is_published', label: 'Published', render: (r) => yesNo(r.is_published) }]}
    />
  );
}
