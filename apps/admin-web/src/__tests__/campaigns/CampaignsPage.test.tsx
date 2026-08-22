import { render, screen, waitFor } from '@testing-library/react';
import CampaignsPage from '@/app/campaigns/page';
import { fetchCampaigns } from '@/lib/admin-api';

jest.mock('@/lib/admin-api', () => ({
  fetchCampaigns: jest.fn(),
  createCampaign: jest.fn(),
  calculateEligibility: jest.fn(),
}));

const mockFetch = jest.mocked(fetchCampaigns);

describe('CampaignsPage', () => {
  it('shows loading state initially', () => {
    mockFetch.mockReturnValue(new Promise(() => {}));
    render(<CampaignsPage />);
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('shows empty state when no campaigns', async () => {
    mockFetch.mockResolvedValue({ data: [], meta: { page: 1, pageSize: 20, total: 0, totalPages: 1 } });
    render(<CampaignsPage />);
    await waitFor(() =>
      expect(screen.getByText(/no campaigns/i)).toBeInTheDocument(),
    );
  });

  it('renders campaign list', async () => {
    mockFetch.mockResolvedValue({
      data: [{
        id: 'abc-123',
        name: 'Q1 Campaign',
        status: 'active',
        startAt: '2026-01-01T00:00:00Z',
        endAt: '2026-03-31T23:59:59Z',
        eligibilityRule: 'complete all scenarios',
        rewardDescription: null,
        governanceDisclaimer: 'Final approval required.',
      }],
      meta: { page: 1, pageSize: 20, total: 1, totalPages: 1 },
    });
    render(<CampaignsPage />);
    await waitFor(() =>
      expect(screen.getByText('Q1 Campaign')).toBeInTheDocument(),
    );
  });
});
