/**
 * Campaigns management page.
 * Allows admins to list, create, and calculate eligibility for campaigns.
 * Governance disclaimer is always shown before eligibility calculation.
 */

'use client';

import { useReducer, useEffect, useState } from 'react';
import {
  fetchCampaigns,
  createCampaign,
  calculateEligibility,
} from '@/lib/admin-api';
import type { Campaign, CampaignCreate, EligibilityResult } from '@/lib/types';
import { ErrorView } from '@/components/ui/ErrorView';
import { LoadingView } from '@/components/ui/LoadingView';
import { EmptyView } from '@/components/ui/EmptyView';

const STATUS_LABELS: Record<Campaign['status'], string> = {
  draft: 'Draft',
  active: 'Active',
  completed: 'Completed',
  cancelled: 'Cancelled',
};

const STATUS_CLASSES: Record<Campaign['status'], string> = {
  draft: 'bg-zinc-100 text-zinc-700 dark:bg-zinc-700 dark:text-zinc-300',
  active: 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300',
  completed: 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300',
  cancelled: 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300',
};

type ListState =
  | { status: 'loading'; campaigns: Campaign[]; fetchCount: number }
  | { status: 'error'; message: string; campaigns: Campaign[]; fetchCount: number }
  | { status: 'loaded'; campaigns: Campaign[]; fetchCount: number };

type ListAction =
  | { type: 'retry' }
  | { type: 'success'; campaigns: Campaign[] }
  | { type: 'failure'; message: string }
  | { type: 'prepend'; campaign: Campaign };

function listReducer(state: ListState, action: ListAction): ListState {
  switch (action.type) {
    case 'retry':
      return { status: 'loading', campaigns: state.campaigns, fetchCount: state.fetchCount + 1 };
    case 'success':
      return { status: 'loaded', campaigns: action.campaigns, fetchCount: state.fetchCount };
    case 'failure':
      return { status: 'error', message: action.message, campaigns: state.campaigns, fetchCount: state.fetchCount };
    case 'prepend':
      return { ...state, campaigns: [action.campaign, ...state.campaigns] };
  }
}

function CreateCampaignForm({ onCreated }: { onCreated: (c: Campaign) => void }) {
  const [name, setName] = useState('');
  const [startAt, setStartAt] = useState('');
  const [endAt, setEndAt] = useState('');
  const [eligibilityRule, setEligibilityRule] = useState('');
  const [rewardDescription, setRewardDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      // Build payload without setting optional rewardDescription to undefined.
      // exactOptionalPropertyTypes requires omitting the key rather than setting it to undefined.
      const base: CampaignCreate = { name, startAt, endAt, eligibilityRule };
      const payload: CampaignCreate = rewardDescription
        ? { ...base, rewardDescription }
        : base;
      const created = await createCampaign(payload);
      onCreated(created);
      setName(''); setStartAt(''); setEndAt(''); setEligibilityRule(''); setRewardDescription('');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to create campaign');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} aria-label="Create campaign" className="rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 p-6 mb-8">
      <h2 className="text-lg font-semibold text-zinc-900 dark:text-white mb-4">New Campaign</h2>
      {error && <p role="alert" className="text-sm text-red-600 dark:text-red-400 mb-3">{error}</p>}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label htmlFor="campaign-name" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Name <span aria-hidden="true">*</span></label>
          <input id="campaign-name" required value={name} onChange={e => setName(e.target.value)} className="w-full rounded border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-3 py-2 text-sm text-zinc-900 dark:text-white" />
        </div>
        <div>
          <label htmlFor="eligibility-rule" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Eligibility Rule <span aria-hidden="true">*</span></label>
          <input id="eligibility-rule" required value={eligibilityRule} onChange={e => setEligibilityRule(e.target.value)} placeholder="e.g. complete all scenarios in Q1" className="w-full rounded border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-3 py-2 text-sm text-zinc-900 dark:text-white" />
        </div>
        <div>
          <label htmlFor="start-at" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Start Date <span aria-hidden="true">*</span></label>
          <input id="start-at" type="datetime-local" required value={startAt} onChange={e => setStartAt(e.target.value)} className="w-full rounded border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-3 py-2 text-sm text-zinc-900 dark:text-white" />
        </div>
        <div>
          <label htmlFor="end-at" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">End Date <span aria-hidden="true">*</span></label>
          <input id="end-at" type="datetime-local" required value={endAt} onChange={e => setEndAt(e.target.value)} className="w-full rounded border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-3 py-2 text-sm text-zinc-900 dark:text-white" />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="reward-desc" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Reward Description</label>
          <input id="reward-desc" value={rewardDescription} onChange={e => setRewardDescription(e.target.value)} placeholder="Optional" className="w-full rounded border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-3 py-2 text-sm text-zinc-900 dark:text-white" />
        </div>
      </div>
      <button type="submit" disabled={submitting} className="mt-4 rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500">
        {submitting ? 'Creating…' : 'Create Campaign'}
      </button>
    </form>
  );
}

