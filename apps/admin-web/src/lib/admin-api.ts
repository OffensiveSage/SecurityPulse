/**
 * Admin API client for Security Pulse.
 * All admin endpoints require approver or platform_admin role.
 * Every analytics and audit access is audit-logged server-side.
 */

import { apiFetch } from './api-client';
import type {
  AnalyticsSummary,
  AuditEvent,
  Campaign,
  CampaignCreate,
  EligibilityResult,
  PaginatedResponse,
} from './types';

// Snake-to-camelCase helpers (backend returns snake_case)
function toAnalyticsSummary(raw: Record<string, unknown>): AnalyticsSummary {
  return {
    totalEmployeesActive: raw['total_employees_active'] as number,
    totalResponses: raw['total_responses'] as number,
    overallAccuracyRate: raw['overall_accuracy_rate'] as number,
    participationRate: raw['participation_rate'] as number,
    byCategory: raw['by_category']
      ? (raw['by_category'] as Array<Record<string, unknown>>).map((c) => ({
          category: c['category'] as string,
          responseCount: c['response_count'] as number,
          accuracyRate: c['accuracy_rate'] as number,
          suppressed: c['suppressed'] as boolean,
        }))
      : null,
    suppressionApplied: raw['suppression_applied'] as boolean,
  };
}

function toCampaign(raw: Record<string, unknown>): Campaign {
  return {
    id: raw['id'] as string,
    name: raw['name'] as string,
    status: raw['status'] as Campaign['status'],
    startAt: raw['start_at'] as string,
    endAt: raw['end_at'] as string,
    eligibilityRule: (raw['eligibility_rule'] as string | null) ?? null,
    rewardDescription: (raw['reward_description'] as string | null) ?? null,
    governanceDisclaimer: raw['governance_disclaimer'] as string,
  };
}

function toAuditEvent(raw: Record<string, unknown>): AuditEvent {
  return {
    id: raw['id'] as string,
    actorId: (raw['actor_id'] as string | null) ?? null,
    action: raw['action'] as string,
    targetType: (raw['target_type'] as string | null) ?? null,
    targetId: (raw['target_id'] as string | null) ?? null,
    beforeSummary: (raw['before_summary'] as string | null) ?? null,
    afterSummary: (raw['after_summary'] as string | null) ?? null,
    timestamp: raw['timestamp'] as string,
    correlationId: (raw['correlation_id'] as string | null) ?? null,
  };
}

export async function fetchAnalyticsSummary(
  accessToken?: string,
): Promise<AnalyticsSummary> {
  const raw = await apiFetch<Record<string, unknown>>(
    '/admin/analytics/summary',
    {},
    accessToken,
  );
  return toAnalyticsSummary(raw);
}

export async function fetchCampaigns(
  page = 1,
  pageSize = 20,
  accessToken?: string,
): Promise<PaginatedResponse<Campaign>> {
  const raw = await apiFetch<{ data: Array<Record<string, unknown>>; meta: Record<string, unknown> }>(
    `/admin/campaigns?page=${page}&page_size=${pageSize}`,
    {},
    accessToken,
  );
  return {
    data: raw.data.map(toCampaign),
    meta: {
      page: raw.meta['page'] as number,
      pageSize: raw.meta['page_size'] as number,
      total: raw.meta['total'] as number,
      totalPages: raw.meta['total_pages'] as number,
    },
  };
}

export async function createCampaign(
  payload: CampaignCreate,
  accessToken?: string,
): Promise<Campaign> {
  const body = {
    name: payload.name,
    start_at: payload.startAt,
    end_at: payload.endAt,
    eligibility_rule: payload.eligibilityRule,
    reward_description: payload.rewardDescription,
  };
  const raw = await apiFetch<Record<string, unknown>>(
    '/admin/campaigns',
    { method: 'POST', body: JSON.stringify(body) },
    accessToken,
  );
  return toCampaign(raw);
}

export async function calculateEligibility(
  campaignId: string,
  accessToken?: string,
): Promise<EligibilityResult> {
  const raw = await apiFetch<Record<string, unknown>>(
    `/admin/campaigns/${campaignId}/calculate-eligibility`,
    { method: 'POST' },
    accessToken,
  );
  return {
    eligibleCount: raw['eligible_count'] as number,
    calculatedAt: raw['calculated_at'] as string,
    suppressed: raw['suppressed'] as boolean,
  };
}

export async function fetchAuditEvents(
  page = 1,
  pageSize = 20,
  action?: string,
  accessToken?: string,
): Promise<PaginatedResponse<AuditEvent>> {
  const params = new URLSearchParams({
    page: String(page),
    page_size: String(pageSize),
  });
  if (action) params.set('action', action);
  const raw = await apiFetch<{ data: Array<Record<string, unknown>>; meta: Record<string, unknown> }>(
    `/admin/audit-events?${params.toString()}`,
    {},
    accessToken,
  );
  return {
    data: raw.data.map(toAuditEvent),
    meta: {
      page: raw.meta['page'] as number,
      pageSize: raw.meta['page_size'] as number,
      total: raw.meta['total'] as number,
      totalPages: raw.meta['total_pages'] as number,
    },
  };
}
