---
name: project-membership-real-data-status
description: GymApp mobile - Membership screen wired to real PackageAssignment data (2026-09-18), part of the backend's Multi-role/Package roadmap step 5. Read this before touching the Membership screen or resuming step 5's remaining scope (Home/Classes/Progress, staff context switcher).
metadata:
  type: project
---

# GymApp Mobile — Membership real-data wiring (2026-09-18)

This is the mobile half of `GymAppApi`'s `project-member-package-linkage-design.md` roadmap step 5 ("Mobile: multi-assignment/multi-company awareness + context switcher"), done autonomously (user asked to continue unattended: "geliştir... bana bir şey sormadan geliştir"). Read the backend file first for the full roadmap context; this file only covers the mobile-specific decisions and status.

## What shipped

- **`MeResult.staffAssignments`** (list, `lib/features/auth/domain/me_result.dart`) — every GymAdmin/BranchManager assignment the caller holds, not just the first (`staffAssignment` singular is kept as-is, still used by `AddStaffMemberScreen`/drawer for the actual target company). `AppDrawer`'s "Personel Ekle" row now shows a `trailingText` naming which company it targets whenever `staffAssignments.length > 1`, so a multi-company GymAdmin isn't silently misled about which company the action hits.
- **`MeResult.packageAssignments`** — parses the richer `MePackageAssignmentDto` fields GetMe now returns (see the backend memory file: `id`, `price`, `startDate`, `sessionCount`, `remainingSessions` were added this session, commit `8422b4d` in GymAppApi).
- **Membership screen fully rewired to real data** (`lib/features/membership/`): `FakeMembershipRepository` deleted outright (same "no archived mock" convention as the Branch→Member-Experience pivot). `membershipsProvider` derives the list of `MembershipSummary` directly from `currentUserProvider`'s `packageAssignments` (no extra network call — single source of truth). `RealMembershipRepository` only implements `getPayments(id)` against `GET /api/package-assignments/{id}/payments`.
- **Context switcher**: when `memberships.length > 1` (a Member with packages at more than one company, or more than one package at the same company), the screen shows a `ChoiceChip` row (`company · package`) above the card; `selectedMembershipIdProvider` holds the current pick.
- **Freeze/renew buttons removed, not stubbed.** Real-backend check (`FreezePackageAssignmentCommand`/Unfreeze/Cancel in `PackageAssignmentsController`, GymAppApi) confirmed these are `[Authorize(Policy = "StaffManagement")]`-only — there is no Member self-service freeze endpoint at all. Keeping the old mock buttons would have been UI that silently does nothing once wired to a real backend, so they were replaced with a static `membershipStaffContactNote` ("contact gym staff to freeze/cancel/renew") instead. **If a self-service freeze is ever wanted, it needs a new backend design decision first** (does it need staff approval, rate limits, etc.) — this is not a "just add the button back" mobile fix.
- **Empty-state gate fixed to match the product's real model:** was `currentUser.hasActiveMembership` (checks for an `Assignment` with `role == 'Member'` — a legacy/mostly-dead path only created by the old `CreateAssignmentCommand`, per the backend roadmap's "Core model decision": a package, not an Assignment row, is what makes someone a member of a company). Membership screen's empty state now gates on the real `memberships.isEmpty` instead. **Home/Classes/Progress screens were NOT touched and still use `hasActiveMembership`/mock data** — this inconsistency is now known and documented, not fixed everywhere, see "Not done" below.

## Backend gap found (not a mobile bug, don't try to route around it)

`TenantResolutionService.ResolveForUserAsync` (GymAppApi) deliberately "picks the FIRST Assignment" for a multi-company staff user — this is a documented, pre-existing backend limitation, not something introduced this session. It means `AddStaffMemberScreen`/`listBranches()` always act on whichever company `staffAssignment` (singular, first match) resolves to, even for a GymAdmin of 2+ companies. A real fix needs the backend's ambient tenant context (`ITenantContext`/`TenantContextMiddleware`) to accept an explicit caller-selected company instead of always resolving ambiently — a cross-cutting change touching every `StaffManagement` endpoint, deliberately NOT attempted this session (too architecturally risky to do unsupervised). The drawer's new `trailingText` (see above) only makes the existing behavior visible, it doesn't fix it.

## Not done (open scope for whoever resumes step 5)

- **Home, Classes, Progress screens are still 100% mock** (`Fake...Repository`, per the old Member Experience plan). Wiring them to real data (next reservation, weekly check-in attendance, etc.) is real, separate work — Reservation/CheckIn backend endpoints exist (GymAppApi step 4) but there's no "all my upcoming reservations across every company" aggregate endpoint yet, only per-`PackageAssignment` ones (`GET /api/package-assignments/{id}/reservations`).
- No live end-to-end smoke test against a real running backend was done this session (Docker Desktop wasn't running, Postgres unavailable) — verification is `flutter analyze` (0 issues) + `flutter test` (77/77 green) only. If picking this back up, do a real smoke test first per this repo's established practice (see [[project-tenant-onboarding-mobile-status]]'s Playwright-driven verification) before trusting the UI actually renders correctly.
- Backend also got an unrelated, pre-existing uncommitted CORS change (`Program.cs`, commit `236b7df` in GymAppApi) picked up and committed this session — needed for a Flutter web client to call the API cross-origin during dev, not otherwise related to this feature.

## If resuming

1. Read GymAppApi's `project-member-package-linkage-design.md` step 5 entry first for the master status.
2. Decide with the user whether to wire Home/Classes/Progress next, or move to step 6 (video/content library, still fully undesigned), or revisit the staff multi-company context switcher (real architecture work, needs the user's judgment on the ambient-tenant-context redesign approach).
3. Run `git log --oneline` in both repos to confirm state — trust git over this file if they disagree.
