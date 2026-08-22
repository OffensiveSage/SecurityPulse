/**
 * Dashboard overview page.
 * Shows KPI cards, category accuracy bars, quick actions, and platform status.
 * Handles loading, error, and loaded states gracefully.
 * Individual-level data is never displayed.
 * WCAG 2.2 AA: all interactive elements have aria labels and focus-visible rings.
 */

'use client';

import { useReducer, useEffect } from 'react';
import Link from 'next/link';
import { fetchAnalyticsSummary } from '@/lib/admin-api';
import type { AnalyticsSummary } from '@/lib/types';

function pct(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`;
}

interface KpiCardProps {
  label: string;
  value: string;
  icon: React.ReactNode;
  color: string;
  subtitle?: string;
}

function KpiCard({ label, value, icon, color, subtitle }: KpiCardProps) {
  return (
    <div role="region" aria-label={label} className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-zinc-500">{label}</p>
          <p className="mt-1 text-3xl font-bold text-zinc-900">{value}</p>
          {subtitle && <p className="mt-1 text-xs text-zinc-400">{subtitle}</p>}
        </div>
        <div className={`rounded-lg p-2.5 ${color}`}>{icon}</div>
      </div>
    </div>
  );
}

interface CategoryBarProps {
  category: string;
  rate: number;
  count: number;
  suppressed: boolean;
}

function CategoryBar({ category, rate, count, suppressed }: CategoryBarProps) {
  const pctNum = suppressed ? 0 : rate * 100;
  const barColor = suppressed
    ? 'bg-zinc-300'
    : pctNum >= 75
    ? 'bg-green-500'
    : pctNum >= 50
    ? 'bg-amber-400'
    : 'bg-red-400';
  const label = category.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between text-sm">
        <span className="font-medium text-zinc-700">{label}</span>
        <span className="text-zinc-500">
          {suppressed ? '—' : pct(rate)} · {count} responses
        </span>
      </div>
      <div className="h-2 w-full rounded-full bg-zinc-100" role="presentation">
        <div
          className={`h-2 rounded-full transition-all duration-500 ${barColor}`}
          style={{ width: suppressed ? '4px' : `${Math.max(pctNum, 2)}%` }}
          aria-label={`${label}: ${suppressed ? 'suppressed' : pct(rate)}`}
        />
      </div>
    </div>
  );
}

type State =
  | { status: 'loading'; fetchCount: number }
  | { status: 'error'; fetchCount: number }
  | { status: 'loaded'; summary: AnalyticsSummary; fetchCount: number };

type Action =
  | { type: 'retry' }
  | { type: 'success'; summary: AnalyticsSummary }
  | { type: 'failure' };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'retry':
      return { status: 'loading', fetchCount: state.fetchCount + 1 };
    case 'success':
      return { status: 'loaded', summary: action.summary, fetchCount: state.fetchCount };
    case 'failure':
      return { status: 'error', fetchCount: state.fetchCount };
  }
}

const QUICK_ACTIONS = [
  {
    href: '/scenarios/new',
    label: 'Create Scenario',
    desc: 'Add new training content',
    color: 'text-blue-600',
    bg: 'bg-blue-50 hover:bg-blue-100',
  },
  {
    href: '/campaigns',
    label: 'New Campaign',
    desc: 'Launch a training campaign',
    color: 'text-purple-600',
    bg: 'bg-purple-50 hover:bg-purple-100',
  },
  {
    href: '/reports',
    label: 'Export Report',
    desc: 'Download compliance report',
    color: 'text-green-600',
    bg: 'bg-green-50 hover:bg-green-100',
  },
  {
    href: '/audit',
    label: 'Audit Log',
    desc: 'Review admin activity',
    color: 'text-zinc-600',
    bg: 'bg-zinc-50 hover:bg-zinc-100',
  },
] as const;

export default function DashboardPage() {
  const [state, dispatch] = useReducer(reducer, { status: 'loading', fetchCount: 0 });

  useEffect(() => {
    let cancelled = false;
    fetchAnalyticsSummary()
      .then((summary) => {
        if (!cancelled) dispatch({ type: 'success', summary });
      })
      .catch(() => {
        if (!cancelled) dispatch({ type: 'failure' });
      });
    return () => {
      cancelled = true;
    };
  }, [state.fetchCount]);

  const today = new Date().toLocaleDateString('en-GB', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  return (
    <div className="p-8 max-w-7xl">
      {/* Page header */}
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900">Dashboard</h1>
          <p className="text-sm text-zinc-500 mt-0.5">{today}</p>
        </div>
        <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-100 px-3 py-1 text-xs font-medium text-amber-700">
          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 inline-block" aria-hidden="true" />
          Development mode
        </span>
      </div>

      {/* Error banner */}
      {state.status === 'error' && (
        <div
          role="alert"
          className="mb-6 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 flex items-center gap-2"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          Backend unavailable — connect the API server to see live data.
          <button
            onClick={() => dispatch({ type: 'retry' })}
            className="ml-auto text-xs font-medium underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-amber-600"
            aria-label="Retry loading analytics data"
          >
            Retry
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Left / main column */}
        <div className="lg:col-span-2 space-y-6">

          {/* KPI cards */}
          <div className="grid grid-cols-2 gap-4">
            <KpiCard
              label="Active Employees"
              value={state.status === 'loaded' ? String(state.summary.totalEmployeesActive) : '—'}
              subtitle="enrolled in training"
              color="bg-blue-50"
              icon={
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1A56DB" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                  <circle cx="9" cy="7" r="4"/>
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                  <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
              }
            />
            <KpiCard
              label="Participation Rate"
              value={state.status === 'loaded' ? pct(state.summary.participationRate) : '—'}
              subtitle="of enrolled employees"
              color="bg-green-50"
              icon={
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#057A55" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                </svg>
              }
            />
            <KpiCard
              label="Overall Accuracy"
              value={state.status === 'loaded' ? pct(state.summary.overallAccuracyRate) : '—'}
              subtitle="correct answers"
              color="bg-purple-50"
              icon={
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7e22ce" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <polyline points="20 6 9 17 4 12"/>
                </svg>
              }
            />
            <KpiCard
              label="Total Responses"
              value={state.status === 'loaded' ? String(state.summary.totalResponses) : '—'}
              subtitle="answers submitted"
              color="bg-orange-50"
              icon={
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#c2410c" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                </svg>
              }
            />
          </div>

          {/* Category accuracy */}
          <section aria-label="Accuracy by category" className="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-base font-semibold text-zinc-900">Accuracy by Category</h2>
              {state.status === 'loaded' && state.summary.suppressionApplied && (
                <span className="text-xs text-amber-600 bg-amber-50 border border-amber-200 rounded-full px-2 py-0.5">
                  Some groups suppressed
                </span>
              )}
            </div>

            {state.status === 'loading' && (
              <div className="space-y-4" aria-label="Loading category data">
                {[1, 2, 3, 4].map((i) => (
                  <div key={i} className="h-8 rounded bg-zinc-100 animate-pulse" />
                ))}
              </div>
            )}

            {state.status === 'loaded' &&
              state.summary.byCategory &&
              state.summary.byCategory.length > 0 && (
                <div className="space-y-4">
                  {state.summary.byCategory.map((cat) => (
                    <CategoryBar
                      key={cat.category}
                      category={cat.category}
                      rate={cat.accuracyRate}
                      count={cat.responseCount}
                      suppressed={cat.suppressed}
                    />
                  ))}
                </div>
              )}

            {state.status === 'loaded' &&
              (!state.summary.byCategory || state.summary.byCategory.length === 0) && (
                <p className="text-sm text-zinc-500 text-center py-6">
                  No category data yet. Complete more scenarios to see breakdown.
                </p>
              )}

            {state.status === 'error' && (
              <p className="text-sm text-zinc-400 text-center py-6">
                Connect the backend to see category breakdown.
              </p>
            )}
          </section>
        </div>

        {/* Right column */}
        <div className="space-y-6">

          {/* Quick actions */}
          <section aria-label="Quick actions" className="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 className="text-base font-semibold text-zinc-900 mb-4">Quick Actions</h2>
            <div className="space-y-2">
              {QUICK_ACTIONS.map(({ href, label, desc, color, bg }) => (
                <Link
                  key={href}
                  href={href}
                  aria-label={label}
                  className={`flex items-start gap-3 rounded-lg p-3 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-blue-500 ${bg}`}
                >
                  <div className="flex-1 min-w-0">
                    <p className={`text-sm font-medium ${color}`}>{label}</p>
                    <p className="text-xs text-zinc-500 mt-0.5">{desc}</p>
                  </div>
                  <svg
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="mt-0.5 text-zinc-400 shrink-0"
                    aria-hidden="true"
                  >
                    <polyline points="9 18 15 12 9 6"/>
                  </svg>
                </Link>
              ))}
            </div>
          </section>

          {/* Platform status */}
          <section aria-label="Platform status" className="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 className="text-base font-semibold text-zinc-900 mb-4">Platform Status</h2>
            <div className="space-y-3">
              {(
                [
                  {
                    label: 'API Server',
                    status:
                      state.status === 'loaded'
                        ? 'online'
                        : state.status === 'error'
                        ? 'offline'
                        : 'checking',
                  },
                  {
                    label: 'Database',
                    status:
                      state.status === 'loaded'
                        ? 'online'
                        : state.status === 'error'
                        ? 'unknown'
                        : 'checking',
                  },
                  { label: 'Notifications', status: 'pending_config' },
                  { label: 'Auth Provider', status: 'dev_mock' },
                ] as const
              ).map(({ label, status }) => (
                <div key={label} className="flex items-center justify-between">
                  <span className="text-sm text-zinc-600">{label}</span>
                  <span
                    className={`inline-flex items-center gap-1.5 text-xs font-medium rounded-full px-2 py-0.5 ${
                      status === 'online'
                        ? 'bg-green-100 text-green-700'
                        : status === 'offline'
                        ? 'bg-red-100 text-red-700'
                        : status === 'checking'
                        ? 'bg-zinc-100 text-zinc-500'
                        : status === 'dev_mock'
                        ? 'bg-blue-100 text-blue-700'
                        : 'bg-amber-100 text-amber-700'
                    }`}
                  >
                    <span
                      className={`w-1.5 h-1.5 rounded-full ${
                        status === 'online'
                          ? 'bg-green-500'
                          : status === 'offline'
                          ? 'bg-red-500'
                          : status === 'checking'
                          ? 'bg-zinc-400'
                          : status === 'dev_mock'
                          ? 'bg-blue-500'
                          : 'bg-amber-500'
                      }`}
                      aria-hidden="true"
                    />
                    {status === 'online'
                      ? 'Online'
                      : status === 'offline'
                      ? 'Offline'
                      : status === 'checking'
                      ? 'Checking'
                      : status === 'dev_mock'
                      ? 'Mock'
                      : status === 'unknown'
                      ? 'Unknown'
                      : 'Config needed'}
                  </span>
                </div>
              ))}
            </div>
          </section>

          {/* Setup checklist */}
          <section aria-label="Setup checklist" className="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 className="text-base font-semibold text-zinc-900 mb-4">Setup Checklist</h2>
            <div className="space-y-2.5">
              {(
                [
                  { label: 'Backend API running', done: state.status === 'loaded' },
                  { label: 'Scenarios created', done: false },
                  { label: 'Auth provider configured', done: false },
                  { label: 'First campaign launched', done: false },
                ] as const
              ).map(({ label, done }) => (
                <div key={label} className="flex items-center gap-2.5">
                  <div
                    className={`w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 ${
                      done ? 'bg-green-500 border-green-500' : 'border-zinc-300'
                    }`}
                    aria-hidden="true"
                  >
                    {done && (
                      <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <polyline points="20 6 9 17 4 12"/>
                      </svg>
                    )}
                  </div>
                  <span className={`text-sm ${done ? 'line-through text-zinc-400' : 'text-zinc-600'}`}>
                    {label}
                  </span>
                  <span className="sr-only">{done ? '(complete)' : '(incomplete)'}</span>
                </div>
              ))}
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
