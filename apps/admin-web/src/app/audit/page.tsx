/**
 * Audit log page.
 * Displays a paginated list of audit events.
 * Requires platform_admin role (enforced server-side).
 */

'use client';

import { useReducer, useEffect, useState } from 'react';
import { fetchAuditEvents } from '@/lib/admin-api';
import type { AuditEvent } from '@/lib/types';
import { ErrorView } from '@/components/ui/ErrorView';
import { LoadingView } from '@/components/ui/LoadingView';
import { EmptyView } from '@/components/ui/EmptyView';
import { UnauthorizedView } from '@/components/ui/UnauthorizedView';
import { ApiClientError } from '@/lib/api-client';

type AuditState =
  | { status: 'loading'; events: AuditEvent[]; totalPages: number; fetchCount: number }
  | { status: 'error'; message: string; events: AuditEvent[]; totalPages: number; fetchCount: number }
  | { status: 'unauthorized'; events: AuditEvent[]; totalPages: number; fetchCount: number }
  | { status: 'loaded'; events: AuditEvent[]; totalPages: number; fetchCount: number };

type AuditAction =
  | { type: 'retry' }
  | { type: 'success'; events: AuditEvent[]; totalPages: number }
  | { type: 'failure'; message: string }
  | { type: 'unauthorized' };

function auditReducer(state: AuditState, action: AuditAction): AuditState {
  switch (action.type) {
    case 'retry':
      return { ...state, status: 'loading', fetchCount: state.fetchCount + 1 };
    case 'success':
      return { status: 'loaded', events: action.events, totalPages: action.totalPages, fetchCount: state.fetchCount };
    case 'failure':
      return { status: 'error', message: action.message, events: state.events, totalPages: state.totalPages, fetchCount: state.fetchCount };
    case 'unauthorized':
      return { status: 'unauthorized', events: [], totalPages: 1, fetchCount: state.fetchCount };
  }
}

export default function AuditPage() {
  const [state, dispatch] = useReducer(auditReducer, {
    status: 'loading',
    events: [],
    totalPages: 1,
    fetchCount: 0,
  });
  const [page, setPage] = useState(1);
  const [actionFilter, setActionFilter] = useState('');

  useEffect(() => {
    let cancelled = false;
    fetchAuditEvents(page, 20, actionFilter || undefined)
      .then((r) => {
        if (!cancelled)
          dispatch({ type: 'success', events: [...r.data], totalPages: r.meta.totalPages });
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          if (err instanceof ApiClientError && err.statusCode === 403) {
            dispatch({ type: 'unauthorized' });
          } else {
            dispatch({
              type: 'failure',
              message: err instanceof Error ? err.message : 'Failed to load audit events',
            });
          }
        }
      });
    return () => {
      cancelled = true;
    };
  }, [page, actionFilter, state.fetchCount]);

  if (state.status === 'unauthorized') return <UnauthorizedView />;

  return (
    <div className="p-8">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-white mb-6">Audit Log</h1>
      <div className="mb-4">
        <label htmlFor="action-filter" className="sr-only">Filter by action</label>
        <input
          id="action-filter"
          placeholder="Filter by action…"
          value={actionFilter}
          onChange={(e) => { setPage(1); setActionFilter(e.target.value); }}
          className="rounded border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-3 py-2 text-sm text-zinc-900 dark:text-white w-64"
        />
      </div>
      {state.status === 'loading' && <LoadingView message="Loading audit events…" />}
      {state.status === 'error' && (
        <ErrorView message={state.message} onRetry={() => dispatch({ type: 'retry' })} />
      )}
      {state.status === 'loaded' && state.events.length === 0 && (
        <EmptyView title="No audit events" message="Audit events will appear here as admins take actions." />
      )}
      {state.status === 'loaded' && state.events.length > 0 && (
        <>
          <table className="w-full text-sm border-collapse" aria-label="Audit event log">
            <thead>
              <tr className="border-b border-zinc-200 dark:border-zinc-700">
                <th scope="col" className="py-2 px-3 text-left font-medium text-zinc-600 dark:text-zinc-400">Timestamp</th>
                <th scope="col" className="py-2 px-3 text-left font-medium text-zinc-600 dark:text-zinc-400">Action</th>
                <th scope="col" className="py-2 px-3 text-left font-medium text-zinc-600 dark:text-zinc-400">Target</th>
              </tr>
            </thead>
            <tbody>
              {state.events.map((ev) => (
                <tr key={ev.id} className="border-b border-zinc-100 dark:border-zinc-800">
                  <td className="py-2 px-3 text-zinc-500 dark:text-zinc-400 whitespace-nowrap">
                    {new Date(ev.timestamp).toLocaleString()}
                  </td>
                  <td className="py-2 px-3 font-mono text-xs text-zinc-900 dark:text-zinc-100">{ev.action}</td>
                  <td className="py-2 px-3 text-zinc-600 dark:text-zinc-400">
                    {ev.targetType ? `${ev.targetType}` : '—'}
                    {ev.targetId ? ` ${ev.targetId.slice(0, 8)}…` : ''}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {state.totalPages > 1 && (
            <nav aria-label="Audit log pagination" className="mt-4 flex gap-2">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="rounded border border-zinc-300 px-3 py-1 text-sm disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label="Previous page"
              >
                Previous
              </button>
              <span className="self-center text-sm text-zinc-600 dark:text-zinc-400">
                Page {page} of {state.totalPages}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(state.totalPages, p + 1))}
                disabled={page === state.totalPages}
                className="rounded border border-zinc-300 px-3 py-1 text-sm disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
                aria-label="Next page"
              >
                Next
              </button>
            </nav>
          )}
        </>
      )}
    </div>
  );
}
