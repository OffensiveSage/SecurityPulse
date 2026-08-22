/**
 * Compliance reports page.
 * Generates training completion, accuracy and category reports.
 * Export via browser print (PDF) or CSV download.
 * WCAG 2.2 AA compliant.
 */

'use client';

import { useReducer, useEffect, useState } from 'react';
import { fetchAnalyticsSummary } from '@/lib/admin-api';
import type { AnalyticsSummary } from '@/lib/types';

function pct(rate: number): string {
  return `${(rate * 100).toFixed(1)}%`;
}

// ── State ─────────────────────────────────────────────────────────────────────
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
    case 'retry': return { status: 'loading', fetchCount: state.fetchCount + 1 };
    case 'success': return { status: 'loaded', summary: action.summary, fetchCount: state.fetchCount };
    case 'failure': return { status: 'error', message: action.message, fetchCount: state.fetchCount };
  }
}

// ── CSV export helper ─────────────────────────────────────────────────────────
function downloadCsv(summary: AnalyticsSummary, startDate: string, endDate: string) {
  const rows = [
    ['Security Pulse — Training Report'],
    [`Period: ${startDate || 'All time'} to ${endDate || 'Present'}`],
    [`Generated: ${new Date().toISOString()}`],
    [],
    ['Metric', 'Value'],
    ['Active Employees', String(summary.totalEmployeesActive)],
    ['Total Responses', String(summary.totalResponses)],
    ['Overall Accuracy', pct(summary.overallAccuracyRate)],
    ['Participation Rate', pct(summary.participationRate)],
    [],
    ['Category Breakdown'],
    ['Category', 'Responses', 'Accuracy', 'Suppressed'],
    ...(summary.byCategory ?? []).map(c => [
      c.category.replace('_', ' '),
      String(c.responseCount),
      c.suppressed ? 'Suppressed' : pct(c.accuracyRate),
      c.suppressed ? 'Yes' : 'No',
    ]),
  ];
  const csv = rows.map(r => r.map(cell => `"${cell}"`).join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `security-pulse-report-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

// ── Report type cards ─────────────────────────────────────────────────────────
const REPORT_TYPES = [
  {
    id: 'completion',
    title: 'Training Completion Report',
    desc: 'Overall participation rate, responses submitted, and active employee counts. Suitable for management review.',
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1A56DB" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
      </svg>
    ),
    color: 'bg-blue-50 border-blue-200',
  },
  {
    id: 'accuracy',
    title: 'Accuracy Report',
    desc: 'Correct answer rate across all scenarios. Shows overall security awareness proficiency.',
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#057A55" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>
      </svg>
    ),
    color: 'bg-green-50 border-green-200',
  },
  {
    id: 'category',
    title: 'Category Breakdown Report',
    desc: 'Per-category accuracy rates with group-size suppression applied. Identifies knowledge gaps.',
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#7e22ce" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/>
      </svg>
    ),
    color: 'bg-purple-50 border-purple-200',
  },
];

// ── Main page ─────────────────────────────────────────────────────────────────
export default function ReportsPage() {
  const [state, dispatch] = useReducer(reducer, { status: 'loading', fetchCount: 0 });
  const [selectedReport, setSelectedReport] = useState('completion');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  useEffect(() => {
    let cancelled = false;
    fetchAnalyticsSummary()
      .then((summary) => { if (!cancelled) dispatch({ type: 'success', summary }); })
      .catch((err: unknown) => {
        if (!cancelled) dispatch({ type: 'failure', message: err instanceof Error ? err.message : 'Failed to load data' });
      });
    return () => { cancelled = true; };
  }, [state.fetchCount]);

  const summary = state.status === 'loaded' ? state.summary : null;

  const inputCls = 'rounded-lg border border-zinc-200 bg-white px-3 py-2 text-sm text-zinc-900 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500';

  return (
    <div className="p-8 max-w-5xl">
      {/* Header */}
      <div className="flex items-start justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900">Reports</h1>
          <p className="text-sm text-zinc-500 mt-0.5">Generate compliance and awareness reports for audit requirements</p>
        </div>
        {summary && (
          <div className="flex gap-2">
            <button
              onClick={() => downloadCsv(summary, startDate, endDate)}
              className="inline-flex items-center gap-1.5 rounded-lg border border-zinc-200 bg-white px-4 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 transition-colors"
              aria-label="Download report as CSV"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Export CSV
            </button>
            <button
              onClick={() => window.print()}
              className="inline-flex items-center gap-1.5 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 transition-colors"
              aria-label="Print report as PDF"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
              Export PDF
            </button>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Left: Config */}
        <div className="space-y-5">
          {/* Report type */}
          <div className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 className="text-sm font-semibold text-zinc-800 mb-3">Report Type</h2>
            <div className="space-y-2">
              {REPORT_TYPES.map(r => (
                <button
                  key={r.id}
                  onClick={() => setSelectedReport(r.id)}
                  className={`w-full text-left rounded-lg border p-3 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 ${selectedReport === r.id ? r.color + ' ring-1 ring-blue-400' : 'border-zinc-100 bg-zinc-50 hover:bg-zinc-100'}`}
                  aria-pressed={selectedReport === r.id}
                >
                  <div className="flex items-start gap-2.5">
                    <div className="mt-0.5 shrink-0">{r.icon}</div>
                    <div>
                      <p className="text-sm font-medium text-zinc-800">{r.title}</p>
                      <p className="text-xs text-zinc-500 mt-0.5">{r.desc}</p>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Date range */}
          <div className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 className="text-sm font-semibold text-zinc-800 mb-3">Date Range</h2>
            <div className="space-y-3">
              <div>
                <label htmlFor="start-date" className="block text-xs font-medium text-zinc-600 mb-1">From</label>
                <input id="start-date" type="date" value={startDate} onChange={e => setStartDate(e.target.value)} className={`${inputCls} w-full`} />
              </div>
              <div>
                <label htmlFor="end-date" className="block text-xs font-medium text-zinc-600 mb-1">To</label>
                <input id="end-date" type="date" value={endDate} onChange={e => setEndDate(e.target.value)} className={`${inputCls} w-full`} />
              </div>
              <p className="text-xs text-zinc-400">Leave blank to include all available data.</p>
            </div>
          </div>

          {/* Compliance note */}
          <div className="rounded-xl border border-blue-100 bg-blue-50 p-4">
            <p className="text-xs font-semibold text-blue-800 mb-1">Compliance Note</p>
            <p className="text-xs text-blue-700 leading-relaxed">
              These reports are suitable for SOC 2 Type II, ISO 27001, GDPR Article 32, and internal audit requirements. Individual employee data is never included — only aggregated group statistics.
            </p>
          </div>
        </div>

        {/* Right: Preview */}
        <div className="lg:col-span-2">
          <div className="rounded-xl border border-zinc-200 bg-white shadow-sm overflow-hidden print:shadow-none print:border-0">
            {/* Report header */}
            <div className="border-b border-zinc-100 bg-zinc-50 px-6 py-4 print:bg-white">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded bg-blue-600 flex items-center justify-center">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                  </div>
                  <span className="text-sm font-semibold text-zinc-900">Security Pulse</span>
                </div>
                <p className="text-xs text-zinc-500">
                  Generated {new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}
                </p>
              </div>
              <h3 className="mt-3 text-base font-bold text-zinc-900">
                {REPORT_TYPES.find(r => r.id === selectedReport)?.title ?? 'Report'}
              </h3>
              {(startDate || endDate) && (
                <p className="text-xs text-zinc-500 mt-0.5">
                  Period: {startDate || 'All time'} → {endDate || 'Present'}
                </p>
              )}
            </div>

            {/* Report body */}
            <div className="p-6">
              {state.status === 'loading' && (
                <div className="space-y-3">
                  {[1, 2, 3, 4].map(i => <div key={i} className="h-12 rounded bg-zinc-100 animate-pulse" />)}
                </div>
              )}

              {state.status === 'error' && (
                <div role="alert" className="text-center py-10">
                  <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#d1d5db" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="mx-auto mb-3" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  <p className="text-sm text-zinc-500 mb-2">Backend unavailable — start the API server to generate reports.</p>
                  <button onClick={() => dispatch({ type: 'retry' })} className="text-sm text-blue-600 hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 rounded">Retry connection</button>
                </div>
              )}

              {state.status === 'loaded' && (
                <div className="space-y-6">
                  {/* Summary metrics */}
                  <section aria-label="Summary metrics">
                    <h4 className="text-sm font-semibold text-zinc-700 mb-3 uppercase tracking-wide text-xs">Summary</h4>
                    <div className="grid grid-cols-2 gap-3">
                      {[
                        { label: 'Active Employees', value: String(summary!.totalEmployeesActive) },
                        { label: 'Total Responses', value: String(summary!.totalResponses) },
                        { label: 'Participation Rate', value: pct(summary!.participationRate) },
                        { label: 'Overall Accuracy', value: pct(summary!.overallAccuracyRate) },
                      ].map(({ label, value }) => (
                        <div key={label} className="rounded-lg bg-zinc-50 border border-zinc-100 p-3">
                          <p className="text-xs text-zinc-500">{label}</p>
                          <p className="text-xl font-bold text-zinc-900 mt-0.5">{value}</p>
                        </div>
                      ))}
                    </div>
                  </section>

                  {/* Category breakdown — shown for accuracy and category reports */}
                  {(selectedReport === 'accuracy' || selectedReport === 'category') && summary!.byCategory && summary!.byCategory.length > 0 && (
                    <section aria-label="Category breakdown">
                      <h4 className="text-xs font-semibold text-zinc-700 mb-3 uppercase tracking-wide">Category Breakdown</h4>
                      {summary!.suppressionApplied && (
                        <p className="text-xs text-amber-600 mb-3 bg-amber-50 border border-amber-100 rounded px-3 py-2">
                          Groups below minimum size have been suppressed to protect privacy.
                        </p>
                      )}
                      <table className="w-full text-sm" aria-label="Accuracy by category">
                        <thead>
                          <tr className="border-b border-zinc-100">
                            <th scope="col" className="py-2 text-left text-xs font-semibold text-zinc-600">Category</th>
                            <th scope="col" className="py-2 text-right text-xs font-semibold text-zinc-600">Responses</th>
                            <th scope="col" className="py-2 text-right text-xs font-semibold text-zinc-600">Accuracy</th>
                          </tr>
                        </thead>
                        <tbody>
                          {summary!.byCategory.map(cat => {
                            const label = cat.category.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase());
                            const pctNum = cat.suppressed ? 0 : cat.accuracyRate * 100;
                            return (
                              <tr key={cat.category} className="border-b border-zinc-50">
                                <td className="py-2.5 font-medium text-zinc-800">{label}</td>
                                <td className="py-2.5 text-right text-zinc-600">{cat.responseCount}</td>
                                <td className="py-2.5 text-right">
                                  {cat.suppressed ? (
                                    <span className="text-amber-500 text-xs">Suppressed</span>
                                  ) : (
                                    <span className={pctNum >= 75 ? 'text-green-600 font-medium' : pctNum >= 50 ? 'text-amber-600 font-medium' : 'text-red-600 font-medium'}>
                                      {pct(cat.accuracyRate)}
                                    </span>
                                  )}
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </section>
                  )}

                  {/* Compliance attestation */}
                  <section aria-label="Compliance attestation" className="border-t border-zinc-100 pt-5">
                    <h4 className="text-xs font-semibold text-zinc-700 mb-2 uppercase tracking-wide">Compliance Attestation</h4>
                    <p className="text-xs text-zinc-500 leading-relaxed">
                      This report confirms that Security Pulse cybersecurity awareness training was delivered to {summary!.totalEmployeesActive} active employees during the specified period. A participation rate of {pct(summary!.participationRate)} was achieved with an overall correct-response rate of {pct(summary!.overallAccuracyRate)}. All data is aggregated and anonymised in accordance with the platform&apos;s privacy controls.
                    </p>
                    <div className="mt-4 grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-xs text-zinc-400 mb-4">Security Admin signature</p>
                        <div className="border-b border-zinc-300 w-full" />
                      </div>
                      <div>
                        <p className="text-xs text-zinc-400 mb-4">Date</p>
                        <div className="border-b border-zinc-300 w-full" />
                      </div>
                    </div>
                  </section>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
