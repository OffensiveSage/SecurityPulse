/**
 * Analytics dashboard page.
 * Displays aggregated security awareness metrics with visual progress bars,
 * KPI cards, and a detailed category breakdown table.
 * Individual-level data is never shown.
 * WCAG 2.2 AA: focus-visible rings, aria labels, semantic table headers.
 * All states: loading, error, empty, loaded.
 */

'use client';

import { useReducer, useEffect, useCallback } from 'react';
import { fetchAnalyticsSummary } from '@/lib/admin-api';
import type { AnalyticsSummary, CategoryAccuracy } from '@/lib/types';

function pct(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`;
}

// ---- Sub-components ----

interface KpiCardProps {
  label: string;
  value: string;
  icon: React.ReactNode;
  accent: string;
  suppressed?: boolean;
}

function KpiCard({ label, value, icon, accent, suppressed }: KpiCardProps) {
  return (
    <div role="region" aria-label={label} className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
      <div className="flex items-start justify-between mb-3">
        <p className="text-sm font-medium text-zinc-500">{label}</p>
        <div className={`rounded-lg p-2 ${accent}`}>{icon}</div>
      </div>
      <p className="text-3xl font-bold text-zinc-900">{suppressed ? '—' : value}</p>
      {suppressed && (
        <p className="mt-1 text-xs text-amber-600">Suppressed: group below minimum size</p>
      )}
    </div>
  );
}

interface CategoryRowProps {
  cat: CategoryAccuracy;
  rank: number;
}

function CategoryRow({ cat, rank }: CategoryRowProps) {
  const pctNum = cat.suppressed ? 0 : cat.accuracyRate * 100;
  const barColor = cat.suppressed
    ? 'bg-zinc-300'
    : pctNum >= 75
    ? 'bg-green-500'
    : pctNum >= 50
    ? 'bg-amber-400'
    : 'bg-red-400';
  const badgeColor = cat.suppressed
    ? 'bg-zinc-100 text-zinc-500'
    : pctNum >= 75
    ? 'bg-green-100 text-green-700'
    : pctNum >= 50
    ? 'bg-amber-100 text-amber-700'
    : 'bg-red-100 text-red-700';
  const label = cat.category.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());

  return (
    <tr className="border-b border-zinc-100 hover:bg-zinc-50 transition-colors">
      <td className="py-3 px-4 text-sm text-zinc-500 w-8 tabular-nums">{rank}</td>
      <td className="py-3 px-4 text-sm font-medium text-zinc-900">{label}</td>
      <td className="py-3 px-4 text-sm text-right text-zinc-700 tabular-nums">{cat.responseCount}</td>
      <td className="py-3 px-4 w-48">
        <div className="h-2 w-full rounded-full bg-zinc-100">
          <div
            className={`h-2 rounded-full transition-all duration-500 ${barColor}`}
            style={{ width: cat.suppressed ? '4px' : `${Math.max(pctNum, 2)}%` }}
            role="presentation"
          />
        </div>
      </td>
      <td className="py-3 px-4 text-sm text-right">
        <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium ${badgeColor}`}>
          {cat.suppressed ? '—' : pct(cat.accuracyRate)}
        </span>
      </td>
    </tr>
  );
}

// ---- CSV export helper ----

function buildCsvFromSummary(summary: AnalyticsSummary): string {
  const rows: string[] = [
    'Metric,Value',
    `Active Employees,${summary.totalEmployeesActive}`,
    `Total Responses,${summary.totalResponses}`,
    `Overall Accuracy,${pct(summary.overallAccuracyRate)}`,
    `Participation Rate,${pct(summary.participationRate)}`,
    '',
    'Category,Response Count,Accuracy Rate,Suppressed',
  ];
  if (summary.byCategory) {
    for (const cat of summary.byCategory) {
      rows.push(
        `${cat.category},${cat.responseCount},${cat.suppressed ? '' : pct(cat.accuracyRate)},${cat.suppressed}`,
      );
    }
  }
  return rows.join('\r\n');
}

function downloadCsv(content: string, filename: string): void {
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

// ---- Reducer ----

type State =
  | { status: 'loading'; fetchCount: number }
  | { status: 'error'; message: string; fetchCount: number }
  | { status: 'loaded'; summary: AnalyticsSummary; fetchCount: number };

type Action =
  | { type: 'retry' }
  | { type: 'success'; summary: AnalyticsSummary }
  | { type: 'failure'; message: string };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'retry':
      return { status: 'loading', fetchCount: state.fetchCount + 1 };
    case 'success':
      return { status: 'loaded', summary: action.summary, fetchCount: state.fetchCount };
    case 'failure':
      return { status: 'error', message: action.message, fetchCount: state.fetchCount };
  }
}

// ---- Page ----

