/**
 * EmptyView — displayed when a list or data set has no items.
 */
import React from 'react';

interface EmptyViewProps {
  readonly title: string;
  readonly message?: string;
  readonly action?: React.ReactNode;
}

export function EmptyView({ title, message, action }: EmptyViewProps) {
  return (
    <div className="flex min-h-[200px] flex-col items-center justify-center gap-4 p-8">
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
            d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
          />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
      {message && (
        <p className="max-w-sm text-center text-sm text-gray-600">{message}</p>
      )}
      {action}
    </div>
  );
}
