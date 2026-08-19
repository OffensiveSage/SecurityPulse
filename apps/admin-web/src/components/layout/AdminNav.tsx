/**
 * Admin navigation sidebar.
 * Provides links to analytics, campaigns, and audit log pages.
 * WCAG 2.2 AA: keyboard-navigable, aria-current for active links.
 */

'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const NAV_ITEMS = [
  { href: '/analytics', label: 'Analytics', ariaLabel: 'Analytics dashboard' },
  { href: '/campaigns', label: 'Campaigns', ariaLabel: 'Campaign management' },
  { href: '/audit', label: 'Audit Log', ariaLabel: 'Audit event log' },
] as const;

export function AdminNav() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Admin navigation"
      className="flex flex-col gap-1 p-4 bg-zinc-900 min-h-full w-48 shrink-0"
    >
      <span className="text-xs font-semibold text-zinc-400 uppercase tracking-wider mb-3 px-2">
        Security Pulse
      </span>
      {NAV_ITEMS.map(({ href, label, ariaLabel }) => {
        const isActive = pathname === href || pathname.startsWith(href + '/');
        return (
          <Link
            key={href}
            href={href}
            aria-label={ariaLabel}
            aria-current={isActive ? 'page' : undefined}
            className={[
              'rounded px-3 py-2 text-sm font-medium transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500',
              isActive
                ? 'bg-zinc-700 text-white'
                : 'text-zinc-300 hover:bg-zinc-800 hover:text-white',
            ].join(' ')}
          >
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
