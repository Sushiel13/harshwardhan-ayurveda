'use client';
import { Crud, yesNo } from '@/components/admin/Crud';

export default function AdminCoupons() {
  return (
    <Crud table="coupons" title="Coupons" order="code" ascending
      fields={[
        { name: 'code', label: 'Code', type: 'text', required: true, help: 'Students type this at checkout, e.g. DIWALI25' },
        { name: 'discount_percent', label: 'Discount %', type: 'number', required: true },
        { name: 'max_uses', label: 'Maximum uses', type: 'number', help: 'Empty = unlimited' },
        { name: 'expires_at', label: 'Expires at', type: 'datetime' },
        { name: 'is_active', label: 'Active', type: 'bool', default: true },
      ]}
      beforeSave={(r) => ({ ...r, code: String(r.code).toUpperCase().replace(/\s+/g, '') })}
      columns={[
        { key: 'code', label: 'Code' }, { key: 'discount_percent', label: '% off' },
        { key: 'used_count', label: 'Used', render: (r) => `${r.used_count}${r.max_uses ? ' / ' + r.max_uses : ''}` },
        { key: 'is_active', label: 'Active', render: (r) => yesNo(r.is_active) },
      ]}
    />
  );
}
