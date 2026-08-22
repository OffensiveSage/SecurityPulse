"""
Scenario endpoints.

GET  /api/v1/scenarios/today               — Today's scenario for the user.
GET  /api/v1/scenarios/{scenario_id}       — A specific scenario.
POST /api/v1/scenarios/{scenario_id}/responses — Submit a response.
GET  /api/v1/scenarios/{scenario_id}/result  — Get result after submission.

Security:
- T-02: All endpoints verify the user has an assignment.
- T-03: is_correct is never in pre-submission responses.
- T-04: Idempotency-Key header supports idempotent submission.
"""

from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies.auth import get_current_user
from app.core.database import get_db_session
from app.models.user import User
from app.schemas.scenario import (
    ResponseCreated,
    ResponseSubmission,
    ScenarioForEmployee,
    ScenarioResultResponse,
)
from app.services.scenario_service import (
    ConflictError,
    ExpiredAssignmentError,
    NoResponseExistsError,
    NotAssignedError,
    OptionNotFoundError,
    get_scenario_by_id,
    get_scenario_result,
    get_today_scenario_for_user,
    submit_response,
)

router = APIRouter(prefix="/scenarios")


@router.get("/today", response_model=ScenarioForEmployee)
async def get_today(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
) -> Response | ScenarioForEmployee:
    """Get today's scenario for the authenticated user.

    Returns 204 No Content if no active assignment exists.
    """
    scenario = await get_today_scenario_for_user(current_user.id, db)

    if scenario is None:
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    return ScenarioForEmployee.model_validate(scenario)


@router.get("/{scenario_id}", response_model=ScenarioForEmployee)
async def get_scenario(
    scenario_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
) -> ScenarioForEmployee:
    """Get a specific scenario by ID.

    Returns 403 if the user is not assigned to this scenario (T-02).
    """
    try:
        scenario = await get_scenario_by_id(scenario_id, current_user.id, db)
    except NotAssignedError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not assigned to this scenario.",
        ) from None

    return ScenarioForEmployee.model_validate(scenario)


@router.post(
    "/{scenario_id}/responses",
    response_model=ResponseCreated,
    status_code=status.HTTP_201_CREATED,
)
async def submit_scenario_response(
    scenario_id: uuid.UUID,
    body: ResponseSubmission,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> Response | ResponseCreated:
    """Submit a response to a scenario.

    Returns 201 on first submission, 200 on idempotent replay.
    Returns 409 on duplicate submission without an idempotency key.
    Returns 410 on expired assignment.
    """
    try:
        response_obj, is_new = await submit_response(
            user_id=current_user.id,
            scenario_id=scenario_id,
            selected_option_id=body.selected_option_id,
            db=db,
            idempotency_key=idempotency_key,
            response_time_ms=body.response_time_ms,
            source=body.source,
        )
    except NotAssignedError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not assigned to this scenario.",
        ) from None
    except ExpiredAssignmentError:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Assignment has expired.",
        ) from None
    except OptionNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Selected option does not belong to this scenario.",
        ) from None
    except ConflictError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already responded to this scenario. "
            "Provide an Idempotency-Key header for safe retries.",
        ) from None

    created = ResponseCreated(response_id=response_obj.id)
    if not is_new:
        # Idempotent replay — return 200 instead of 201
        return Response(
            content=created.model_dump_json(),
            status_code=status.HTTP_200_OK,
            media_type="application/json",
        )

    return created


@router.get("/{scenario_id}/result", response_model=ScenarioResultResponse)
async def get_result(
    scenario_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db_session)],
) -> ScenarioResultResponse:
    """Get the result of a scenario after submission (T-03).

    Returns 403 if the user has not submitted a response yet.
    """
    try:
        result = await get_scenario_result(current_user.id, scenario_id, db)
    except NoResponseExistsError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must submit a response before viewing results.",
        ) from None
    except NotAssignedError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scenario not found.",
        ) from None

    return ScenarioResultResponse(**result)