function EligibilityPanel({ campaign }: { campaign: Campaign }) {
  const [result, setResult] = useState<EligibilityResult | null>(null);
  const [calculating, setCalculating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [disclaimerAccepted, setDisclaimerAccepted] = useState(false);

  async function handleCalculate() {
    setCalculating(true);
    setError(null);
    try {
      const r = await calculateEligibility(campaign.id);
      setResult(r);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed');
    } finally {
      setCalculating(false);
    }
  }

  return (
    <div className="mt-3">
      {!disclaimerAccepted ? (
        <div className="rounded border border-amber-300 bg-amber-50 dark:border-amber-700 dark:bg-amber-900/20 p-3">
          <p className="text-xs text-amber-800 dark:text-amber-300 mb-2" role="note">
            <strong>Governance notice:</strong> {campaign.governanceDisclaimer}
          </p>
          <button
            onClick={() => setDisclaimerAccepted(true)}
            className="text-xs rounded bg-amber-600 px-3 py-1 text-white hover:bg-amber-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber-500"
          >
            I understand — calculate eligibility
          </button>
        </div>
      ) : (
        <div>
          <button
            onClick={handleCalculate}
            disabled={calculating}
            className="text-xs rounded bg-blue-600 px-3 py-1 text-white hover:bg-blue-700 disabled:opacity-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
          >
            {calculating ? 'Calculating…' : 'Calculate Eligibility'}
          </button>
          {error && <p role="alert" className="text-xs text-red-600 dark:text-red-400 mt-1">{error}</p>}
          {result && (
            <p className="text-sm text-zinc-700 dark:text-zinc-300 mt-2">
              {result.suppressed
                ? 'Eligible count suppressed (below minimum group size).'
                : `${result.eligibleCount} eligible participant${result.eligibleCount !== 1 ? 's' : ''}.`}
            </p>
          )}
        </div>
      )}
    </div>
  );
}

export default function CampaignsPage() {
  const [state, dispatch] = useReducer(listReducer, {
    status: 'loading',
    campaigns: [],
    fetchCount: 0,
  });

  useEffect(() => {
    let cancelled = false;
    fetchCampaigns()
      .then((r) => {
        if (!cancelled) dispatch({ type: 'success', campaigns: [...r.data] });
      })
      .catch((err: unknown) => {
        if (!cancelled)
          dispatch({
            type: 'failure',
            message: err instanceof Error ? err.message : 'Failed to load campaigns',
          });
      });
    return () => {
      cancelled = true;
    };
  }, [state.fetchCount]);

  return (
    <div className="p-8">
      <h1 className="text-2xl font-semibold text-zinc-900 dark:text-white mb-6">Campaigns</h1>
      <CreateCampaignForm onCreated={(c) => dispatch({ type: 'prepend', campaign: c })} />
      {state.status === 'loading' && <LoadingView message="Loading campaigns…" />}
      {state.status === 'error' && (
        <ErrorView message={state.message} onRetry={() => dispatch({ type: 'retry' })} />
      )}
      {state.status === 'loaded' && state.campaigns.length === 0 && (
        <EmptyView title="No campaigns" message="Create your first campaign above." />
      )}
      {state.status === 'loaded' && state.campaigns.length > 0 && (
        <ul aria-label="Campaign list" className="space-y-4">
          {state.campaigns.map((c) => (
            <li key={c.id} className="rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 p-5">
              <div className="flex items-center gap-3 mb-1">
                <h3 className="font-medium text-zinc-900 dark:text-white">{c.name}</h3>
                <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${STATUS_CLASSES[c.status]}`}>
                  {STATUS_LABELS[c.status]}
                </span>
              </div>
              <p className="text-xs text-zinc-500 dark:text-zinc-400 mb-1">
                {new Date(c.startAt).toLocaleDateString()} – {new Date(c.endAt).toLocaleDateString()}
              </p>
              {c.eligibilityRule && (
                <p className="text-xs text-zinc-600 dark:text-zinc-400 mb-2">Rule: {c.eligibilityRule}</p>
              )}
              <EligibilityPanel campaign={c} />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
