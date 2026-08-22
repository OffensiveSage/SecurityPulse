/**
 * Employee management page.
 * Shows enrolled employees with participation status, streak, and accuracy.
 * Always shows demo data — no employee list API endpoint exists yet.
 * Individual-level data is anonymised. No row-level drilldown (PII protection).
 * WCAG 2.2 AA compliant.
 */

'use client';

import { useState } from 'react';

interface EmployeeRow {
  id: string;
  department: string;
  enrolledAt: string;
  streakDays: number;
  lastActiveAt: string;
  isActive: boolean;
  accuracyRate: number;
}

// ── Demo data ──────────────────────────────────────────────────────────────────
const DEMO_EMPLOYEES: EmployeeRow[] = [
  { id: 'EMP-7f2a', department: 'Engineering',   enrolledAt: '2026-01-15', streakDays: 14, lastActiveAt: '2026-08-21', isActive: true,  accuracyRate: 0.89 },
  { id: 'EMP-3b9c', department: 'Legal',         enrolledAt: '2026-01-15', streakDays: 7,  lastActiveAt: '2026-08-20', isActive: true,  accuracyRate: 0.76 },
  { id: 'EMP-c1d4', department: 'HR',            enrolledAt: '2026-02-01', streakDays: 3,  lastActiveAt: '2026-08-19', isActive: true,  accuracyRate: 0.61 },
  { id: 'EMP-a5f8', department: 'Finance',       enrolledAt: '2026-02-01', streakDays: 21, lastActiveAt: '2026-08-21', isActive: true,  accuracyRate: 0.93 },
  { id: 'EMP-d2e7', department: 'Product',       enrolledAt: '2026-03-10', streakDays: 0,  lastActiveAt: '2026-08-10', isActive: false, accuracyRate: 0.55 },
  { id: 'EMP-9g3h', department: 'Engineering',   enrolledAt: '2026-03-10', streakDays: 5,  lastActiveAt: '2026-08-21', isActive: true,  accuracyRate: 0.82 },
  { id: 'EMP-b6i1', department: 'Sales',         enrolledAt: '2026-04-01', streakDays: 0,  lastActiveAt: '2026-07-28', isActive: false, accuracyRate: 0.44 },
  { id: 'EMP-e4j2', department: 'Operations',    enrolledAt: '2026-04-01', streakDays: 10, lastActiveAt: '2026-08-20', isActive: true,  accuracyRate: 0.78 },
  { id: 'EMP-f7k5', department: 'Finance',       enrolledAt: '2026-05-15', streakDays: 2,  lastActiveAt: '2026-08-18', isActive: true,  accuracyRate: 0.67 },
  { id: 'EMP-h8l6', department: 'HR',            enrolledAt: '2026-06-01', streakDays: 0,  lastActiveAt: '2026-08-05', isActive: false, accuracyRate: 0.38 },
];

// ── Computed summary stats ─────────────────────────────────────────────────────
function computeStats(employees: EmployeeRow[]) {
  const total = employees.length;
  const activeThisWeek = employees.filter((e) => e.isActive).length;
  const avgAccuracy = employees.reduce((sum, e) => sum + e.accuracyRate, 0) / total;
  const topStreak = Math.max(...employees.map((e) => e.streakDays));
  return { total, activeThisWeek, avgAccuracy, topStreak };
}

