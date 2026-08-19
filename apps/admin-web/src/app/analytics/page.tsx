/**
 * Analytics dashboard page.
 * Displays aggregated security awareness metrics.
 * Individual-level data is never shown.
 * All states: loading, error, empty, loaded.
 */

'use client';

import { useReducer, useEffect } from 'react';
import { fetchAnalyticsSummary } from '@/lib/admin-api';
import type { AnalyticsSummary } from '@/lib/types';
import { ErrorView } from '@/components/ui/ErrorView';
import { LoadingView } from '@/components/ui/LoadingView';

function pct(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`;
}

interface StatCardProps {
  label: string;
  value: string;
  suppressed?: boolean;
}

function StatCard({ label, value, suppressed }: StatCardProps) {
  return (
    <div
      role="region"
      aria-label={label}
      className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-700 dark:bg-zinc-800"
    >
      <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">{label}</p>
      <p className="mt-1 text-3xl font-semibold text-zinc-900 dark:text-white">
        {suppressed ? '—' : value}
      </p>
      {suppressed && (
        <p className="mt-1 text-xs text-amber-600 dark:text-amber-400">
          Suppressed: group below minimum size
        </p>
      )}
    </div>
  );
}

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

  if (state.status === 'loading') return <LoadingView message="Loading analytics…" />;
  if (state.status === 'error')
    return (
      <ErrorView
        message={state.message}
        onRetry={() => dispatch({ type: 'retry' })}
      />
    );

  const { summary } = state;

  return (
    <div className="p-8">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-white mb-6">
        Analytics
      </h1>
      {summary.suppressionApplied && (
        <div
          role="alert"
          className="mb-6 rounded border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-700 dark:bg-amber-900/30 dark:text-amber-300"
        >
          Some groups have been suppressed because they fall below the minimum group size. Individual data is never shown.
        </div>
      )}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 mb-8">
        <StatCard label="Active Employees" value={String(summary.totalEmployeesActive)} />
        <StatCard label="Total Responses" value={String(summary.totalResponses)} />
        <StatCard label="Overall Accuracy" value={pct(summary.overallAccuracyRate)} />
        <StatCard label="Participation Rate" value={pct(summary.participationRate)} />
      </div>
      {summary.byCategory && summary.byCategory.length > 0 && (
        <section aria-label="Category breakdown">
          <h2 className="text-lg font-semibold text-zinc-800 dark:text-zinc-200 mb-3">
            By Category
          </h2>
          <table className="w-full text-sm border-collapse" aria-label="Accuracy by category">
            <thead>
              <tr className="border-b border-zinc-200 dark:border-zinc-700">
                <th scope="col" className="py-2 px-3 text-left font-medium text-zinc-600 dark:text-zinc-400">Category</th>
                <th scope="col" className="py-2 px-3 text-right font-medium text-zinc-600 dark:text-zinc-400">Responses</th>
                <th scope="col" className="py-2 px-3 text-right font-medium text-zinc-600 dark:text-zinc-400">Accuracy</th>
              </tr>
            </thead>
            <tbody>
              {summary.byCategory.map((cat) => (
                <tr key={cat.category} className="border-b border-zinc-100 dark:border-zinc-800">
                  <td className="py-2 px-3 text-zinc-900 dark:text-zinc-100">{cat.category}</td>
                  <td className="py-2 px-3 text-right text-zinc-700 dark:text-zinc-300">{cat.responseCount}</td>
                  <td className="py-2 px-3 text-right text-zinc-700 dark:text-zinc-300">
                    {cat.suppressed ? (
                      <span className="text-amber-600 dark:text-amber-400" aria-label="Suppressed">—</span>
                    ) : pct(cat.accuracyRate)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}
    </div>
  );
}
