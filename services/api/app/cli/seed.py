"""
Development seed data for Phase 3.

Seeds 5 published scenarios with answer options and assignments
for the mock employee user. Idempotent: checks if data exists
before creating.

Only runs when APP_ENV=development AND ALLOW_MOCK_AUTH=true.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from app.models.assignment import Assignment
from app.models.scenario import (
    AnswerOption,
    Scenario,
    ScenarioCategory,
    ScenarioDifficulty,
    ScenarioStatus,
)
from app.models.user import User

logger = structlog.get_logger(__name__)

# Fixed UUIDs for deterministic seeding
_SCENARIO_IDS = [
    uuid.UUID("a1000000-0000-0000-0000-000000000001"),
    uuid.UUID("a1000000-0000-0000-0000-000000000002"),
    uuid.UUID("a1000000-0000-0000-0000-000000000003"),
    uuid.UUID("a1000000-0000-0000-0000-000000000004"),
    uuid.UUID("a1000000-0000-0000-0000-000000000005"),
]


def _build_scenarios() -> list[dict[str, Any]]:
    """Return the 5 seed scenarios with their answer options."""
    return [
        {
            "id": _SCENARIO_IDS[0],
            "title": "Suspicious Email from IT Support",
            "prompt": (
                "You receive an email from 'IT Support <support@1t-helpdesk.com>' "
                "asking you to verify your credentials by clicking a link. "
                "The email says your account will be locked in 24 hours if you "
                "don't comply. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "This is a phishing attempt. The sender domain '1t-helpdesk.com' "
                "uses the number '1' instead of the letter 'l' to mimic a "
                "legitimate IT domain. Urgency tactics like account lockout "
                "threats are common in phishing emails."
            ),
            "recommended_action": (
                "Do not click any links. Report the email to your IT security "
                "team using the 'Report Phishing' button or forward it to "
                "the security team."
            ),
            "options": [
                {
                    "text": "Click the link and enter your credentials to prevent lockout",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Report the email to IT security without clicking any links",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Reply to the email asking if it's legitimate",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Forward the email to your colleagues as a warning",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        {
            "id": _SCENARIO_IDS[1],
            "title": "Unexpected MFA Push Notifications",
            "prompt": (
                "You're at home on a Saturday evening when you receive three "
                "MFA push notifications on your phone for your corporate "
                "account. You didn't initiate any login. What should you do?"
            ),
            "category": ScenarioCategory.social_engineering,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "This is an MFA fatigue attack. Attackers who have already "
                "obtained your password repeatedly trigger MFA prompts, "
                "hoping you'll approve one out of annoyance or confusion. "
                "Approving even one prompt grants them full access."
            ),
            "recommended_action": (
                "Deny all unexpected MFA prompts. Change your password "
                "immediately and report the incident to your security team. "
                "Enable number-matching MFA if available."
            ),
            "options": [
                {
                    "text": "Approve one of the notifications to make them stop",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Deny all prompts, change your password, and report to security",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Ignore the notifications and go back to what you were doing",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Turn off MFA on your account to prevent future notifications",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        {
            "id": _SCENARIO_IDS[2],
            "title": "Free Wi-Fi QR Code in Lobby",
            "prompt": (
                "You notice a printed QR code taped near the elevator in your "
                "office lobby. It says 'Scan for Free Guest Wi-Fi' but has no "
                "company branding. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Unauthorized QR codes could redirect to malicious websites "
                "that steal credentials or install malware. Legitimate "
                "corporate Wi-Fi access should be provided through official "
                "IT channels, not anonymous printed QR codes."
            ),
            "recommended_action": (
                "Do not scan unknown QR codes. Report the unauthorized "
                "posting to building security or your IT team. Use only "
                "officially provided Wi-Fi connection methods."
            ),
            "options": [
                {
                    "text": "Scan it — free Wi-Fi is convenient for work",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Scan it on your personal phone to test if it's safe first",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Report the unauthorized QR code to building security or IT",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Take a photo and share it on your team chat for feedback",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        {
            "id": _SCENARIO_IDS[3],
            "title": "Urgent Request from CEO via Teams",
            "prompt": (
                "You receive a Teams message from someone whose display name "
                "matches your CEO's name. They ask you to urgently purchase "
                "five $200 gift cards and send the redemption codes. They say "
                "they're in a board meeting and can't call. What should you do?"
            ),
            "category": ScenarioCategory.social_engineering,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "This is a CEO impersonation / business email compromise "
                "attack. Attackers create fake accounts with executive names "
                "and use urgency to bypass normal approval processes. "
                "Legitimate executives never ask employees to purchase "
                "gift cards via chat."
            ),
            "recommended_action": (
                "Do not purchase anything. Verify the request through a "
                "different communication channel (call the CEO's known "
                "phone number). Report the suspicious message to your "
                "security team."
            ),
            "options": [
                {
                    "text": "Purchase the gift cards quickly — the CEO is waiting",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Ask the CEO for more details in the same Teams chat",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Verify through a different channel and report to security",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Forward the message to your manager for approval",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        {
            "id": _SCENARIO_IDS[4],
            "title": "Uploading Client Data to Public AI Tool",
            "prompt": (
                "A colleague mentions they've been pasting client contract "
                "details into a public AI chatbot to help summarize documents "
                "faster. They say it saves hours of work. What should you do?"
            ),
            "category": ScenarioCategory.data_protection,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Pasting client data into public AI tools exposes confidential "
                "information to third parties. The AI provider may store, "
                "log, or use the data for training. This violates data "
                "protection policies and could breach client contracts."
            ),
            "recommended_action": (
                "Advise your colleague to stop immediately. Report the data "
                "exposure to your security or privacy team. Use only "
                "company-approved tools for handling confidential data."
            ),
            "options": [
                {
                    "text": "It's fine — AI tools are just for convenience",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Report the data exposure and advise them to use approved tools only",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Try it yourself to see if it really saves time",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Tell them to anonymize the data before pasting it",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
    ]


async def seed_dev_data(engine: AsyncEngine) -> None:
    """Seed development data. Idempotent — checks before creating."""
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as session:
        # Check if scenarios already exist
        result = await session.execute(
            select(Scenario).where(Scenario.id == _SCENARIO_IDS[0]),
        )
        if result.scalar_one_or_none() is not None:
            logger.info("seed_data_already_exists", action="skipping")
            return

        # Get the mock employee user
        result = await session.execute(
            select(User).where(User.identity_provider_subject == "mock-employee-001"),
        )
        mock_employee = result.scalar_one_or_none()

        if mock_employee is None:
            logger.info("seed_data_no_mock_employee", action="skipping")
            return

        now = datetime.now(UTC)
        scenarios_data = _build_scenarios()

        for i, sdata in enumerate(scenarios_data):
            scenario = Scenario(
                id=sdata["id"],
                title=sdata["title"],
                prompt=sdata["prompt"],
                category=sdata["category"],
                difficulty=sdata["difficulty"],
                explanation=sdata["explanation"],
                recommended_action=sdata["recommended_action"],
                status=ScenarioStatus.published,
            )
            session.add(scenario)

            for opt_data in sdata["options"]:
                option = AnswerOption(
                    id=uuid.uuid4(),
                    scenario_id=scenario.id,
                    text=opt_data["text"],
                    is_correct=opt_data["is_correct"],
                    display_order=opt_data["order"],
                )
                session.add(option)

            # Stagger assignments: first one is today, rest are past days
            if i == 0:
                available_from = now.replace(hour=0, minute=0, second=0, microsecond=0)
                due_at = available_from + timedelta(days=1)
            else:
                start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
                available_from = start_of_day - timedelta(days=i)
                due_at = available_from + timedelta(days=1)

            assignment = Assignment(
                id=uuid.uuid4(),
                scenario_id=scenario.id,
                user_id=mock_employee.id,
                available_from=available_from,
                due_at=due_at,
            )
            session.add(assignment)

        await session.commit()
        logger.info("seed_data_created", scenarios=len(scenarios_data))
