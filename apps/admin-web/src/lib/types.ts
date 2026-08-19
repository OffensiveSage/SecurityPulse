/**
 * Shared TypeScript types for the Security Pulse admin portal.
 * These mirror the API contract defined in packages/api-contract/openapi.yaml.
 */

/** Standard API error envelope */
export interface ApiError {
  readonly code: string;
  readonly message: string;
  readonly details: Record<string, unknown>;
  readonly correlationId: string;
}

/** Pagination metadata */
export interface PaginationMeta {
  readonly page: number;
  readonly pageSize: number;
  readonly total: number;
  readonly totalPages: number;
}

/** Generic paginated response */
export interface PaginatedResponse<T> {
  readonly data: readonly T[];
  readonly meta: PaginationMeta;
}

/** Scenario status values */
export type ScenarioStatus =
  | 'draft'
  | 'review'
  | 'approved'
  | 'published'
  | 'retired';

/** User role values */
export type UserRole =
  | 'employee'
  | 'author'
  | 'reviewer'
  | 'approver'
  | 'soc_analyst'
  | 'platform_admin';

/** App environment values */
export type AppEnv = 'development' | 'production';

// ---- Admin: Analytics ----

export interface CategoryAccuracy {
  readonly category: string;
  readonly responseCount: number;
  readonly accuracyRate: number;
  readonly suppressed: boolean;
}

export interface AnalyticsSummary {
  readonly totalEmployeesActive: number;
  readonly totalResponses: number;
  readonly overallAccuracyRate: number;
  readonly participationRate: number;
  readonly byCategory: readonly CategoryAccuracy[] | null;
  readonly suppressionApplied: boolean;
}

// ---- Admin: Campaigns ----

export type CampaignStatus = 'draft' | 'active' | 'completed' | 'cancelled';

export interface Campaign {
  readonly id: string;
  readonly name: string;
  readonly status: CampaignStatus;
  readonly startAt: string;
  readonly endAt: string;
  readonly eligibilityRule: string | null;
  readonly rewardDescription: string | null;
  readonly governanceDisclaimer: string;
}

export interface CampaignCreate {
  readonly name: string;
  readonly startAt: string;
  readonly endAt: string;
  readonly eligibilityRule: string;
  readonly rewardDescription?: string;
}

export interface EligibilityResult {
  readonly eligibleCount: number;
  readonly calculatedAt: string;
  readonly suppressed: boolean;
}

// ---- Admin: Audit ----

export interface AuditEvent {
  readonly id: string;
  readonly actorId: string | null;
  readonly action: string;
  readonly targetType: string | null;
  readonly targetId: string | null;
  readonly beforeSummary: string | null;
  readonly afterSummary: string | null;
  readonly timestamp: string;
  readonly correlationId: string | null;
}
