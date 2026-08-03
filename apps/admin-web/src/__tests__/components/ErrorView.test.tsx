import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ErrorView } from '@/components/ui/ErrorView';

describe('ErrorView', () => {
  it('renders with required message', () => {
    render(<ErrorView message="Network error" />);
    expect(screen.getByRole('alert')).toBeInTheDocument();
    expect(screen.getByText('Network error')).toBeInTheDocument();
  });

  it('uses default title when none provided', () => {
    render(<ErrorView message="error" />);
    expect(screen.getByText('Something went wrong')).toBeInTheDocument();
  });

  it('renders retry button when onRetry provided', async () => {
    const onRetry = jest.fn();
    render(<ErrorView message="error" onRetry={onRetry} />);
    const button = screen.getByRole('button', { name: /try again/i });
    await userEvent.click(button);
    expect(onRetry).toHaveBeenCalledTimes(1);
  });

  it('does not render retry button when onRetry not provided', () => {
    render(<ErrorView message="error" />);
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });
});
