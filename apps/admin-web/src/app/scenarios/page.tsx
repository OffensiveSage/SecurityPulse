/**
 * Scenario management page.
 * Lists all scenarios with status, category, difficulty.
 * Falls back to demo data when backend is unavailable.
 * WCAG 2.2 AA compliant.
 */

'use client';

import { useReducer, useEffect, useState } from 'react';
import Link from 'next/link';
import type { ScenarioAdmin, ScenarioStatus, ScenarioCategory } from '@/lib/types';

// ── Demo data shown when backend is unavailable ───────────────────────────────
const DEMO_SCENARIOS: ScenarioAdmin[] = [
  {
    id: 'demo-1',
    title: 'Suspicious Email from IT Support',
    prompt: "You receive an email from 'IT Support <support@1t-helpdesk.com>' asking you to verify your credentials by clicking a link.",
    category: 'phishing',
    difficulty: 'beginner',
    status: 'published',
    explanation: "The domain '1t-helpdesk.com' uses '1' instead of 'l' — a classic phishing technique.",
    recommendedAction: 'Report to security team without clicking any links.',
    answerOptions: [],
    createdAt: new Date(Date.now() - 7 * 86400000).toISOString(),
    updatedAt: new Date(Date.now() - 7 * 86400000).toISOString(),
  },
  {
    id: 'demo-2',
    title: 'Unexpected MFA Push Notifications',
    prompt: "You receive three MFA push notifications you did not initiate. What do you do?",
    category: 'social_engineering',
    difficulty: 'intermediate',
    status: 'published',
    explanation: 'This is an MFA fatigue attack — attackers flood you with prompts hoping you approve one.',
    recommendedAction: 'Deny all, change your password, and report to security.',
    answerOptions: [],
    createdAt: new Date(Date.now() - 6 * 86400000).toISOString(),
    updatedAt: new Date(Date.now() - 6 * 86400000).toISOString(),
  },
  {
    id: 'demo-3',
    title: 'Uploading Client Data to Public AI',
    prompt: "A colleague pastes client contract details into a public AI chatbot to save time. What should you do?",
    category: 'data_protection',
    difficulty: 'beginner',
    status: 'published',
    explanation: 'Public AI tools may store or use input data for training, violating data protection policies.',
    recommendedAction: 'Report the exposure and advise use of approved tools only.',
    answerOptions: [],
    createdAt: new Date(Date.now() - 5 * 86400000).toISOString(),
    updatedAt: new Date(Date.now() - 5 * 86400000).toISOString(),
  },
  {
    id: 'demo-4',
    title: 'Tailgating into Secure Area',
    prompt: 'Someone in business attire holds the door open for you to enter a restricted server room without badging.',
    category: 'physical_security',
    difficulty: 'intermediate',
    status: 'approved',
    explanation: 'Tailgating bypasses physical access controls regardless of intent.',
    recommendedAction: 'Politely ask them to badge in separately and report if they cannot.',
    answerOptions: [],
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    updatedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
  {
    id: 'demo-5',
    title: 'Password Reuse Across Systems',
    prompt: 'You use the same password for your corporate email and a personal shopping site that just reported a breach.',
    category: 'password_security',
    difficulty: 'beginner',
    status: 'draft',
    explanation: 'Credential stuffing attacks use leaked passwords from one site on others.',
    recommendedAction: 'Change your corporate password immediately and use a password manager.',
    answerOptions: [],
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    updatedAt: new Date(Date.now() - 86400000).toISOString(),
  },
];

// ── Label/badge helpers ────────────────────────────────────────────────────────
const STATUS_LABELS: Record<ScenarioStatus, string> = {
  draft: 'Draft',
  review: 'In Review',
  approved: 'Approved',
  published: 'Published',
  retired: 'Retired',
};

const STATUS_CLASSES: Record<ScenarioStatus, string> = {
  draft: 'bg-zinc-100 text-zinc-600',
  review: 'bg-amber-100 text-amber-700',
  approved: 'bg-blue-100 text-blue-700',
  published: 'bg-green-100 text-green-700',
  retired: 'bg-red-100 text-red-600',
};

const CATEGORY_LABELS: Record<ScenarioCategory, string> = {
  phishing: 'Phishing',
  password_security: 'Password Security',
  social_engineering: 'Social Engineering',
  data_protection: 'Data Protection',
  device_security: 'Device Security',
  physical_security: 'Physical Security',
};

const CATEGORY_CLASSES: Record<ScenarioCategory, string> = {
  phishing: 'bg-orange-100 text-orange-700',
  password_security: 'bg-purple-100 text-purple-700',
  social_engineering: 'bg-red-100 text-red-700',
  data_protection: 'bg-blue-100 text-blue-700',
  device_security: 'bg-teal-100 text-teal-700',
  physical_security: 'bg-zinc-100 text-zinc-700',
};

const DIFFICULTY_CLASSES: Record<string, string> = {
  beginner: 'text-green-600',
  intermediate: 'text-amber-600',
  advanced: 'text-red-600',
};

const STATUS_TABS: Array<{ value: string; label: string }> = [
  { value: 'all', label: 'All' },
  { value: 'draft', label: 'Draft' },
  { value: 'review', label: 'In Review' },
  { value: 'approved', label: 'Approved' },
  { value: 'published', label: 'Published' },
  { value: 'retired', label: 'Retired' },
];

// ── State machine ──────────────────────────────────────────────────────────────
type State =
  | { status: 'loading' }
  | { status: 'demo'; scenarios: ScenarioAdmin[] }
  | { status: 'loaded'; scenarios: ScenarioAdmin[] }
  | { status: 'error'; message: string };

type Action =
  | { type: 'success'; scenarios: ScenarioAdmin[] }
  | { type: 'demo' }
  | { type: 'failure'; message: string };

function reducer(_: State, action: Action): State {
  switch (action.type) {
    case 'success': return { status: 'loaded', scenarios: action.scenarios };
    case 'demo': return { status: 'demo', scenarios: DEMO_SCENARIOS };
    case 'failure': return { status: 'error', message: action.message };
  }
}

// ── Main page ──────────────────────────────────────────────────────────────────
export default function ScenariosPage() {
  const [state, dispatch] = useReducer(reducer, { status: 'loading' });
  const [activeTab, setActiveTab] = useState<string>('all');

  useEffect(() => {
    // Try to fetch from backend; fall back to demo data
    const controller = new AbortController();
    const baseUrl = process.env['NEXT_PUBLIC_API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
    fetch(`${baseUrl}/admin/scenarios?page=1&page_size=50`, { signal: controller.signal })
      .then(async (res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json() as { data: ScenarioAdmin[] };
        dispatch({ type: 'success', scenarios: json.data });
      })
      .catch(() => {
        if (!controller.signal.aborted) dispatch({ type: 'demo' });
      });
    return () => controller.abort();
  }, []);

  const scenarios = state.status === 'loaded' || state.status === 'demo' ? state.scenarios : [];

  const filtered = activeTab === 'all'
    ? scenarios
    : scenarios.filter((s) => s.status === activeTab);

  return (
    <div className="p-8 max-w-7xl">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900">Scenarios</h1>
          <p className="text-sm text-zinc-500 mt-0.5">Manage security awareness training content</p>
        </div>
        <Link
          href="/scenarios/new"
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition-colors"
          aria-label="Create new scenario"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Create Scenario
        </Link>
      </div>

      {/* Demo banner */}
      {state.status === 'demo' && (
        <div role="status" className="mb-5 flex items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          Showing demo data — start the API server to manage real scenarios.
        </div>
      )}

      {/* Status tabs */}
      <div className="flex gap-1 mb-5 border-b border-zinc-200" role="tablist" aria-label="Filter by status">
        {STATUS_TABS.map(({ value, label }) => {
          const count = value === 'all' ? scenarios.length : scenarios.filter(s => s.status === value).length;
          return (
            <button
              key={value}
              role="tab"
              aria-selected={activeTab === value}
              onClick={() => setActiveTab(value)}
              className={[
                'px-3 py-2 text-sm font-medium border-b-2 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500',
                activeTab === value
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-zinc-500 hover:text-zinc-700 hover:border-zinc-300',
              ].join(' ')}
            >
              {label}
              {count > 0 && (
                <span className={`ml-1.5 rounded-full px-1.5 py-0.5 text-xs ${activeTab === value ? 'bg-blue-100 text-blue-600' : 'bg-zinc-100 text-zinc-500'}`}>
                  {count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Loading */}
      {state.status === 'loading' && (
        <div className="space-y-3">
          {[1, 2, 3].map(i => <div key={i} className="h-16 rounded-lg bg-zinc-100 animate-pulse" />)}
        </div>
      )}

      {/* Error */}
      {state.status === 'error' && (
        <div role="alert" className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          {state.message}
        </div>
      )}

      {/* Scenarios table */}
      {(state.status === 'loaded' || state.status === 'demo') && (
        <>
          {filtered.length === 0 ? (
            <div className="rounded-xl border border-zinc-200 bg-white p-12 text-center">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#d1d5db" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="mx-auto mb-3" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
              <p className="text-zinc-500 text-sm">No scenarios with this status.</p>
              {activeTab !== 'all' && (
                <button onClick={() => setActiveTab('all')} className="mt-2 text-sm text-blue-600 hover:underline">View all scenarios</button>
              )}
            </div>
          ) : (
            <div className="rounded-xl border border-zinc-200 bg-white shadow-sm overflow-hidden">
              <table className="w-full text-sm" aria-label="Scenarios">
                <thead>
                  <tr className="border-b border-zinc-100 bg-zinc-50">
                    <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Title</th>
                    <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Category</th>
                    <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Difficulty</th>
                    <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Status</th>
                    <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Created</th>
                    <th scope="col" className="py-3 px-4 text-right font-semibold text-zinc-600">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((s, idx) => (
                    <tr key={s.id} className={`border-b border-zinc-50 hover:bg-zinc-50 transition-colors ${idx % 2 === 0 ? '' : 'bg-zinc-50/50'}`}>
                      <td className="py-3 px-4">
                        <p className="font-medium text-zinc-900 truncate max-w-xs">{s.title}</p>
                        <p className="text-xs text-zinc-400 mt-0.5 truncate max-w-xs">{s.prompt.slice(0, 80)}…</p>
                      </td>
                      <td className="py-3 px-4">
                        <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${CATEGORY_CLASSES[s.category]}`}>
                          {CATEGORY_LABELS[s.category]}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <span className={`text-xs font-medium capitalize ${DIFFICULTY_CLASSES[s.difficulty] ?? 'text-zinc-500'}`}>
                          {s.difficulty}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${STATUS_CLASSES[s.status]}`}>
                          {STATUS_LABELS[s.status]}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-zinc-500 text-xs">
                        {new Date(s.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                      </td>
                      <td className="py-3 px-4 text-right">
                        <Link
                          href={`/scenarios/${s.id}`}
                          className="text-xs font-medium text-blue-600 hover:text-blue-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 rounded"
                          aria-label={`View ${s.title}`}
                        >
                          View
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="px-4 py-3 border-t border-zinc-100 bg-zinc-50 text-xs text-zinc-500">
                {filtered.length} scenario{filtered.length !== 1 ? 's' : ''} {activeTab !== 'all' ? `with status "${STATUS_LABELS[activeTab as ScenarioStatus] ?? activeTab}"` : 'total'}
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
