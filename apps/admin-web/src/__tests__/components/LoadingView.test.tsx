import { render, screen } from '@testing-library/react';
import { LoadingView } from '@/components/ui/LoadingView';

describe('LoadingView', () => {
  it('renders with default message', () => {
    render(<LoadingView />);
    expect(screen.getByRole('status')).toBeInTheDocument();
    expect(screen.getByText('Loading…')).toBeInTheDocument();
  });

  it('renders with custom message', () => {
    render(<LoadingView message="Fetching scenarios…" />);
    expect(screen.getByText('Fetching scenarios…')).toBeInTheDocument();
  });

  it('has accessible aria-label matching the message', () => {
    const message = 'Loading data';
    render(<LoadingView message={message} />);
    expect(screen.getByRole('status')).toHaveAttribute('aria-label', message);
  });
});