export default function AnalyticsPage() {
  const [state, dispatch] = useReducer(reducer, { status: 'loading', fetchCount: 0 });

  useEffect(() => {
    let cancelled = false;
    fetchAnalyticsSummary()
      .then((summary) => {
        if (!cancelled) dispatch({ type: 'success', summary });
      })
      .catch((err: unknown) => {
        if (!cancelled)
          dispatch({
            type: 'failure',
            message: err instanceof Error ? err.message : 'Failed to load analytics',
          });
      });
    return () => {
      cancelled = true;
    };
  }, [state.fetchCount]);

  const handleExportCsv = useCallback(() => {
    if (state.status !== 'loaded') return;
    const csv = buildCsvFromSummary(state.summary);
    const date = new Date().toISOString().slice(0, 10);
    downloadCsv(csv, `security-pulse-analytics-${date}.csv`);
  }, [state]);

  return (
    <div className="p-8 max-w-6xl">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900">Analytics</h1>
          <p className="text-sm text-zinc-500 mt-0.5">
            Aggregated training metrics — individual data is never displayed.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => dispatch({ type: 'retry' })}
            disabled={state.status === 'loading'}
            aria-label="Refresh analytics data"
            className="inline-flex items-center gap-1.5 rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50 disabled:opacity-50 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 .49-4.5"/>
            </svg>
            {state.status === 'loading' ? 'Refreshing…' : 'Refresh'}
          </button>
          <button
            onClick={handleExportCsv}
            disabled={state.status !== 'loaded'}
            aria-label="Export analytics data as CSV"
            className="inline-flex items-center gap-1.5 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
            </svg>
            Export CSV
          </button>
        </div>
      </div>

      {/* Suppression notice */}
      {state.status === 'loaded' && state.summary.suppressionApplied && (
        <div
          role="alert"
          className="mb-6 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 flex items-start gap-2"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mt-0.5 shrink-0" aria-hidden="true">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
            <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
          </svg>
          <span>
            <strong>Privacy suppression applied.</strong> Some groups fall below the minimum size threshold and their accuracy rates are hidden. Individual data is never shown.
          </span>
        </div>
      )}

      {/* Error state */}
      {state.status === 'error' && (
        <div role="alert" className="mb-6 rounded-xl border border-red-200 bg-red-50 p-6 text-center">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="mx-auto mb-3" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <p className="text-sm font-medium text-red-700 mb-1">Failed to load analytics</p>
          <p className="text-xs text-red-600 mb-4">{state.message}</p>
          <button
            onClick={() => dispatch({ type: 'retry' })}
            className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-500"
          >
            Retry
          </button>
        </div>
      )}

      {/* KPI cards */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 mb-8">
        <KpiCard
          label="Active Employees"
          value={state.status === 'loaded' ? String(state.summary.totalEmployeesActive) : '—'}
          accent="bg-blue-50"
          icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1A56DB" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
          }
        />
        <KpiCard
          label="Total Responses"
          value={state.status === 'loaded' ? String(state.summary.totalResponses) : '—'}
          accent="bg-orange-50"
          icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#c2410c" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
          }
        />
        <KpiCard
          label="Overall Accuracy"
          value={state.status === 'loaded' ? pct(state.summary.overallAccuracyRate) : '—'}
          accent="bg-purple-50"
          icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#7e22ce" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          }
        />
        <KpiCard
          label="Participation Rate"
          value={state.status === 'loaded' ? pct(state.summary.participationRate) : '—'}
          accent="bg-green-50"
          icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#057A55" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
            </svg>
          }
        />
      </div>

      {/* Loading skeleton */}
      {state.status === 'loading' && (
        <div className="rounded-xl border border-zinc-200 bg-white shadow-sm" aria-label="Loading category data" aria-busy="true">
          <div className="px-6 py-4 border-b border-zinc-100">
            <div className="h-5 w-40 rounded bg-zinc-100 animate-pulse" />
          </div>
          <div className="p-6 space-y-4">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="flex items-center gap-4">
                <div className="h-4 w-6 rounded bg-zinc-100 animate-pulse" />
                <div className="h-4 flex-1 rounded bg-zinc-100 animate-pulse" />
                <div className="h-4 w-16 rounded bg-zinc-100 animate-pulse" />
                <div className="h-3 w-32 rounded-full bg-zinc-100 animate-pulse" />
                <div className="h-5 w-14 rounded-full bg-zinc-100 animate-pulse" />
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Category breakdown table */}
      {state.status === 'loaded' && (
        <section aria-label="Category breakdown">
          <div className="rounded-xl border border-zinc-200 bg-white shadow-sm overflow-hidden">
            <div className="px-6 py-4 border-b border-zinc-100 flex items-center justify-between">
              <h2 className="text-base font-semibold text-zinc-900">Accuracy by Category</h2>
              <div className="flex items-center gap-4 text-xs text-zinc-500">
                <span className="flex items-center gap-1">
                  <span className="w-3 h-3 rounded-full bg-green-500 inline-block" aria-hidden="true" />
                  High (&ge;75%)
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-3 h-3 rounded-full bg-amber-400 inline-block" aria-hidden="true" />
                  Medium (50–75%)
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-3 h-3 rounded-full bg-red-400 inline-block" aria-hidden="true" />
                  Low (&lt;50%)
                </span>
              </div>
            </div>

            {state.summary.byCategory && state.summary.byCategory.length > 0 ? (
              <table className="w-full text-sm" aria-label="Accuracy by category">
                <thead>
                  <tr className="border-b border-zinc-100 bg-zinc-50">
                    <th scope="col" className="py-3 px-4 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider w-8">#</th>
                    <th scope="col" className="py-3 px-4 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider">Category</th>
                    <th scope="col" className="py-3 px-4 text-right text-xs font-semibold text-zinc-500 uppercase tracking-wider">Responses</th>
                    <th scope="col" className="py-3 px-4 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wider w-48">Pass Rate</th>
                    <th scope="col" className="py-3 px-4 text-right text-xs font-semibold text-zinc-500 uppercase tracking-wider">Accuracy</th>
                  </tr>
                </thead>
                <tbody>
                  {state.summary.byCategory.map((cat, i) => (
                    <CategoryRow key={cat.category} cat={cat} rank={i + 1} />
                  ))}
                </tbody>
              </table>
            ) : (
              <div className="px-6 py-12 text-center">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#d4d4d8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="mx-auto mb-3" aria-hidden="true">
                  <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>
                </svg>
                <p className="text-sm font-medium text-zinc-500">No category data yet</p>
                <p className="text-xs text-zinc-400 mt-1">
                  Complete more scenarios to see the category breakdown.
                </p>
              </div>
            )}
          </div>
        </section>
      )}
    </div>
  );
}