// ── Accuracy badge ─────────────────────────────────────────────────────────────
function AccuracyBadge({ rate }: { rate: number }) {
  const pct = Math.round(rate * 100);
  const cls =
    pct >= 75 ? 'bg-green-100 text-green-700'
    : pct >= 50 ? 'bg-amber-100 text-amber-700'
    : 'bg-red-100 text-red-700';
  return (
    <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${cls}`}>
      {pct}%
    </span>
  );
}

// ── KPI stat card ──────────────────────────────────────────────────────────────
function StatCard({ label, value, sub }: { label: string; value: string; sub: string }) {
  return (
    <div role="region" aria-label={label} className="rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
      <p className="text-xs font-medium text-zinc-500">{label}</p>
      <p className="mt-1 text-2xl font-bold text-zinc-900">{value}</p>
      <p className="mt-0.5 text-xs text-zinc-400">{sub}</p>
    </div>
  );
}

type FilterTab = 'all' | 'active' | 'inactive';
const FILTER_TABS: Array<{ value: FilterTab; label: string }> = [
  { value: 'all', label: 'All' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

// ── Main page ──────────────────────────────────────────────────────────────────
export default function EmployeesPage() {
  const [activeTab, setActiveTab] = useState<FilterTab>('all');

  const stats = computeStats(DEMO_EMPLOYEES);

  const filtered =
    activeTab === 'all'
      ? DEMO_EMPLOYEES
      : DEMO_EMPLOYEES.filter((e) =>
          activeTab === 'active' ? e.isActive : !e.isActive
        );

  return (
    <div className="p-8 max-w-7xl">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-zinc-900">Employees</h1>
        <p className="text-sm text-zinc-500 mt-0.5">
          Enrolled employee participation and progress — aggregated, anonymised data only.
        </p>
      </div>

      {/* Demo data banner */}
      <div role="status" className="mb-6 flex items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
        </svg>
        Showing demo data — no employee list endpoint is available yet. Connect the backend to see live data.
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-2 gap-4 mb-6 lg:grid-cols-4">
        <StatCard
          label="Total Enrolled"
          value={String(stats.total)}
          sub="employees in training"
        />
        <StatCard
          label="Active This Week"
          value={String(stats.activeThisWeek)}
          sub={`of ${stats.total} enrolled`}
        />
        <StatCard
          label="Average Accuracy"
          value={`${Math.round(stats.avgAccuracy * 100)}%`}
          sub="correct answers"
        />
        <StatCard
          label="Top Streak"
          value={`${stats.topStreak}d`}
          sub="consecutive days"
        />
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1 mb-5 border-b border-zinc-200" role="tablist" aria-label="Filter by status">
        {FILTER_TABS.map(({ value, label }) => {
          const count =
            value === 'all'
              ? DEMO_EMPLOYEES.length
              : DEMO_EMPLOYEES.filter((e) =>
                  value === 'active' ? e.isActive : !e.isActive
                ).length;
          return (
            <button
              key={value}
              role="tab"
              aria-selected={activeTab === value}
              onClick={() => setActiveTab(value)}
              className={[
                'px-3 py-2 text-sm font-medium border-b-2 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500',
                activeTab === value
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-zinc-500 hover:text-zinc-700 hover:border-zinc-300',
              ].join(' ')}
            >
              {label}
              <span className={`ml-1.5 rounded-full px-1.5 py-0.5 text-xs ${activeTab === value ? 'bg-blue-100 text-blue-600' : 'bg-zinc-100 text-zinc-500'}`}>
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <div className="rounded-xl border border-zinc-200 bg-white p-12 text-center">
          <p className="text-zinc-500 text-sm">No employees with this status.</p>
          <button onClick={() => setActiveTab('all')} className="mt-2 text-sm text-blue-600 hover:underline">
            View all employees
          </button>
        </div>
      ) : (
        <div className="rounded-xl border border-zinc-200 bg-white shadow-sm overflow-hidden">
          <table className="w-full text-sm" aria-label="Employee roster">
            <thead>
              <tr className="border-b border-zinc-100 bg-zinc-50">
                <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Employee ID</th>
                <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Department</th>
                <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Enrolled</th>
                <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Streak</th>
                <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Last Active</th>
                <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Status</th>
                <th scope="col" className="py-3 px-4 text-left font-semibold text-zinc-600">Accuracy</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((emp, idx) => (
                <tr
                  key={emp.id}
                  className={`border-b border-zinc-50 ${idx % 2 === 0 ? '' : 'bg-zinc-50/50'}`}
                >
                  <td className="py-3 px-4">
                    <span className="font-mono text-xs font-medium text-zinc-700">{emp.id}</span>
                  </td>
                  <td className="py-3 px-4 text-zinc-600">{emp.department}</td>
                  <td className="py-3 px-4 text-zinc-500 text-xs">
                    {new Date(emp.enrolledAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </td>
                  <td className="py-3 px-4">
                    <span className={`text-sm font-medium ${emp.streakDays > 0 ? 'text-orange-600' : 'text-zinc-400'}`}>
                      {emp.streakDays > 0 ? `🔥 ${emp.streakDays}d` : '—'}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-zinc-500 text-xs">
                    {new Date(emp.lastActiveAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </td>
                  <td className="py-3 px-4">
                    <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                      emp.isActive ? 'bg-green-100 text-green-700' : 'bg-zinc-100 text-zinc-500'
                    }`}>
                      {emp.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="py-3 px-4">
                    <AccuracyBadge rate={emp.accuracyRate} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="px-4 py-3 border-t border-zinc-100 bg-zinc-50 text-xs text-zinc-500">
            {filtered.length} employee{filtered.length !== 1 ? 's' : ''} shown
            {activeTab !== 'all' ? ` · filtered by "${activeTab}"` : ''} · IDs are anonymised
          </div>
        </div>
      )}
    </div>
  );
}
