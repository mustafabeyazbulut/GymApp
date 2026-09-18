# Memory Index

- [Membership real-data status](project-membership-real-data-status.md) — Membership screen wired to real PackageAssignment data + context switcher (2026-09-18), mobile half of the backend's Package roadmap step 5. Read first before touching Membership or resuming step 5 (Home/Classes/Progress still mock).
- [Never remove registration](feedback-never-remove-registration.md) — self-service registration is permanent; a 2026-09-17 attempt to remove it was reverted. Read before touching Register/CreateCompany/AddStaffMember.
- [Tenant Onboarding mobile status](project-tenant-onboarding-mobile-status.md) — Tasks 1-5 done + Company Management addition; Task 6 (retire registration) REVERTED, do not redo. Read this first if asked about company/staff management screens.
- [OTP security actions status](project-otp-security-actions.md) — OTP register, phone normalization, notifications, language switcher, OTP-gated freeze/reactivate/delete, membership-screen visual fixes. Supersedes the "no OTP" line in the Real Auth file below.
- [Real Auth design](project-real-auth-design.md) — backend + mobile Real Auth plan, COMPLETE (14/14, 15/15). Historical/design-rationale context; for current status read the file above instead.
- [Member Experience status](project-member-experience-status.md) — PLAN COMPLETE (17/17 tasks), historical context; superseded by the files above.
- [Mobile Foundation status](project-mobile-foundation-status.md) — prior, now-superseded plan (Branch proof-of-concept, since deleted); historical context only.
- [Memory location rule](feedback-memory-location.md) — all mobile memory lives in this repo, never in GymAppApi's memory.
- [Design quality bar](feedback-design-quality-bar.md) — every screen, even POC ones, must match the reference mockup's polish, not a rough placeholder.
- [Visual language](feedback-visual-language.md) — standing, locked-in visual system (flat bg, thin-line fields, functional-only green, fixed logo position) for EVERY screen, not just Auth.
- [Implementer must not update memory](feedback-implementer-must-not-update-memory.md) — only the coordinator writes the shared status memory, only after independent review passes, never the implementer subagent itself.
