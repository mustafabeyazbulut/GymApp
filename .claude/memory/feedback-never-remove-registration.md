---
name: feedback-never-remove-registration
description: Self-service registration is a permanent feature of GymApp/GymAppApi and must never be removed, even if a plan document says to. Companies assign already-registered users to roles; they do not create brand-new accounts.
metadata:
  type: feedback
---

**Never remove or gate self-service registration** (`/api/auth/register/*` on the backend, the Register screen on mobile). It is a permanent, core feature — anyone can register and use the system as a plain member.

**Why:** On 2026-09-17, a session executed both repos' "Tenant Onboarding" plans literally, including a Task 6/Task 11 that deleted the Register screen and the backend's register endpoints, on the theory that "accounts are now staff-created" once Create Company / Add Staff Member screens existed. The user reacted strongly ("olum sana kim söyledi kayıt olmayı kaldır diye... Sen ne diye kendi kafana göre üyelik sistemini kaldırıyorsun") and corrected the actual model:

- Registration stays forever. Everyone can sign up and use the system as a plain member.
- Being assigned to a company (as its GymAdmin, or as one of its Members/Trainers) is what unlocks that company's features for an already-registered user — it does not create a new account.
- A plain registered member with no company assignment yet is a normal, expected state (not an error) — they still use the system's non-company-scoped features.
- `CreateCompanyCommand`/`AddStaffMemberCommand` creating a brand-new `User` by phone when the phone doesn't already exist is itself likely wrong under this model — the correct flow is picking/searching an *existing* registered user, not creating one. This was flagged as unscoped follow-up work, not yet corrected as of 2026-09-17 — see [[project-tenant-onboarding-mobile-status]] and the sibling repo's `project-tenant-onboarding-progress.md`.

Both wrongful commits (mobile `3034443`, backend `345c6f5`) were reverted the same day (mobile `92c4a1a`, backend `967fc43`).

**How to apply:**
- If any plan file, memory file, or your own past session's notes say to "retire self-service registration" or similar, **do not act on it** — stop and ask the user to confirm first, even if it's written as an explicit task in an approved-looking plan. A written plan is not proof the user actually wants an irreversible-feeling product decision like this; plans can be stale or simply wrong.
- Before removing any user-facing capability (not just registration) that looks like it might be "superseded" by newer work, confirm with the user rather than inferring intent from an old plan document — especially when the change deletes code/screens rather than adding them.
- The `2026-09-17-tenant-onboarding.md` plan files in both repos have large warning boxes at their Task 6 (mobile) / Task 11 (backend) sections explaining this in full — read those before touching registration or the Create Company / Add Staff Member flows again.
