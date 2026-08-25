"""
Development seed data for Phase 3.

Seeds 30 published scenarios with answer options and assignments
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
from app.models.response import Response
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
    uuid.UUID("a1000000-0000-0000-0000-000000000006"),
    uuid.UUID("a1000000-0000-0000-0000-000000000007"),
    uuid.UUID("a1000000-0000-0000-0000-000000000008"),
    uuid.UUID("a1000000-0000-0000-0000-000000000009"),
    uuid.UUID("a1000000-0000-0000-0000-000000000010"),
    uuid.UUID("a1000000-0000-0000-0000-000000000011"),
    uuid.UUID("a1000000-0000-0000-0000-000000000012"),
    uuid.UUID("a1000000-0000-0000-0000-000000000013"),
    uuid.UUID("a1000000-0000-0000-0000-000000000014"),
    uuid.UUID("a1000000-0000-0000-0000-000000000015"),
    uuid.UUID("a1000000-0000-0000-0000-000000000016"),
    uuid.UUID("a1000000-0000-0000-0000-000000000017"),
    uuid.UUID("a1000000-0000-0000-0000-000000000018"),
    uuid.UUID("a1000000-0000-0000-0000-000000000019"),
    uuid.UUID("a1000000-0000-0000-0000-000000000020"),
    uuid.UUID("a1000000-0000-0000-0000-000000000021"),
    uuid.UUID("a1000000-0000-0000-0000-000000000022"),
    uuid.UUID("a1000000-0000-0000-0000-000000000023"),
    uuid.UUID("a1000000-0000-0000-0000-000000000024"),
    uuid.UUID("a1000000-0000-0000-0000-000000000025"),
    uuid.UUID("a1000000-0000-0000-0000-000000000026"),
    uuid.UUID("a1000000-0000-0000-0000-000000000027"),
    uuid.UUID("a1000000-0000-0000-0000-000000000028"),
    uuid.UUID("a1000000-0000-0000-0000-000000000029"),
    uuid.UUID("a1000000-0000-0000-0000-000000000030"),
]


def _build_scenarios() -> list[dict[str, Any]]:
    """Return 30 seed scenarios with their answer options."""
    return [
        # ------------------------------------------------------------------ #
        # Scenario 1 — phishing / beginner  (existing)
        # ------------------------------------------------------------------ #
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
        # ------------------------------------------------------------------ #
        # Scenario 2 — social_engineering / intermediate  (existing)
        # ------------------------------------------------------------------ #
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
        # ------------------------------------------------------------------ #
        # Scenario 3 — phishing / intermediate  (existing)
        # ------------------------------------------------------------------ #
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
        # ------------------------------------------------------------------ #
        # Scenario 4 — social_engineering / advanced  (existing)
        # ------------------------------------------------------------------ #
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
        # ------------------------------------------------------------------ #
        # Scenario 5 — data_protection / beginner  (existing)
        # ------------------------------------------------------------------ #
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
        # ------------------------------------------------------------------ #
        # Scenario 6 — phishing / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[5],
            "title": "Invoice Email from Unknown Vendor",
            "prompt": (
                "An email arrives in your inbox with the subject 'Invoice #INV-2024-8821 "
                "Overdue — Action Required.' The sender is billing@acme-invoices.net and "
                "you don't recognize the vendor. The email contains a PDF attachment "
                "labeled 'Final_Notice.pdf'. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Fake invoice emails are a common phishing vector used to trick "
                "employees into opening malicious attachments or paying fraudulent "
                "invoices. Opening the PDF could execute malware, and paying would "
                "result in financial loss."
            ),
            "recommended_action": (
                "Do not open the attachment. Verify with your accounts payable team "
                "whether this vendor exists in the system. Report the email to IT "
                "security as a potential phishing attempt."
            ),
            "options": [
                {
                    "text": "Open the PDF to see the invoice details",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Forward it to accounts payable so they can handle it",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Delete it — you don't recognize the sender",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Do not open the attachment and report to IT security",
                    "is_correct": True,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 7 — phishing / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[6],
            "title": "DocuSign Request for HR Policy Update",
            "prompt": (
                "You receive an email from 'DocuSign <no-reply@docusign-secure.com>' "
                "asking you to review and sign an updated HR policy document. "
                "The link in the email goes to 'docusign-secure.com/review/hr-policy'. "
                "Your company does use DocuSign for some documents. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "The sender domain 'docusign-secure.com' is not the legitimate "
                "DocuSign domain (docusign.com). Attackers register similar-looking "
                "domains to impersonate trusted services. Clicking the link could "
                "harvest your credentials or deliver malware."
            ),
            "recommended_action": (
                "Do not click the link. Verify with HR directly whether they sent "
                "a DocuSign request. If you need to access DocuSign, navigate directly "
                "to docusign.com rather than following email links."
            ),
            "options": [
                {
                    "text": "Click the link and sign the document — HR policy updates are routine",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Verify with HR directly whether a DocuSign was sent, then access via docusign.com",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Reply to the email asking HR to confirm",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Forward it to your manager and let them decide",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 8 — phishing / advanced  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[7],
            "title": "Spear Phishing Email Referencing Your Project",
            "prompt": (
                "You receive an email from a sender claiming to be a consultant "
                "you worked with last quarter on the Apex project. The email "
                "references specific project names and your manager's first name, "
                "and asks you to review a shared document via a OneDrive link. "
                "You don't recall this consultant's email address. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "Spear phishing emails use personal details gathered from LinkedIn, "
                "company websites, or previous breaches to appear credible. The "
                "specific project details make this email convincing, but the unknown "
                "sender address is a red flag that warrants verification before "
                "clicking any links."
            ),
            "recommended_action": (
                "Do not click the link. Contact the consultant directly using a "
                "phone number or email address from your existing records to verify "
                "the request. Report the email to IT security regardless of the outcome."
            ),
            "options": [
                {
                    "text": "Click the OneDrive link — the project details prove it's legitimate",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Reply to the email asking them to resend from their official address",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Verify by contacting the consultant through previously known contact info and report to IT",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Search for the document name in your email history to see if it exists",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 9 — phishing / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[8],
            "title": "Voicemail Notification with Login Link",
            "prompt": (
                "You receive an email titled 'You have a new voicemail from +1-555-0147' "
                "with a Play button linking to 'voicemail-listen.com/msg?id=7842'. "
                "Your company uses a voicemail-to-email service, but the link domain "
                "doesn't match the service your company uses. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Voicemail phishing (vishing via email) tricks employees into clicking "
                "links to hear fake voicemails. The mismatched domain is a clear "
                "indicator that this is not from your company's legitimate service. "
                "Clicking could lead to a credential harvesting page."
            ),
            "recommended_action": (
                "Do not click the link. Access your voicemail directly through your "
                "company's official portal or phone system. Report the suspicious "
                "email to IT security."
            ),
            "options": [
                {
                    "text": "Click the Play button to hear the voicemail",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Access voicemail through the official company portal and report the email",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Call the number back to see who left the message",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Ignore it — you can check voicemail later on your desk phone",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 10 — phishing / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[9],
            "title": "Password Reset Email You Didn't Request",
            "prompt": (
                "You receive an email from 'accounts@company-portal.org' saying "
                "a password reset was requested for your corporate account. "
                "The email includes a Reset Password button. You did not request "
                "a password reset. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Unsolicited password reset emails are a phishing technique. "
                "The domain 'company-portal.org' is not your company's domain. "
                "Clicking the link could redirect you to a fake login page designed "
                "to steal your current credentials."
            ),
            "recommended_action": (
                "Do not click the Reset Password button. Log into your corporate "
                "account directly by typing the URL in your browser to confirm "
                "your password is unchanged. Report the email to IT security immediately."
            ),
            "options": [
                {
                    "text": "Click Reset Password — someone may have tried to access your account",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Ignore it — password reset emails that you didn't request are always spam",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Log into your account directly via the official URL and report the email to IT",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Reply to confirm whether the reset is legitimate",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 11 — phishing / advanced  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[10],
            "title": "Callback Phishing via Fake Security Alert",
            "prompt": (
                "You receive an email from 'Microsoft Security <security@microsoft-alerts.info>' "
                "saying suspicious sign-ins were detected on your Microsoft 365 account. "
                "The email asks you to call a toll-free number to speak with a Microsoft "
                "security specialist and does not include any links. What should you do?"
            ),
            "category": ScenarioCategory.phishing,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "This is a callback phishing attack (also called TOAD — Telephone-Oriented "
                "Attack Delivery). By avoiding links, attackers bypass email security "
                "filters. If you call the number, a fake 'specialist' will attempt to "
                "install remote access software or extract credentials over the phone."
            ),
            "recommended_action": (
                "Do not call the number. Check your Microsoft 365 sign-in activity "
                "directly at account.microsoft.com. Report the email to IT security "
                "and verify account status through the official Microsoft portal."
            ),
            "options": [
                {
                    "text": "Call the number — there are no suspicious links so it must be safe",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Check sign-in activity at account.microsoft.com and report the email to IT",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Reply to the email asking for the specialist's employee ID",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Change your Microsoft password and then call the number as a precaution",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 12 — password_security / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[11],
            "title": "Reusing Your Corporate Password on a Personal Site",
            "prompt": (
                "You need to create an account for a fitness tracking website. "
                "To keep things simple, you're considering using your corporate "
                "email address and the same password you use to log into company "
                "systems. Is this acceptable?"
            ),
            "category": ScenarioCategory.password_security,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Password reuse is one of the most common causes of corporate "
                "account compromise. If the fitness site suffers a data breach, "
                "attackers will attempt your credentials on corporate systems "
                "in a technique called credential stuffing."
            ),
            "recommended_action": (
                "Use a unique, strong password for every account. Use your company "
                "password manager to generate and store credentials for personal "
                "accounts if permitted, or use a separate personal password manager."
            ),
            "options": [
                {
                    "text": "Yes — it's easier to remember one strong password",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "No — use a unique password for the fitness site and store it in a password manager",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Yes — personal sites are low risk and don't affect corporate security",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "It's fine as long as the fitness site has HTTPS",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 13 — password_security / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[12],
            "title": "Colleague Asks to Borrow Your Login",
            "prompt": (
                "Your colleague is presenting a client demo in 10 minutes and "
                "has forgotten their laptop. They ask if they can log into their "
                "client-facing dashboard using your credentials just for the demo. "
                "They promise to change your password back afterward. What do you do?"
            ),
            "category": ScenarioCategory.password_security,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Sharing credentials violates security policy and removes individual "
                "accountability. Actions taken under your credentials are attributed "
                "to you, and your colleague would have access to data beyond what the "
                "demo requires. There are always better alternatives in emergencies."
            ),
            "recommended_action": (
                "Decline to share your credentials. Help your colleague contact IT "
                "to reset their access or use a guest/demo account. If a demo account "
                "isn't available, escalate to a manager to find an approved solution."
            ),
            "options": [
                {
                    "text": "Lend your credentials — it's just for 10 minutes",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Decline and help them contact IT for an approved alternative",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Log in yourself and let them drive the keyboard for the demo",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Create a temporary password for them and change it back later",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 14 — password_security / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[13],
            "title": "Password Written on a Sticky Note",
            "prompt": (
                "You notice your coworker has their VPN password written on a "
                "sticky note attached to their monitor in an open-plan office. "
                "They say they wrote it there because the password is too complex "
                "to remember. What should you do?"
            ),
            "category": ScenarioCategory.password_security,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Passwords written in visible locations can be read by visitors, "
                "contractors, or anyone walking through the office. VPN credentials "
                "in particular provide remote network access, making this a "
                "significant security risk."
            ),
            "recommended_action": (
                "Advise your coworker to remove the sticky note immediately and "
                "store the password in the company-approved password manager instead. "
                "If they are unaware of the password manager, help them get set up."
            ),
            "options": [
                {
                    "text": "Ignore it — your coworker knows their own risk tolerance",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Take a photo of the note as evidence and report it to HR",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Advise them to remove the note and use the company password manager",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Tell them to fold the note and keep it in their desk drawer instead",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 15 — password_security / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[14],
            "title": "IT Helpdesk Asks for Your Password Over the Phone",
            "prompt": (
                "You receive a call from someone identifying themselves as an IT "
                "helpdesk technician. They say they're troubleshooting a system "
                "issue affecting your account and need your password to verify "
                "your identity. They reference your employee ID number correctly. "
                "What should you do?"
            ),
            "category": ScenarioCategory.password_security,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Legitimate IT support staff never need your password to resolve "
                "issues — they have administrative tools to reset or access accounts "
                "without your credentials. Knowing your employee ID proves nothing; "
                "that information is often easily obtainable."
            ),
            "recommended_action": (
                "Refuse to provide your password. Hang up and call the IT helpdesk "
                "back using the official number from the company intranet. Report "
                "the attempted vishing call to your security team."
            ),
            "options": [
                {
                    "text": "Provide the password — they already know your employee ID so they must be IT",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Refuse, hang up, and call IT back on the official number to report it",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Give them a hint but not the full password",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Ask them to send the request by email instead so you have a record",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 16 — password_security / advanced  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[15],
            "title": "Prompted to Change Password After a Site Breach",
            "prompt": (
                "You receive a legitimate notification from HaveIBeenPwned that your "
                "corporate email address appeared in a recent data breach of a "
                "third-party project management tool you use. You used a unique "
                "password for that tool, not your corporate password. What should "
                "you do?"
            ),
            "category": ScenarioCategory.password_security,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "Even with a unique password for the breached site, the exposure "
                "of your corporate email address in a breach means attackers may "
                "attempt targeted phishing or use other leaked information. The "
                "breached site's password must still be changed, and security "
                "teams need to be informed of the exposure."
            ),
            "recommended_action": (
                "Change your password on the breached third-party tool immediately. "
                "Report the breach notification to your security team so they can "
                "monitor for suspicious activity. Enable MFA on the affected tool "
                "if not already enabled."
            ),
            "options": [
                {
                    "text": "Do nothing — you used a unique password so your corporate account is safe",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Change your corporate password as a precaution and ignore the third-party tool",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Change the breached site's password, report to security, and enable MFA on that tool",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Unsubscribe from the third-party tool entirely to reduce future risk",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 17 — password_security / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[16],
            "title": "Choosing a New Password After a Forced Reset",
            "prompt": (
                "Your company's security policy requires you to set a new password. "
                "You want to make it memorable. You're considering 'Summer2024!' "
                "because it meets the minimum complexity requirements of uppercase, "
                "lowercase, number, and special character. Is this a good choice?"
            ),
            "category": ScenarioCategory.password_security,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Predictable patterns like season+year+punctuation are among the "
                "first entries in password cracking dictionaries. Meeting minimum "
                "complexity requirements does not make a password strong if it "
                "follows common patterns attackers already know to try."
            ),
            "recommended_action": (
                "Use a password manager to generate a long, random password of at "
                "least 16 characters. If you must create one manually, use an "
                "unpredictable passphrase of four or more random words instead "
                "of a season-year pattern."
            ),
            "options": [
                {
                    "text": "Yes — it meets all complexity requirements",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "No — use a password manager to generate a long random password instead",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Yes — adding an exclamation mark makes it strong enough",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "It depends — only avoid it if other employees might guess it",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 18 — social_engineering / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[17],
            "title": "Delivery Person Asks to Be Let Through a Secure Door",
            "prompt": (
                "You're approaching the badge-access door to your office floor "
                "when a person in a delivery uniform, carrying several large boxes, "
                "asks you to hold the door open so they can bring in a delivery. "
                "They say the reception desk called ahead. What should you do?"
            ),
            "category": ScenarioCategory.social_engineering,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "This is tailgating — a physical social engineering technique where "
                "an unauthorized person gains access by following an authorized "
                "employee through a secured entry. The delivery uniform and boxes "
                "create a sympathetic scenario to lower your guard."
            ),
            "recommended_action": (
                "Do not hold the door. Direct the delivery person to the reception "
                "desk or building security to be properly signed in and escorted. "
                "Every visitor must badge in through official channels."
            ),
            "options": [
                {
                    "text": "Hold the door — they're clearly a delivery person and their hands are full",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Ask them to wait and call reception to confirm before letting them through",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Direct them to the reception desk or building security for proper access",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Let them in and immediately alert building security afterward",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 19 — social_engineering / advanced  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[18],
            "title": "Contractor Claims to Need Temporary Admin Rights",
            "prompt": (
                "A contractor you've worked with for two months sends a Slack message "
                "saying they've been given approval to run some deployment scripts and "
                "need temporary local admin rights on the production server. They say "
                "the approval came from your VP of Engineering in a meeting you weren't "
                "in. What should you do?"
            ),
            "category": ScenarioCategory.social_engineering,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "Privilege escalation requests via informal channels are a high-risk "
                "social engineering pattern. Even trusted contractors should go through "
                "formal access request processes. The claim of out-of-band approval "
                "cannot be verified through Slack alone and is a common manipulation tactic."
            ),
            "recommended_action": (
                "Do not grant elevated access through an informal request. Ask the "
                "contractor to submit a formal access request ticket and verify the "
                "VP's approval directly with them via another channel before any "
                "permissions are changed."
            ),
            "options": [
                {
                    "text": "Grant the access — you've worked with the contractor for two months",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Ask them to submit a formal access request and verify VP approval directly",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Grant temporary access but set it to expire in 24 hours",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Ask the contractor to send the VP's approval email as proof",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 20 — social_engineering / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[19],
            "title": "Phone Call Claiming to Be from Your Bank",
            "prompt": (
                "You receive a call on your work phone from someone claiming to be "
                "from your company's corporate banking partner. They say they've "
                "detected unusual activity and need to verify your company's account "
                "details. They ask you to confirm your company's bank account number "
                "and routing number. What do you do?"
            ),
            "category": ScenarioCategory.social_engineering,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Vishing (voice phishing) attackers impersonate banks and financial "
                "institutions to extract sensitive financial data. Legitimate banks "
                "will never call and ask you to read out full account numbers. "
                "The caller could be recording this information for fraud."
            ),
            "recommended_action": (
                "Do not provide any account information. Hang up and call your "
                "company's bank back using the number on the official bank website "
                "or on your company's banking statements. Report the call to your "
                "finance and security teams."
            ),
            "options": [
                {
                    "text": "Provide the details — the bank needs to protect the company's money",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Hang up and call the bank back on the official number, then report it",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Ask them to send the request by email so you have a record",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Verify by asking for the caller's employee ID before sharing anything",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 21 — data_protection / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[20],
            "title": "Emailing a Spreadsheet of Customer PII to Yourself",
            "prompt": (
                "You're working from home and need access to a spreadsheet containing "
                "customer names, email addresses, and phone numbers for a project. "
                "The file isn't accessible via VPN so you're considering emailing "
                "it to your personal Gmail account so you can work on it. "
                "What should you do?"
            ),
            "category": ScenarioCategory.data_protection,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Sending customer PII to personal email accounts violates data "
                "protection regulations such as GDPR and CCPA and your company's "
                "data handling policy. Personal email accounts lack enterprise-grade "
                "security controls and the data could be exposed in a personal account breach."
            ),
            "recommended_action": (
                "Do not email the file to your personal account. Contact IT to resolve "
                "the VPN access issue or request a secure remote access method. If the "
                "work is urgent, escalate to your manager to find an approved solution."
            ),
            "options": [
                {
                    "text": "Email it to yourself — it's just temporary and you'll delete it after",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Upload it to your personal Google Drive and access it from home",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Contact IT to fix VPN access or find an approved secure method",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Copy only the rows you need into a new file and email that instead",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 22 — data_protection / advanced  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[21],
            "title": "Disposing of Printed Customer Reports",
            "prompt": (
                "You have a stack of printed customer account reports from last month's "
                "audit that you no longer need. The reports contain customer names, "
                "account numbers, and transaction histories. The office recycling bin "
                "is right next to your desk. What is the correct way to dispose of "
                "these documents?"
            ),
            "category": ScenarioCategory.data_protection,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "Printed documents containing personal or financial data must be "
                "shredded before disposal. Placing them in recycling or trash "
                "exposes sensitive customer information that could be retrieved "
                "by anyone with access to that bin, including unauthorized individuals."
            ),
            "recommended_action": (
                "Use the cross-cut shredder designated for sensitive documents, "
                "or place them in the locked confidential waste bin if your office "
                "has one. Never place documents containing PII or financial data "
                "in standard recycling or trash."
            ),
            "options": [
                {
                    "text": "Place them in the recycling bin — they're just paper",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Shred them using the cross-cut shredder or place in the locked confidential waste bin",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Keep them in a desk drawer until the end of the year for reference",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Tear them in half and put them in the regular trash",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 23 — data_protection / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[22],
            "title": "Screen Left Unlocked in a Shared Space",
            "prompt": (
                "You step away from your laptop in the company cafeteria to grab "
                "a coffee, leaving your screen unlocked with a confidential "
                "quarterly financial report open. You expect to be back in "
                "under two minutes. Is this acceptable?"
            ),
            "category": ScenarioCategory.data_protection,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Leaving a screen unlocked in a shared or public area exposes "
                "confidential information to anyone who walks by, even for short "
                "durations. Shoulder surfing and opportunistic photography are "
                "real threats in cafeterias, lobbies, and co-working spaces."
            ),
            "recommended_action": (
                "Always lock your screen when stepping away, no matter how briefly. "
                "Use the keyboard shortcut (Windows+L or Cmd+Ctrl+Q) to lock "
                "instantly. Better yet, avoid working on confidential documents "
                "in shared spaces where shoulder surfing is possible."
            ),
            "options": [
                {
                    "text": "Yes — two minutes is too short for anyone to do anything",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Yes — the cafeteria is inside the office so it's secure",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "No — always lock your screen before stepping away, even briefly",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "It depends on whether anyone else is in the cafeteria at the time",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 24 — device_security / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[23],
            "title": "Found a USB Drive in the Parking Lot",
            "prompt": (
                "You find a USB flash drive in the company parking lot. It has a "
                "label that says 'Q3 Payroll Data.' You're curious whether it belongs "
                "to a colleague and consider plugging it into your work laptop to "
                "check the contents so you can return it. What should you do?"
            ),
            "category": ScenarioCategory.device_security,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Attackers deliberately leave USB drives in parking lots and lobbies "
                "('baiting') to entice curious employees. Plugging an unknown USB drive "
                "into a work device can automatically execute malware, install keyloggers, "
                "or give attackers remote access — even if the drive appears to contain "
                "normal files."
            ),
            "recommended_action": (
                "Do not plug the USB drive into any device. Hand it to IT security "
                "or building security so it can be safely analyzed. Report where and "
                "when you found it."
            ),
            "options": [
                {
                    "text": "Plug it into your work laptop to check for an owner's contact information",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Plug it into a personal device since it's less risky than a work laptop",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Hand it to IT security without plugging it into anything",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Leave it where you found it — it's not your problem",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 25 — device_security / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[24],
            "title": "Automatic OS Update Prompt During Work Hours",
            "prompt": (
                "A pop-up on your work laptop says a critical security update is "
                "available and recommends installing it now. You're in the middle "
                "of a project and the update will require a restart. Your last "
                "update was 45 days ago. What should you do?"
            ),
            "category": ScenarioCategory.device_security,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Security patches fix known vulnerabilities that attackers actively "
                "exploit. A 45-day delay increases exposure to these threats. While "
                "timing the restart is reasonable, repeatedly postponing updates "
                "creates a significant security gap."
            ),
            "recommended_action": (
                "Save your work and install the update at the earliest opportunity "
                "— ideally within the same day. Do not dismiss critical security "
                "updates repeatedly. If updates are interfering with work, discuss "
                "a patching schedule with IT rather than skipping them."
            ),
            "options": [
                {
                    "text": "Dismiss the update — you'll do it when you're less busy",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Save your work and install the update at the earliest opportunity today",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Disable automatic update notifications so they don't interrupt work",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Wait until the end of the quarter when things quiet down",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 26 — device_security / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[25],
            "title": "Charging Work Phone at a Public USB Kiosk",
            "prompt": (
                "Your work phone battery is at 5% and you have two hours until "
                "your flight. You spot a USB charging kiosk in the airport terminal. "
                "You're considering using it to charge your phone. What should you do?"
            ),
            "category": ScenarioCategory.device_security,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Public USB charging kiosks can be compromised to perform 'juice "
                "jacking' — a technique where malware is loaded onto a device or "
                "data is extracted via the USB data connection. Work phones often "
                "contain sensitive corporate data, email, and VPN configurations."
            ),
            "recommended_action": (
                "Use your own AC power adapter with an outlet, or use a portable "
                "battery pack instead of public USB kiosks. If you must use a USB "
                "kiosk, use a charge-only USB cable (with data pins removed) or a "
                "USB data blocker dongle."
            ),
            "options": [
                {
                    "text": "Use the kiosk — airports are secure and monitored locations",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Use the kiosk but turn the phone off first to prevent data transfer",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Use your AC adapter with a wall outlet or a portable battery pack instead",
                    "is_correct": True,
                    "order": 2,
                },
                {
                    "text": "Use the kiosk but only for 15 minutes to minimize risk",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 27 — device_security / advanced  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[26],
            "title": "Installing Unapproved Software for a Client Project",
            "prompt": (
                "A client requires you to use a specific screen recording tool "
                "for project documentation. The tool is not on your company's "
                "approved software list. Your manager says 'just install it, "
                "we need to get this done.' What should you do?"
            ),
            "category": ScenarioCategory.device_security,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "Unapproved software bypasses IT security review processes that "
                "screen tools for malware, data exfiltration capabilities, and "
                "licensing compliance. Screen recording tools in particular can "
                "capture sensitive information. A manager's informal approval does "
                "not substitute for the formal IT approval process."
            ),
            "recommended_action": (
                "Do not install the unapproved software. Submit a software approval "
                "request to IT for expedited review, citing the client requirement. "
                "Ask IT whether an already-approved tool can meet the same need in "
                "the interim."
            ),
            "options": [
                {
                    "text": "Install it — your manager approved it and the client needs it",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Submit an expedited IT approval request and use an approved alternative in the interim",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Install it on a personal device and use that for the client project",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Install it temporarily and uninstall it when the project ends",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 28 — physical_security / beginner  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[27],
            "title": "Visitor Without a Badge on Your Floor",
            "prompt": (
                "While walking to a meeting room, you notice an unfamiliar person "
                "wandering in your office area without a visitor badge. They look "
                "confident and are dressed professionally. What should you do?"
            ),
            "category": ScenarioCategory.physical_security,
            "difficulty": ScenarioDifficulty.beginner,
            "explanation": (
                "Unauthorized individuals on secured floors pose a physical security "
                "risk, regardless of how professional they appear. Attackers often "
                "dress and act confidently to avoid being challenged. Visitor badges "
                "exist so employees can quickly identify who has authorized access."
            ),
            "recommended_action": (
                "Politely ask if they need help and direct them back to reception. "
                "If they cannot explain their presence or become evasive, notify "
                "building security immediately. Never assume that appearance alone "
                "means someone is authorized."
            ),
            "options": [
                {
                    "text": "Ignore them — they look like they belong here",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "Politely offer to help and direct them to reception; alert security if they're evasive",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "Follow them discreetly to see where they go",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "Assume reception already cleared them since they got past the main door",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 29 — physical_security / intermediate  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[28],
            "title": "Sensitive Conversation in a Public Coffee Shop",
            "prompt": (
                "You're working from a coffee shop and join a call with your "
                "team to discuss a confidential product roadmap and upcoming "
                "partnership negotiations. The café is fairly busy. You have "
                "your earbuds in. What is the biggest security concern here?"
            ),
            "category": ScenarioCategory.physical_security,
            "difficulty": ScenarioDifficulty.intermediate,
            "explanation": (
                "Even with earbuds in, your side of the conversation — your spoken "
                "words and anything visible on your screen — can be overheard or "
                "seen by nearby people. Competitors, journalists, or bad actors "
                "could be seated nearby, and public spaces offer no confidentiality "
                "guarantees."
            ),
            "recommended_action": (
                "Avoid discussing confidential business matters in public spaces. "
                "If the call cannot be rescheduled, find a private space such as "
                "a phone booth, your car, or a private meeting room. At minimum, "
                "reposition so your screen is not visible to others."
            ),
            "options": [
                {
                    "text": "The risk that the café's Wi-Fi is unencrypted",
                    "is_correct": False,
                    "order": 0,
                },
                {
                    "text": "The risk that your spoken words and screen content can be overheard or seen by nearby people",
                    "is_correct": True,
                    "order": 1,
                },
                {
                    "text": "The risk that your laptop could be stolen while you're distracted by the call",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "The risk that the meeting link could be shared publicly by another attendee",
                    "is_correct": False,
                    "order": 3,
                },
            ],
        },
        # ------------------------------------------------------------------ #
        # Scenario 30 — physical_security / advanced  (new)
        # ------------------------------------------------------------------ #
        {
            "id": _SCENARIO_IDS[29],
            "title": "Printed Presentation Left on a Conference Room Table",
            "prompt": (
                "After a client presentation, you realize you left a printed "
                "copy of the slides — which include non-public financial "
                "forecasts and a client's internal org chart — on the conference "
                "room table. The room is now booked for another group that "
                "includes external vendors. What should you do?"
            ),
            "category": ScenarioCategory.physical_security,
            "difficulty": ScenarioDifficulty.advanced,
            "explanation": (
                "Documents containing confidential business data must be retrieved "
                "or secured before unauthorized parties enter the room. External "
                "vendors are not entitled to see financial forecasts or client org "
                "charts, and leaving them could constitute a data breach or breach "
                "of client confidentiality."
            ),
            "recommended_action": (
                "Immediately retrieve the printed documents before the next group "
                "enters. If you cannot get there in time, contact the meeting organizer "
                "or building security to secure the room. Shred the documents once "
                "retrieved. Review your document handling procedures to prevent recurrence."
            ),
            "options": [
                {
                    "text": "Retrieve the documents immediately before the next group enters",
                    "is_correct": True,
                    "order": 0,
                },
                {
                    "text": "Send an email to the vendor group asking them to discard any materials they find",
                    "is_correct": False,
                    "order": 1,
                },
                {
                    "text": "Ask the next meeting's organizer to collect the slides and return them to you",
                    "is_correct": False,
                    "order": 2,
                },
                {
                    "text": "The information is already presented to the client so it's no longer sensitive",
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

            # Track the correct option ID so we can create a past Response
            correct_option_id: uuid.UUID | None = None

            for opt_data in sdata["options"]:
                option = AnswerOption(
                    id=uuid.uuid4(),
                    scenario_id=scenario.id,
                    text=opt_data["text"],
                    is_correct=opt_data["is_correct"],
                    display_order=opt_data["order"],
                )
                session.add(option)
                if opt_data["is_correct"]:
                    correct_option_id = option.id

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

            # Create past responses for scenarios 2–5 (indices 1–4) so the
            # mock employee has a visible answer history and streak.
            if 0 < i <= 4 and correct_option_id is not None:
                response = Response(
                    id=uuid.uuid4(),
                    user_id=mock_employee.id,
                    scenario_id=scenario.id,
                    selected_option_id=correct_option_id,
                    is_correct=True,
                    source="app",
                    submitted_at=available_from + timedelta(hours=9),
                )
                session.add(response)

        await session.commit()
        logger.info("seed_data_created", scenarios=len(scenarios_data))


async def main() -> None:
    """Entry point: create engine from settings and run the seed."""

    from sqlalchemy.ext.asyncio import create_async_engine

    from app.core.config import get_settings

    settings = get_settings()

    if not settings.ALLOW_MOCK_AUTH or settings.APP_ENV == "production":
        logger.error(
            "seed_refused",
            reason="Seed only runs when APP_ENV=development and ALLOW_MOCK_AUTH=true",
        )
        return

    # SQLite requires connect_args; Postgres uses pool_size / max_overflow.
    db_url = settings.DATABASE_URL
    if db_url.startswith("sqlite"):
        _engine = create_async_engine(db_url, echo=True, future=True)
    else:
        _engine = create_async_engine(
            db_url,
            pool_size=settings.DATABASE_POOL_SIZE,
            max_overflow=settings.DATABASE_MAX_OVERFLOW,
            echo=True,
            future=True,
        )

    try:
        await seed_dev_data(_engine)
    finally:
        await _engine.dispose()


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
