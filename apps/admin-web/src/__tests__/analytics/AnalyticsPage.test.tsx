import { render, screen, waitFor } from '@testing-library/react';
import AnalyticsPage from '@/app/analytics/page';
import { fetchAnalyticsSummary } from '@/lib/admin-api';

jest.mock('@/lib/admin-api', () => ({
  fetchAnalyticsSummary: jest.fn(),
}));

const mockFetch = jest.mocked(fetchAnalyticsSummary);

describe('AnalyticsPage', () => {
  it('shows loading state initially', () => {
    mockFetch.mockReturnValue(new Promise(() => {}));
    render(<AnalyticsPage />);
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('renders analytics summary after load', async () => {
    mockFetch.mockResolvedValue({
      totalEmployeesActive: 120,
      totalResponses: 450,
      overallAccuracyRate: 0.78,
      participationRate: 0.65,
      byCategory: null,
      suppressionApplied: false,
    });
    render(<AnalyticsPage />);
    await waitFor(() => expect(screen.getByText('120')).toBeInTheDocument());
    expect(screen.getByText('450')).toBeInTheDocument();
  });

  it('shows suppression alert when suppressionApplied is true', async () => {
    mockFetch.mockResolvedValue({
      totalEmployeesActive: 10,
      totalResponses: 5,
      overallAccuracyRate: 0.6,
      participationRate: 0.5,
      byCategory: null,
      suppressionApplied: true,
    });
    render(<AnalyticsPage />);
    await waitFor(() =>
      expect(screen.getByRole('alert')).toBeInTheDocument(),
    );
  });

  it('shows error view on failure', async () => {
    mockFetch.mockRejectedValue(new Error('Network error'));
    render(<AnalyticsPage />);
    await waitFor(() =>
      expect(screen.getByText(/network error/i)).toBeInTheDocument(),
    );
  });
});
