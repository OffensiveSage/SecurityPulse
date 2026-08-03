/**
 * LoadingView — displayed while async operations are in progress.
 *
 * Accessibility: uses role="status" and aria-label so screen readers
 * announce the loading state.
 */
import React from 'react';

interface LoadingViewProps {
  readonly message?: string;
}

export function LoadingView({ message = 'Loading…' }: LoadingViewProps) {
  return (
    <div
      role="status"
      aria-label={message}
      aria-live="polite"
      className="flex min-h-[200px] flex-col items-center justify-center gap-4 p-8"
    >
      <div
        className="h-10 w-10 animate-spin rounded-full border-4 border-blue-600 border-t-transparent"
        aria-hidden="true"
      />
      <p className="text-sm text-gray-600">{message}</p>
    </div>
  );
}
