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
