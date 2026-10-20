import { redirect } from 'next/navigation';
import { getSessionProfile } from '@/lib/data';
import { AdminNav } from '@/components/admin/AdminNav';

export const dynamic = 'force-dynamic';
export const metadata = { title: 'Admin' };

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, profile } = await getSessionProfile();
  if (!user) redirect('/login?next=/admin');
  if (profile?.role !== 'admin') redirect('/dashboard');
  return (
    <div className="flex min-h-screen flex-col bg-ivory-100 lg:flex-row">
      <AdminNav name={profile.full_name || user.email || 'Admin'} />
      <div className="flex-1 overflow-x-hidden p-5 md:p-8 lg:p-10">{children}</div>
    </div>
  );
}
