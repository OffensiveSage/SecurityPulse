"""
Unit tests for campaign_service.

Tests campaign creation, listing, and eligibility calculation,
including suppression logic for small counts.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.schemas.admin import MIN_ANALYTICS_GROUP_SIZE, CampaignCreate


@pytest.mark.asyncio
class TestCreateCampaign:
    async def test_creates_campaign_and_returns_schema(self) -> None:
        """create_campaign persists a campaign and returns CampaignSchema."""
        from app.services.campaign_service import create_campaign

        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()

        campaign_id = uuid.uuid4()

        async def fake_refresh(obj):
            obj.id = campaign_id
            obj.name = "Test Campaign"
            obj.status = MagicMock()
            obj.status.value = "draft"
            obj.start_at = datetime(2026, 10, 1, tzinfo=UTC)
            obj.end_at = datetime(2026, 10, 31, tzinfo=UTC)
            obj.eligibility_rule = '{"min_responses": 3}'
            obj.reward_description = "$100 gift card"

        db.refresh = fake_refresh

        payload = CampaignCreate(
            name="Test Campaign",
            start_at=datetime(2026, 10, 1, tzinfo=UTC),
            end_at=datetime(2026, 10, 31, tzinfo=UTC),
            eligibility_rule='{"min_responses": 3}',
            reward_description="$100 gift card",
        )

        result = await create_campaign(payload, db)

        db.add.assert_called_once()
        db.commit.assert_called_once()
        assert result.name == "Test Campaign"
        assert result.status == "draft"
        assert "governance_disclaimer" in result.model_dump()
        assert result.reward_description == "$100 gift card"

    async def test_governance_disclaimer_is_always_present(self) -> None:
        """The governance disclaimer must always be included in the schema."""
        from app.services.campaign_service import GOVERNANCE_DISCLAIMER, create_campaign

        db = AsyncMock()
        db.add = MagicMock()
        db.commit = AsyncMock()

        async def fake_refresh(obj):
            obj.id = uuid.uuid4()
            obj.name = "Disclaimer Test"
            obj.status = MagicMock()
            obj.status.value = "draft"
            obj.start_at = datetime(2026, 10, 1, tzinfo=UTC)
            obj.end_at = datetime(2026, 10, 31, tzinfo=UTC)
            obj.eligibility_rule = "{}"
            obj.reward_description = None

        db.refresh = fake_refresh

        payload = CampaignCreate(
            name="Disclaimer Test",
            start_at=datetime(2026, 10, 1, tzinfo=UTC),
            end_at=datetime(2026, 10, 31, tzinfo=UTC),
            eligibility_rule="{}",
        )

        result = await create_campaign(payload, db)
        assert result.governance_disclaimer == GOVERNANCE_DISCLAIMER


@pytest.mark.asyncio
class TestCalculateEligibility:
    async def test_raises_value_error_when_campaign_not_found(self) -> None:
        """calculate_eligibility raises ValueError when campaign does not exist."""
        from app.services.campaign_service import calculate_eligibility

        db = AsyncMock()
        db.get = AsyncMock(return_value=None)

        campaign_id = uuid.uuid4()
        with pytest.raises(ValueError, match=str(campaign_id)):
            await calculate_eligibility(campaign_id, db)

    async def test_suppresses_count_when_below_threshold(self) -> None:
        """eligible_count is 0 and suppressed=True when count < MIN_ANALYTICS_GROUP_SIZE."""
        from app.services.campaign_service import calculate_eligibility

        campaign_id = uuid.uuid4()
        mock_campaign = MagicMock()
        mock_campaign.start_at = datetime(2026, 9, 1, tzinfo=UTC)
        mock_campaign.end_at = datetime(2026, 9, 30, tzinfo=UTC)

        db = AsyncMock()
        db.get = AsyncMock(return_value=mock_campaign)

        count_below_threshold = MIN_ANALYTICS_GROUP_SIZE - 1
        count_result = MagicMock()
        count_result.scalar_one.return_value = count_below_threshold
        db.execute = AsyncMock(return_value=count_result)

        result = await calculate_eligibility(campaign_id, db)

        assert result.suppressed is True
        assert result.eligible_count == 0
        assert isinstance(result.calculated_at, datetime)

    async def test_returns_count_when_above_threshold(self) -> None:
        """eligible_count is returned as-is when count >= MIN_ANALYTICS_GROUP_SIZE."""
        from app.services.campaign_service import calculate_eligibility

        campaign_id = uuid.uuid4()
        mock_campaign = MagicMock()
        mock_campaign.start_at = datetime(2026, 9, 1, tzinfo=UTC)
        mock_campaign.end_at = datetime(2026, 9, 30, tzinfo=UTC)

        db = AsyncMock()
        db.get = AsyncMock(return_value=mock_campaign)

        count_above_threshold = MIN_ANALYTICS_GROUP_SIZE + 10
        count_result = MagicMock()
        count_result.scalar_one.return_value = count_above_threshold
        db.execute = AsyncMock(return_value=count_result)

        result = await calculate_eligibility(campaign_id, db)

        assert result.suppressed is False
        assert result.eligible_count == count_above_threshold

    async def test_returns_suppressed_at_exactly_threshold_minus_one(self) -> None:
        """Boundary: exactly threshold-1 responses triggers suppression."""
        from app.services.campaign_service import calculate_eligibility

        campaign_id = uuid.uuid4()
        mock_campaign = MagicMock()
        mock_campaign.start_at = datetime(2026, 9, 1, tzinfo=UTC)
        mock_campaign.end_at = datetime(2026, 9, 30, tzinfo=UTC)

        db = AsyncMock()
        db.get = AsyncMock(return_value=mock_campaign)

        count_result = MagicMock()
        count_result.scalar_one.return_value = MIN_ANALYTICS_GROUP_SIZE - 1
        db.execute = AsyncMock(return_value=count_result)

        result = await calculate_eligibility(campaign_id, db)
        assert result.suppressed is True

    async def test_not_suppressed_at_exactly_threshold(self) -> None:
        """Boundary: exactly MIN_ANALYTICS_GROUP_SIZE responses is not suppressed."""
        from app.services.campaign_service import calculate_eligibility

        campaign_id = uuid.uuid4()
        mock_campaign = MagicMock()
        mock_campaign.start_at = datetime(2026, 9, 1, tzinfo=UTC)
        mock_campaign.end_at = datetime(2026, 9, 30, tzinfo=UTC)

        db = AsyncMock()
        db.get = AsyncMock(return_value=mock_campaign)

        count_result = MagicMock()
        count_result.scalar_one.return_value = MIN_ANALYTICS_GROUP_SIZE
        db.execute = AsyncMock(return_value=count_result)

        result = await calculate_eligibility(campaign_id, db)
        assert result.suppressed is False
        assert result.eligible_count == MIN_ANALYTICS_GROUP_SIZE


@pytest.mark.asyncio
class TestListCampaigns:
    async def test_returns_paginated_response(self) -> None:
        """list_campaigns returns a PaginatedResponse with correct meta."""
        from app.services.campaign_service import list_campaigns

        db = AsyncMock()

        count_result = MagicMock()
        count_result.scalar_one.return_value = 0

        rows_result = MagicMock()
        rows_result.scalars.return_value.all.return_value = []

        db.execute = AsyncMock(side_effect=[count_result, rows_result])

        result = await list_campaigns(db, page=1, page_size=20)

        assert result.meta.page == 1
        assert result.meta.page_size == 20
        assert result.meta.total == 0
        assert result.meta.total_pages == 1
        assert result.data == []

    async def test_calculates_total_pages_correctly(self) -> None:
        """total_pages is calculated as ceil(total / page_size)."""
        from app.services.campaign_service import list_campaigns

        db = AsyncMock()

        count_result = MagicMock()
        count_result.scalar_one.return_value = 45  # 45 campaigns

        rows_result = MagicMock()
        rows_result.scalars.return_value.all.return_value = []

        db.execute = AsyncMock(side_effect=[count_result, rows_result])

        result = await list_campaigns(db, page=1, page_size=20)

        # ceil(45 / 20) = 3
        assert result.meta.total_pages == 3
