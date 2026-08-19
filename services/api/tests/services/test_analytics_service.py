"""
Unit tests for analytics_service.

Validates group suppression logic and correct aggregation of response data.
Uses mocked AsyncSession to avoid requiring a live database.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.schemas.admin import MIN_ANALYTICS_GROUP_SIZE, AnalyticsSummary, CategoryAccuracy


@pytest.mark.asyncio
class TestGetAnalyticsSummary:
    async def test_suppresses_categories_below_minimum_group_size(self) -> None:
        """Categories with fewer than MIN_ANALYTICS_GROUP_SIZE responses must be suppressed."""
        from app.services.analytics_service import get_analytics_summary

        db = AsyncMock()
        small_count = MIN_ANALYTICS_GROUP_SIZE - 1  # Below threshold

        # Build sequential return values for db.execute():
        # 1. total_employees_active
        # 2. total_responses
        # 3. total_correct (for overall accuracy)
        # 4. users_responded (for participation rate)
        # 5. category rows

        def make_scalar_result(value):
            r = MagicMock()
            r.scalar_one.return_value = value
            return r

        # Category row mock for a small group
        small_row = MagicMock()
        small_row.category = "phishing"
        small_row.response_count = small_count
        small_row.correct_count = 2

        cat_result = MagicMock()
        cat_result.all.return_value = [small_row]

        db.execute = AsyncMock(
            side_effect=[
                make_scalar_result(50),   # total_employees_active
                make_scalar_result(small_count),  # total_responses
                make_scalar_result(2),    # total_correct
                make_scalar_result(3),    # users_responded
                cat_result,               # category rows
            ]
        )

        result = await get_analytics_summary(db)

        assert isinstance(result, AnalyticsSummary)
        assert result.suppression_applied is True
        assert result.by_category is not None
        assert len(result.by_category) == 1
        cat = result.by_category[0]
        assert cat.suppressed is True
        assert cat.accuracy_rate == 0.0
        assert cat.category == "phishing"

    async def test_does_not_suppress_categories_at_or_above_minimum(self) -> None:
        """Categories meeting MIN_ANALYTICS_GROUP_SIZE must not be suppressed."""
        from app.services.analytics_service import get_analytics_summary

        db = AsyncMock()
        count = MIN_ANALYTICS_GROUP_SIZE  # Exactly at threshold

        def make_scalar_result(value):
            r = MagicMock()
            r.scalar_one.return_value = value
            return r

        large_row = MagicMock()
        large_row.category = "social_engineering"
        large_row.response_count = count
        large_row.correct_count = 4

        cat_result = MagicMock()
        cat_result.all.return_value = [large_row]

        db.execute = AsyncMock(
            side_effect=[
                make_scalar_result(100),  # total_employees_active
                make_scalar_result(count),  # total_responses
                make_scalar_result(4),    # total_correct
                make_scalar_result(5),    # users_responded
                cat_result,               # category rows
            ]
        )

        result = await get_analytics_summary(db)

        assert result.suppression_applied is False
        assert result.by_category is not None
        cat = result.by_category[0]
        assert cat.suppressed is False
        assert cat.accuracy_rate == pytest.approx(4 / count)

    async def test_returns_zero_rates_when_no_responses(self) -> None:
        """Overall accuracy and participation rate are 0.0 when there are no responses."""
        from app.services.analytics_service import get_analytics_summary

        db = AsyncMock()

        def make_scalar_result(value):
            r = MagicMock()
            r.scalar_one.return_value = value
            return r

        cat_result = MagicMock()
        cat_result.all.return_value = []

        db.execute = AsyncMock(
            side_effect=[
                make_scalar_result(100),  # total_employees_active
                make_scalar_result(0),    # total_responses
                make_scalar_result(0),    # total_correct
                make_scalar_result(0),    # users_responded
                cat_result,               # category rows (empty)
            ]
        )

        result = await get_analytics_summary(db)

        assert result.overall_accuracy_rate == 0.0
        assert result.participation_rate == 0.0
        assert result.by_category is None

    async def test_returns_zero_participation_when_no_active_users(self) -> None:
        """Participation rate is 0.0 when total_employees_active is 0."""
        from app.services.analytics_service import get_analytics_summary

        db = AsyncMock()

        def make_scalar_result(value):
            r = MagicMock()
            r.scalar_one.return_value = value
            return r

        cat_result = MagicMock()
        cat_result.all.return_value = []

        db.execute = AsyncMock(
            side_effect=[
                make_scalar_result(0),  # total_employees_active
                make_scalar_result(0),  # total_responses
                make_scalar_result(0),  # total_correct
                make_scalar_result(0),  # users_responded
                cat_result,
            ]
        )

        result = await get_analytics_summary(db)
        assert result.participation_rate == 0.0

    async def test_mixed_categories_partial_suppression(self) -> None:
        """Only categories below threshold are suppressed; others are shown."""
        from app.services.analytics_service import get_analytics_summary

        db = AsyncMock()

        def make_scalar_result(value):
            r = MagicMock()
            r.scalar_one.return_value = value
            return r

        small_row = MagicMock()
        small_row.category = "ransomware"
        small_row.response_count = 2  # Below threshold
        small_row.correct_count = 1

        large_row = MagicMock()
        large_row.category = "phishing"
        large_row.response_count = 10  # Above threshold
        large_row.correct_count = 7

        cat_result = MagicMock()
        cat_result.all.return_value = [small_row, large_row]

        db.execute = AsyncMock(
            side_effect=[
                make_scalar_result(50),   # total_employees_active
                make_scalar_result(12),   # total_responses
                make_scalar_result(8),    # total_correct
                make_scalar_result(10),   # users_responded
                cat_result,
            ]
        )

        result = await get_analytics_summary(db)

        assert result.suppression_applied is True
        suppressed = [c for c in result.by_category if c.suppressed]  # type: ignore[union-attr]
        visible = [c for c in result.by_category if not c.suppressed]  # type: ignore[union-attr]
        assert len(suppressed) == 1
        assert suppressed[0].category == "ransomware"
        assert len(visible) == 1
        assert visible[0].category == "phishing"
        assert visible[0].accuracy_rate == pytest.approx(0.7)
