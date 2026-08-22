/**
 * Create new scenario page.
 * Full form for authoring security awareness scenarios.
 * Saves as draft. Validation on submit.
 * WCAG 2.2 AA compliant.
 */

'use client';

import { useState, useId } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import type { ScenarioCategory, ScenarioDifficulty } from '@/lib/types';

const CATEGORIES: Array<{ value: ScenarioCategory; label: string }> = [
  { value: 'phishing', label: 'Phishing' },
  { value: 'password_security', label: 'Password Security' },
  { value: 'social_engineering', label: 'Social Engineering' },
  { value: 'data_protection', label: 'Data Protection' },
  { value: 'device_security', label: 'Device Security' },
  { value: 'physical_security', label: 'Physical Security' },
];

const DIFFICULTIES: Array<{ value: ScenarioDifficulty; label: string; desc: string }> = [
  { value: 'beginner', label: 'Beginner', desc: 'Clear red flags, obvious correct answer' },
  { value: 'intermediate', label: 'Intermediate', desc: 'Requires some security knowledge' },
  { value: 'advanced', label: 'Advanced', desc: 'Subtle cues, nuanced decision-making' },
];

interface OptionDraft {
  text: string;
  isCorrect: boolean;
}

const DEFAULT_OPTIONS: OptionDraft[] = [
  { text: '', isCorrect: false },
  { text: '', isCorrect: false },
  { text: '', isCorrect: false },
  { text: '', isCorrect: false },
];

function FieldError({ message }: { message: string | undefined }) {
  if (!message) return null;
  return <p role="alert" className="mt-1 text-xs text-red-600">{message}</p>;
}

function CharCount({ current, max }: { current: number; max: number }) {
  const near = current > max * 0.85;
  const over = current > max;
  return (
    <span className={`text-xs tabular-nums ${over ? 'text-red-600' : near ? 'text-amber-600' : 'text-zinc-400'}`}>
      {current}/{max}
    </span>
  );
}

