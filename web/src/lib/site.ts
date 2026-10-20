export const site = {
  name: 'Harshwardhan Institute of Ayurveda',
  short: 'Harshwardhan Ayurveda',
  tagline: 'Classical wisdom. Modern mastery.',
  description:
    'Expert-led BAMS courses, AIAPGET preparation, test series, eBooks and live classes from Harshwardhan Institute of Ayurveda.',
  url: process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000',
  // Defaults; the admin can override these in Admin → Settings
  contact: {
    phone: '+91 90000 00000',
    whatsapp: '919000000000',
    email: 'hello@harshwardhanayurveda.in',
    address: 'Pune, Maharashtra',
  },
  playStoreUrl: '#',
  appStoreUrl: '#',
};

export const inr = (n: number | string | null | undefined) =>
  n === null || n === undefined ? '' : '₹' + Number(n).toLocaleString('en-IN', { maximumFractionDigits: 0 });

export const discount = (price?: number | null, mrp?: number | null) =>
  price && mrp && mrp > price ? Math.round(((mrp - price) / mrp) * 100) : 0;

export const slugify = (s: string) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
