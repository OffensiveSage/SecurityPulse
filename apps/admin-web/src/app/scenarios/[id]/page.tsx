/**
 * Scenario detail page.
 * Displays full scenario content, answer options, and status workflow.
 * Status transition buttons are mocked until the API supports them.
 * WCAG 2.2 AA compliant.
 */

'use client';

import { useReducer, useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { apiFetch, ApiClientError } from '@/lib/api-client';
import type { ScenarioAdmin, ScenarioCategory, ScenarioDifficulty, ScenarioStatus } from '@/lib/types';

// ── Helpers ────────────────────────────────────────────────────────────────────
function toScenarioAdmin(raw: Record<string, unknown>): ScenarioAdmin {
  return {
    id: raw['id'] as string,
    title: raw['title'] as string,
    prompt: raw['prompt'] as string,
    category: raw['category'] as ScenarioCategory,
    difficulty: raw['difficulty'] as ScenarioDifficulty,
    status: (raw['status'] as ScenarioStatus | undefined) ?? 'published',
    explanation: raw['explanation'] as string,
    recommendedAction: (raw['recommended_action'] as string | undefined) ?? '',
    answerOptions: ((raw['answer_options'] as Array<Record<string, unknown>>) ?? []).map((o) => ({
      id: o['id'] as string,
      text: o['text'] as string,
      isCorrect: o['is_correct'] as boolean,
      displayOrder: (o['display_order'] as number) ?? 0,
    })),
    createdAt: (raw['created_at'] as string | undefined) ?? '',
    updatedAt: (raw['updated_at'] as string | undefined) ?? '',
  };
}

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

const DIFFICULTY_CLASSES: Record<ScenarioDifficulty, string> = {
  beginner: 'bg-green-100 text-green-700',
  intermediate: 'bg-amber-100 text-amber-700',
  advanced: 'bg-red-100 text-red-700',
};

const NEXT_ACTION: Partial<Record<ScenarioStatus, string>> = {
  draft: 'Send for Review',
  review: 'Approve',
  approved: 'Publish',
  published: 'Retire',
};

// ── State machine ──────────────────────────────────────────────────────────────
type State =
  | { status: 'loading' }
  | { status: 'loaded'; scenario: ScenarioAdmin }
  | { status: 'notFound' }
  | { status: 'error'; message: string };

type Action =
  | { type: 'success'; scenario: ScenarioAdmin }
  | { type: 'notFound' }
  | { type: 'failure'; message: string };

function reducer(_: State, action: Action): State {
  switch (action.type) {
    case 'success': return { status: 'loaded', scenario: action.scenario };
    case 'notFound': return { status: 'notFound' };
    case 'failure': return { status: 'error', message: action.message };
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────────
function SectionCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
      <h2 className="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-3">{title}</h2>
      {children}
    </div>
  );
}

// ── Main page ──────────────────────────────────────────────────────────────────
export default function ScenarioDetailPage() {
  const params = useParams();
  const id = typeof params['id'] === 'string' ? params['id'] : Array.isArray(params['id']) ? params['id'][0] : '';

  const [state, dispatch] = useReducer(reducer, { status: 'loading' });
  const [toast, setToast] = useState<string | null>(null);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
  }, []);

  // Auto-dismiss toast after 3 s
  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(null), 3000);
    return () => clearTimeout(t);
  }, [toast]);

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    // The backend only exposes /scenarios/{id} via the employee endpoint.
    // A dedicated admin endpoint does not yet exist; mock-employee reads any
    // assigned scenario. Status workflow buttons are already mocked.
    apiFetch<Record<string, unknown>>(`/scenarios/${id}`, {}, 'mock-employee')
      .then((raw) => {
        if (!cancelled) dispatch({ type: 'success', scenario: toScenarioAdmin(raw) });
      })
      .catch((err: unknown) => {
        if (cancelled) return;
        if (err instanceof ApiClientError && err.statusCode === 404) {
          dispatch({ type: 'notFound' });
        } else {
          dispatch({
            type: 'failure',
            message: err instanceof Error ? err.message : 'Failed to load scenario.',
          });
        }
      });
    return () => { cancelled = true; };
  }, [id]);

  return (
    <div className="p-8 max-w-3xl">
      {/* Back link */}
      <Link
        href="/scenarios"
        className="inline-flex items-center gap-1.5 text-sm text-zinc-500 hover:text-zinc-700 mb-5 focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 rounded"
        aria-label="Back to scenarios"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="15 18 9 12 15 6"/>
        </svg>
        Back to Scenarios
      </Link>

      {/* Toast */}
      {toast && (
        <div
          role="status"
          aria-live="polite"
          className="mb-5 flex items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800"
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          {toast}
        </div>
      )}

      {/* Loading */}
      {state.status === 'loading' && (
        <div className="space-y-4" aria-label="Loading scenario">
          <div className="h-8 rounded bg-zinc-100 animate-pulse w-2/3" />
          <div className="h-4 rounded bg-zinc-100 animate-pulse w-1/3" />
          <div className="h-32 rounded-xl bg-zinc-100 animate-pulse mt-6" />
          <div className="h-48 rounded-xl bg-zinc-100 animate-pulse" />
        </div>
      )}

      {/* Not found */}
      {state.status === 'notFound' && (
        <div className="rounded-xl border border-zinc-200 bg-white p-12 text-center">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#d1d5db" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="mx-auto mb-3" aria-hidden="true">
            <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
          </svg>
          <p className="text-zinc-600 font-medium">Scenario not found</p>
          <p className="text-zinc-400 text-sm mt-1">This scenario may have been removed.</p>
          <Link href="/scenarios" className="mt-4 inline-block text-sm text-blue-600 hover:underline">
            Return to scenarios
          </Link>
        </div>
      )}

      {/* Error */}
      {state.status === 'error' && (
        <div role="alert" className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {state.message}
        </div>
      )}

      {/* Loaded */}
      {state.status === 'loaded' && (() => {
        const { scenario } = state;
        const nextAction = NEXT_ACTION[scenario.status];
        const sorted = [...scenario.answerOptions].sort((a, b) => a.displayOrder - b.displayOrder);

        return (
          <div className="space-y-5">
            {/* Header */}
            <div>
              <div className="flex flex-wrap items-center gap-2 mb-2">
                <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${CATEGORY_CLASSES[scenario.category]}`}>
                  {CATEGORY_LABELS[scenario.category]}
                </span>
                <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${DIFFICULTY_CLASSES[scenario.difficulty]}`}>
                  {scenario.difficulty.charAt(0).toUpperCase() + scenario.difficulty.slice(1)}
                </span>
                <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${STATUS_CLASSES[scenario.status]}`}>
                  {STATUS_LABELS[scenario.status]}
                </span>
              </div>
              <h1 className="text-2xl font-bold text-zinc-900">{scenario.title}</h1>
              {scenario.createdAt && (
                <p className="text-xs text-zinc-400 mt-1">
                  Created {new Date(scenario.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                  {scenario.updatedAt ? ` · Updated ${new Date(scenario.updatedAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}` : ''}
                </p>
              )}
            </div>

            {/* Scenario prompt */}
            <SectionCard title="Scenario Prompt">
              <p className="text-sm text-zinc-700 leading-relaxed">{scenario.prompt}</p>
            </SectionCard>

            {/* Answer options */}
            <SectionCard title="Answer Options">
              <div className="space-y-2.5">
                {sorted.map((opt, idx) => (
                  <div
                    key={opt.id}
                    className={`flex items-start gap-3 rounded-lg border p-3 ${
                      opt.isCorrect
                        ? 'border-green-300 bg-green-50'
                        : 'border-zinc-200 bg-zinc-50'
                    }`}
                    aria-label={`Option ${String.fromCharCode(65 + idx)}: ${opt.text}${opt.isCorrect ? ' — correct answer' : ''}`}
                  >
                    <span className={`mt-0.5 text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center shrink-0 ${
                      opt.isCorrect ? 'bg-green-500 text-white' : 'bg-zinc-200 text-zinc-600'
                    }`}>
                      {String.fromCharCode(65 + idx)}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-zinc-800">{opt.text}</p>
                      {opt.isCorrect && (
                        <p className="text-xs text-green-600 font-medium mt-0.5">Correct answer</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </SectionCard>

            {/* Why this matters */}
            <SectionCard title="Why This Matters">
              <p className="text-sm text-zinc-700 leading-relaxed">{scenario.explanation}</p>
            </SectionCard>

            {/* Recommended action */}
            {scenario.recommendedAction && (
              <SectionCard title="Recommended Action">
                <p className="text-sm text-zinc-700 leading-relaxed">{scenario.recommendedAction}</p>
              </SectionCard>
            )}

            {/* Status workflow */}
            <div className="flex items-center gap-3 pt-2">
              {nextAction && (
                <button
                  type="button"
                  onClick={() => showToast('Status changes require API support — coming soon.')}
                  className="rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-blue-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition-colors"
                  aria-label={`${nextAction} this scenario`}
                >
                  {nextAction}
                </button>
              )}
              <button
                type="button"
                onClick={() => showToast('Edit endpoints are not yet available in the API.')}
                className="rounded-lg border border-zinc-200 px-5 py-2.5 text-sm font-medium text-zinc-600 hover:bg-zinc-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition-colors"
              >
                Edit
              </button>
              {scenario.status === 'retired' && (
                <span className="ml-2 text-xs text-zinc-400">This scenario is retired and cannot be changed.</span>
              )}
            </div>
          </div>
        );
      })()}
    </div>
  );
}
