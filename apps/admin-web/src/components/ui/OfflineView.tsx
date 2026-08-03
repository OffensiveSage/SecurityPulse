/**
 * OfflineView — displayed when the user has no network connectivity.
 */
import React from 'react';

interface OfflineViewProps {
  readonly onRetry?: () => void;
}

export function OfflineView({ onRetry }: OfflineViewProps) {
  return (
    <div
      role="status"
      aria-live="polite"
      className="flex min-h-[200px] flex-col items-center justify-center gap-4 p-8"
    >
      <div
        className="flex h-12 w-12 items-center justify-center rounded-full bg-gray-100"
        aria-hidden="true"
      >
        <svg
          className="h-6 w-6 text-gray-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3"
          />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-gray-900">No connection</h2>
      <p className="max-w-sm text-center text-sm text-gray-600">
        Check your network connection and try again.
      </p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          type="button"
        >
          Retry
        </button>
      )}
    </div>
  );
}
