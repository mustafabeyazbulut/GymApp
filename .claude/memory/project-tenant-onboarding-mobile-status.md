---
name: project-tenant-onboarding-mobile-status
description: GymApp mobile Tenant Onboarding plan status - DONE (6/6 tasks), including a mid-plan Company Management addition and a visual-design revision. Read this first for this plan's history.
metadata:
  type: project
---

# GymApp Mobile Tenant Onboarding — Status: DONE (2026-09-17)

**Plan:** `docs/superpowers/plans/2026-09-17-tenant-onboarding.md` — see that file's own "PLAN COMPLETE" note at the top for the full task-by-task commit list. This memory captures the parts worth knowing without re-reading the whole plan.

## What shipped

- Role helpers on `MeResult` (`isSuperAdmin`, `staffAssignment`) — commit `05913e7`.
- `TenantRepository`/`RealTenantRepository`: `createCompany`, `listBranches`, `addStaffMember`, plus (added mid-plan) `listCompanies`, `getCompanyDetail`, `updateCompanyName`, `setCompanyActive` — commits `95594a4`, `73387c2`.
- `CreateCompanyScreen`, `AddStaffMemberScreen` — commit `8dc4fc6`.
- **Company Management screen (list + detail) — not in the original plan.** User feedback while reviewing the live Create Company screen: "Bence bu mantıksız olmuş... Firma Yönetimi butonu olacak, oradan girip yönetecek" (going straight from the drawer into a bare create-form is illogical; there should be a management screen). User chose the fuller scope when asked (list+detail+rename+active-toggle, not just a list). Required a **new backend surface** too: `GET /api/companies`, `GET /api/companies/{id}`, `PATCH /api/companies/{id}`, `PATCH /api/companies/{id}/active` in GymAppApi (commit `b74bcfe` there) — this plan's original scope only had `POST /api/companies`.
- Drawer wiring (commit `3486031`), then two follow-up user-feedback passes:
  1. Visual design polish (commit `7d4fb05`) — see [[feedback-visual-language]] and [[feedback-design-quality-bar]]. First version used bare `Material` with no border and `radiusMd`; corrected to match `membership_screen.dart`'s own card convention (`AppColors.surface` fill + `Border.all(AppColors.border)` + `AppSpacing.radiusLg`), added row icons, and reused the existing `StatusPill` widget for Aktif/Pasif instead of an ad-hoc badge.
  2. Drawer item order (same commit `7d4fb05`) — user: "Firma yönetimi butonu en üstte olması gerekmez mi... Dil/Dondur/Sil hep en altta olmalı ve üstte bir çizgi olsun." Admin items (Firma Yönetimi, Üye/Antrenör Ekle when applicable) now sit at the top of the drawer's item list, above a `Divider`, ahead of Dil/Hesabımı Dondur/Hesabımı Sil.
- Self-service registration retired (commit `3034443`): `register_screen.dart` deleted, `AuthRepository`/`RealAuthRepository`'s two methods removed, `/register` route + public-route entry removed, sign-up link removed from Login, all `register*`/`loginNoAccount` l10n keys removed. Two things the plan's own file list missed, fixed in the same commit: `forgot_password_screen.dart` was reusing `registerPasswordTooShort` (renamed to `commonPasswordTooShort`, kept — still a real field), and `dio_client.dart`'s `_noAuthPaths` had a stale pre-OTP-rework `/api/auth/register` entry (removed).

## Verification

Full flow tested genuinely end-to-end against a **live** `GymAppApi` backend (not just unit tests): `flutter build web --release`, served via `python -m http.server`, driven with Playwright (semantics enabled via the `flt-semantics-placeholder` click) — login as the seeded SuperAdmin, opened the drawer, listed companies, opened one, renamed it, toggled it inactive, confirmed the Pasif badge appeared back in the list. All real HTTP round-trips (`GET/PATCH /api/companies/...`), not mocked.

`flutter analyze`: no issues. `flutter test`: 65/65 green (final count, after Task 6's test removals).

## Cross-repo implication

`GymAppApi`'s own Tenant Onboarding plan has a Task 11 (retire the backend's `/api/auth/register/*` endpoints) that was explicitly blocked until this plan's Task 6 shipped. **It now has — that backend task is unblocked and safe to do**, if not already done by the time this is read (check `GymAppApi`'s own `docs/superpowers/plans/2026-09-17-tenant-onboarding.md` and its progress memory for current status).

## If resuming

Nothing pending in this plan — it's fully done. If asked to touch Company Management again (a "Şirket/Şube Seç" context switcher, editing a branch's own name/address, deleting a company outright, etc.), that's new scope, not a loose end of this plan.
