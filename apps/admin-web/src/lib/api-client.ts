/**
 * API client for the Security Pulse backend.
 *
 * All requests attach an Authorization header with the OIDC access token.
 * All requests include a correlation ID for tracing.
 * Never log or expose tokens.
 */

import type { ApiError } from './types';

const API_BASE_URL =
  process.env['NEXT_PUBLIC_API_BASE_URL'] ?? 'http://localhost:8000/api/v1';

function generateCorrelationId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
}

export class ApiClientError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly error: ApiError,
  ) {
    super(error.message);
    this.name = 'ApiClientError';
  }
}

/**
 * Core fetch wrapper that adds auth headers, correlation IDs,
 * and parses the standard error envelope.
 *
 * @param path - API path (relative to base URL)
 * @param options - Standard fetch options
 * @param accessToken - OIDC access token (never stored in this module)
 */
export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
  accessToken?: string,
): Promise<T> {
  const correlationId = generateCorrelationId();

  const headers = new Headers(options.headers);
  headers.set('Content-Type', 'application/json');
  headers.set('X-Correlation-Id', correlationId);

  if (accessToken) {
    // Token is passed in per-request; never cached in module scope
    headers.set('Authorization', `Bearer ${accessToken}`);
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorBody = (await response.json().catch(() => ({
      code: 'unknown_error',
      message: response.statusText,
      details: {},
      correlationId,
    }))) as ApiError;

    throw new ApiClientError(response.status, errorBody);
  }

  return response.json() as Promise<T>;
}
