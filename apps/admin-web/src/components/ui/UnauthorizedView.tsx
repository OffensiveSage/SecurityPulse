/**
 * UnauthorizedView — displayed when the user lacks permission for a resource.
 *
 * Accessibility: uses role="alert" to announce the denied access state.
 * Does not reveal details about why access was denied.
 */
import React from 'react';

interface UnauthorizedViewProps {
  readonly message?: string;
}

export function UnauthorizedView({
  message = 'You do not have permission to view this page.',
}: UnauthorizedViewProps) {
  return (
    <div
      role="alert"
      aria-live="assertive"
      className="flex min-h-[200px] flex-col items-center justify-center gap-4 p-8"
    >
      <div
        className="flex h-12 w-12 items-center justify-center rounded-full bg-yellow-100"
        aria-hidden="true"
      >
        <svg
          className="h-6 w-6 text-yellow-600"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
          />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-gray-900">Access denied</h2>
      <p className="max-w-sm text-center text-sm text-gray-600">{message}</p>
    </div>
  );
}
