"""
Shared Pydantic schemas used across multiple features.

These define the standard API envelope shapes.
"""

from __future__ import annotations

from typing import Any, Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class ErrorDetail(BaseModel):
    """Standard error detail object."""

    code: str = Field(description="Machine-readable error code")
    message: str = Field(description="Human-readable error message")
    details: dict[str, Any] = Field(default_factory=dict, description="Additional error context")
    correlation_id: str = Field(description="Request correlation identifier")


class PaginationMeta(BaseModel):
    """Pagination metadata for list responses."""

    page: int
    page_size: int
    total: int
    total_pages: int


class PaginatedResponse(BaseModel, Generic[T]):  # noqa: UP046
    """Generic paginated response wrapper."""

    data: list[T]
    meta: PaginationMeta
