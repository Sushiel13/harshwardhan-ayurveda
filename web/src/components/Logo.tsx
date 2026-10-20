export function Emblem({ className = 'h-9 w-9' }: { className?: string }) {
  return (
    <svg viewBox="0 0 48 48" className={className} aria-hidden="true">
      <circle cx="24" cy="24" r="23" fill="#11302A" />
      <circle cx="24" cy="24" r="20.5" fill="none" stroke="#D2AA62" strokeWidth="0.8" />
      {/* three-leaf sprout */}
      <path d="M24 13c-3.2 3-3.2 7.6 0 10.6 3.2-3 3.2-7.6 0-10.6Z" fill="#D2AA62" />
      <path d="M14.5 18.5c1 4.3 4.6 7 9 6.6-1-4.3-4.6-7-9-6.6Z" fill="#B8893B" />
      <path d="M33.5 18.5c-1 4.3-4.6 7-9 6.6 1-4.3 4.6-7 9-6.6Z" fill="#B8893B" />
      {/* H monogram */}
      <path d="M18 27v10M30 27v10M18 32h12" stroke="#F8F4EB" strokeWidth="2.2" strokeLinecap="round" />
    </svg>
  );
}

export function Logo({ light = false }: { light?: boolean }) {
  return (
    <span className="flex items-center gap-2.5">
      <Emblem />
      <span className="leading-none">
        <span className={`block font-display text-[17px] font-semibold tracking-tight ${light ? 'text-ivory' : 'text-forest-900'}`}>
          Harshwardhan
        </span>
        <span className={`mt-0.5 block text-[9.5px] font-semibold uppercase tracking-[0.24em] ${light ? 'text-brass-300' : 'text-brass-600'}`}>
          Institute of Ayurveda
        </span>
      </span>
    </span>
  );
}