export default function NewScenarioPage() {
  const router = useRouter();
  const id = useId();

  const [title, setTitle] = useState('');
  const [category, setCategory] = useState<ScenarioCategory>('phishing');
  const [difficulty, setDifficulty] = useState<ScenarioDifficulty>('beginner');
  const [prompt, setPrompt] = useState('');
  const [explanation, setExplanation] = useState('');
  const [recommendedAction, setRecommendedAction] = useState('');
  const [options, setOptions] = useState<OptionDraft[]>(DEFAULT_OPTIONS);
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);

  function setCorrect(idx: number) {
    setOptions(opts => opts.map((o, i) => ({ ...o, isCorrect: i === idx })));
  }

  function setOptionText(idx: number, text: string) {
    setOptions(opts => opts.map((o, i) => i === idx ? { ...o, text } : o));
  }

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (title.trim().length < 5) errs['title'] = 'Title must be at least 5 characters.';
    if (title.trim().length > 100) errs['title'] = 'Title must be 100 characters or fewer.';
    if (prompt.trim().length < 20) errs['prompt'] = 'Scenario prompt must be at least 20 characters.';
    if (prompt.trim().length > 500) errs['prompt'] = 'Scenario prompt must be 500 characters or fewer.';
    if (explanation.trim().length < 10) errs['explanation'] = 'Explanation must be at least 10 characters.';
    if (recommendedAction.trim().length < 10) errs['recommendedAction'] = 'Recommended action must be at least 10 characters.';
    options.forEach((o, i) => {
      if (!o.text.trim()) errs[`option_${i}`] = 'This option cannot be empty.';
    });
    if (!options.some(o => o.isCorrect)) errs['options_correct'] = 'Mark one option as the correct answer.';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;
    setSubmitting(true);
    setSubmitError(null);
    try {
      const payload = {
        title: title.trim(),
        prompt: prompt.trim(),
        category,
        difficulty,
        explanation: explanation.trim(),
        recommended_action: recommendedAction.trim(),
        answer_options: options.map((o, i) => ({
          text: o.text.trim(),
          is_correct: o.isCorrect,
          display_order: i,
        })),
      };
      const baseUrl = process.env['NEXT_PUBLIC_API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
      const res = await fetch(`${baseUrl}/admin/scenarios`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer mock-content_admin' },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({ message: `HTTP ${res.status}` })) as { message?: string };
        throw new Error((err as { message?: string }).message ?? `HTTP ${res.status}`);
      }
      router.push('/scenarios?created=1');
    } catch (err: unknown) {
      setSubmitError(err instanceof Error ? err.message : 'Failed to create scenario. Ensure the API server is running.');
      setSubmitting(false);
    }
  }

  const inputCls = 'w-full rounded-lg border border-zinc-200 bg-white px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500';
  const labelCls = 'block text-sm font-medium text-zinc-700 mb-1';

  return (
    <div className="p-8 max-w-3xl">
      {/* Header */}
      <div className="mb-6">
        <Link href="/scenarios" className="inline-flex items-center gap-1.5 text-sm text-zinc-500 hover:text-zinc-700 mb-3 focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 rounded" aria-label="Back to scenarios">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="15 18 9 12 15 6"/></svg>
          Back to Scenarios
        </Link>
        <h1 className="text-2xl font-bold text-zinc-900">Create Scenario</h1>
        <p className="text-sm text-zinc-500 mt-0.5">New scenarios are saved as drafts and require approval before publishing.</p>
      </div>

      {submitError && (
        <div role="alert" className="mb-5 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {submitError}
        </div>
      )}

      <form onSubmit={handleSubmit} noValidate aria-label="Create scenario form" className="space-y-6">
        {/* Title */}
        <div className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h2 className="text-sm font-semibold text-zinc-800 mb-4">Basic Information</h2>
          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between mb-1">
                <label htmlFor={`${id}-title`} className={labelCls}>Title <span aria-hidden="true" className="text-red-500">*</span></label>
                <CharCount current={title.length} max={100} />
              </div>
              <input
                id={`${id}-title`}
                type="text"
                required
                maxLength={100}
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="e.g. Suspicious Email from IT Support"
                className={inputCls}
                aria-describedby={errors['title'] ? `${id}-title-err` : undefined}
                aria-invalid={!!errors['title']}
              />
              <FieldError message={errors['title']} />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor={`${id}-category`} className={labelCls}>Category <span aria-hidden="true" className="text-red-500">*</span></label>
                <select
                  id={`${id}-category`}
                  value={category}
                  onChange={e => setCategory(e.target.value as ScenarioCategory)}
                  className={inputCls}
                >
                  {CATEGORIES.map(c => <option key={c.value} value={c.value}>{c.label}</option>)}
                </select>
              </div>
              <div>
                <fieldset>
                  <legend className={labelCls}>Difficulty <span aria-hidden="true" className="text-red-500">*</span></legend>
                  <div className="space-y-1.5">
                    {DIFFICULTIES.map(d => (
                      <label key={d.value} className="flex items-start gap-2 cursor-pointer">
                        <input
                          type="radio"
                          name={`${id}-difficulty`}
                          value={d.value}
                          checked={difficulty === d.value}
                          onChange={() => setDifficulty(d.value)}
                          className="mt-0.5 accent-blue-600"
                        />
                        <span>
                          <span className="text-sm font-medium text-zinc-700">{d.label}</span>
                          <span className="block text-xs text-zinc-400">{d.desc}</span>
                        </span>
                      </label>
                    ))}
                  </div>
                </fieldset>
              </div>
            </div>
          </div>
        </div>

        {/* Scenario content */}
        <div className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h2 className="text-sm font-semibold text-zinc-800 mb-4">Scenario Content</h2>
          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between mb-1">
                <label htmlFor={`${id}-prompt`} className={labelCls}>Scenario Prompt <span aria-hidden="true" className="text-red-500">*</span></label>
                <CharCount current={prompt.length} max={500} />
              </div>
              <p className="text-xs text-zinc-400 mb-1.5">Write in second person. Describe the situation the employee faces.</p>
              <textarea
                id={`${id}-prompt`}
                required
                rows={4}
                maxLength={500}
                value={prompt}
                onChange={e => setPrompt(e.target.value)}
                placeholder="You receive an email from…"
                className={`${inputCls} resize-y`}
                aria-invalid={!!errors['prompt']}
              />
              <FieldError message={errors['prompt']} />
            </div>

            <div>
              <label htmlFor={`${id}-explanation`} className={labelCls}>Why This Matters <span aria-hidden="true" className="text-red-500">*</span></label>
              <p className="text-xs text-zinc-400 mb-1.5">Explain why the correct answer is right and what the risk is.</p>
              <textarea
                id={`${id}-explanation`}
                required
                rows={3}
                value={explanation}
                onChange={e => setExplanation(e.target.value)}
                placeholder="This is a phishing attempt because…"
                className={`${inputCls} resize-y`}
                aria-invalid={!!errors['explanation']}
              />
              <FieldError message={errors['explanation']} />
            </div>

            <div>
              <label htmlFor={`${id}-action`} className={labelCls}>Recommended Action <span aria-hidden="true" className="text-red-500">*</span></label>
              <p className="text-xs text-zinc-400 mb-1.5">What should the employee actually do in this situation?</p>
              <textarea
                id={`${id}-action`}
                required
                rows={3}
                value={recommendedAction}
                onChange={e => setRecommendedAction(e.target.value)}
                placeholder="Do not click any links. Report the email to…"
                className={`${inputCls} resize-y`}
                aria-invalid={!!errors['recommendedAction']}
              />
              <FieldError message={errors['recommendedAction']} />
            </div>
          </div>
        </div>

        {/* Answer options */}
        <div className="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
          <div className="flex items-start justify-between mb-1">
            <h2 className="text-sm font-semibold text-zinc-800">Answer Options</h2>
            <span className="text-xs text-zinc-400">Select the correct answer</span>
          </div>
          <p className="text-xs text-zinc-400 mb-4">Make wrong answers plausible — avoid obviously incorrect distractors.</p>

          {errors['options_correct'] && (
            <p role="alert" className="mb-3 text-xs text-red-600">{errors['options_correct']}</p>
          )}

          <fieldset aria-label="Answer options">
            <legend className="sr-only">Choose the correct answer and enter option text</legend>
            <div className="space-y-3">
              {options.map((opt, idx) => (
                <div key={idx} className={`flex items-start gap-3 rounded-lg border p-3 transition-colors ${opt.isCorrect ? 'border-green-300 bg-green-50' : 'border-zinc-200 bg-zinc-50'}`}>
                  <div className="pt-0.5 flex-shrink-0">
                    <input
                      type="radio"
                      name={`${id}-correct`}
                      checked={opt.isCorrect}
                      onChange={() => setCorrect(idx)}
                      className="accent-green-600 w-4 h-4"
                      aria-label={`Mark option ${String.fromCharCode(65 + idx)} as correct`}
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1.5">
                      <span className={`text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center ${opt.isCorrect ? 'bg-green-500 text-white' : 'bg-zinc-200 text-zinc-600'}`}>
                        {String.fromCharCode(65 + idx)}
                      </span>
                      {opt.isCorrect && <span className="text-xs font-medium text-green-600">Correct answer</span>}
                    </div>
                    <input
                      type="text"
                      value={opt.text}
                      onChange={e => setOptionText(idx, e.target.value)}
                      placeholder={`Option ${String.fromCharCode(65 + idx)}`}
                      className="w-full rounded-md border border-zinc-200 bg-white px-2.5 py-1.5 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      aria-label={`Option ${String.fromCharCode(65 + idx)} text`}
                      aria-invalid={!!errors[`option_${idx}`]}
                    />
                    <FieldError message={errors[`option_${idx}`]} />
                  </div>
                </div>
              ))}
            </div>
          </fieldset>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3 pt-2">
          <button
            type="submit"
            disabled={submitting}
            className="rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition-colors"
          >
            {submitting ? 'Saving…' : 'Save as Draft'}
          </button>
          <Link
            href="/scenarios"
            className="rounded-lg px-5 py-2.5 text-sm font-medium text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 transition-colors"
          >
            Cancel
          </Link>
          <span className="ml-auto text-xs text-zinc-400">Saved as draft · requires approval to publish</span>
        </div>
      </form>
    </div>
  );
}
