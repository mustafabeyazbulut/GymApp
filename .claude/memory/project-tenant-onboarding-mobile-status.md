---
name: project-tenant-onboarding-mobile-status
description: GymApp mobile Tenant Onboarding plan status - Tasks 1-5 DONE (+ Company Management addition + visual-design revision); Task 6 (retire registration) executed then REVERTED - wrong. Read this first for this plan's history.
metadata:
  type: project
---

# GymApp Mobile Tenant Onboarding — Status: Tasks 1-5 done, Task 6 REVERTED (2026-09-17)

**⚠️ Task 6 ("retire self-service registration") was wrong and was reverted (commit `92c4a1a`) after the user corrected the product model — see [[feedback-never-remove-registration]] before touching Register/CreateCompany/AddStaffMember again.** Registration is permanent; companies assign already-registered users, they don't create new accounts by phone. `CreateCompanyCommand`/`AddStaffMemberCommand` currently DO create new users by phone — that's now known to be wrong too, and is unscoped follow-up work, not yet done.

**Plan:** `docs/superpowers/plans/2026-09-17-tenant-onboarding.md` — see that file's own "PLAN COMPLETE" note at the top for the full task-by-task commit list. This memory captures the parts worth knowing without re-reading the whole plan.

## What shipped

- Role helpers on `MeResult` (`isSuperAdmin`, `staffAssignment`) — commit `05913e7`.
- `TenantRepository`/`RealTenantRepository`: `createCompany`, `listBranches`, `addStaffMember`, plus (added mid-plan) `listCompanies`, `getCompanyDetail`, `updateCompanyName`, `setCompanyActive` — commits `95594a4`, `73387c2`.
- `CreateCompanyScreen`, `AddStaffMemberScreen` — commit `8dc4fc6`.
- **Company Management screen (list + detail) — not in the original plan.** User feedback while reviewing the live Create Company screen: "Bence bu mantıksız olmuş... Firma Yönetimi butonu olacak, oradan girip yönetecek" (going straight from the drawer into a bare create-form is illogical; there should be a management screen). User chose the fuller scope when asked (list+detail+rename+active-toggle, not just a list). Required a **new backend surface** too: `GET /api/companies`, `GET /api/companies/{id}`, `PATCH /api/companies/{id}`, `PATCH /api/companies/{id}/active` in GymAppApi (commit `b74bcfe` there) — this plan's original scope only had `POST /api/companies`.
- Drawer wiring (commit `3486031`), then two follow-up user-feedback passes:
  1. Visual design polish (commit `7d4fb05`) — see [[feedback-visual-language]] and [[feedback-design-quality-bar]]. First version used bare `Material` with no border and `radiusMd`; corrected to match `membership_screen.dart`'s own card convention (`AppColors.surface` fill + `Border.all(AppColors.border)` + `AppSpacing.radiusLg`), added row icons, and reused the existing `StatusPill` widget for Aktif/Pasif instead of an ad-hoc badge.
  2. Drawer item order (same commit `7d4fb05`) — user: "Firma yönetimi butonu en üstte olması gerekmez mi... Dil/Dondur/Sil hep en altta olmalı ve üstte bir çizgi olsun." Admin items (Firma Yönetimi, Üye/Antrenör Ekle when applicable) now sit at the top of the drawer's item list, above a `Divider`, ahead of Dil/Hesabımı Dondur/Hesabımı Sil.
- **Self-service registration removal (commit `3034443`) was WRONG and was REVERTED (commit `92c4a1a`).** The user's correction: registration is a permanent feature — anyone registers and uses the system as a plain member; a company assigns *already-registered* members to roles, it doesn't create new accounts. Full story in [[feedback-never-remove-registration]]. `hasActiveMembership` was also fixed the same day (commit `9e842ed`) to require a real `Member`-role assignment, not just any assignment — unrelated bug, found while investigating this area (a SuperAdmin was wrongly landing on the fake member Home screen).

## Verification

Full flow tested genuinely end-to-end against a **live** `GymAppApi` backend (not just unit tests): `flutter build web --release`, served via `python -m http.server`, driven with Playwright (semantics enabled via the `flt-semantics-placeholder` click) — login as the seeded SuperAdmin, opened the drawer, listed companies, opened one, renamed it, toggled it inactive, confirmed the Pasif badge appeared back in the list. All real HTTP round-trips (`GET/PATCH /api/companies/...`), not mocked.

`flutter analyze`: no issues. `flutter test`: 65/65 green (final count, after Task 6's test removals).

## Cross-repo implication

`GymAppApi` did the same wrong thing in its own Task 11 (commit `345c6f5`) and also reverted it (commit `967fc43`) the same day. Neither repo's registration endpoints/screens should be touched without reading [[feedback-never-remove-registration]] first.

## If resuming

Real remaining work in this area: rework `CreateCompanyCommand`/`AddStaffMemberCommand` (both repos) and their mobile screens to pick an *existing* registered user (search by phone/name) instead of creating a new `User` when the phone doesn't already exist — this is what the corrected product model actually requires, and hasn't been built yet as of 2026-09-17. Confirm scope with the user before starting; don't assume this note fully specifies it. Company Management itself (list/detail/rename/activate) needs nothing further unless asked (e.g. a "Şirket/Şube Seç" context switcher, editing a branch's own name/address, deleting a company outright — all new scope).
