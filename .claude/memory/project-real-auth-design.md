---
name: project-real-auth-design
description: GymApp real Auth feature (backend-integrated login/register) — brainstorming in progress, spans GymApp mobile + GymAppApi backend. Read this first for the current auth design status; supersedes the "next task" section of [[project-member-experience-status]].
metadata:
  type: project
---

# Real Auth — Design Status (brainstorming, not yet spec'd)

**STATUS: mid-brainstorm** (superpowers:brainstorming skill), spanning both repos. Not yet written as a spec doc, no implementation plan yet, no code written. This file is the resume point if the session is interrupted before the spec is written — read it, then continue the brainstorm rather than re-asking questions already answered below.

## Why this file exists / sequence so far

1. Visual design pass for the real Login screen was run first (frontend-design skill, pure HTML/artifact mockups, no code) — went through 3 rounds before approval: v1 (gradient hero + stats row) and v2 (top hero/pattern + bottom sheet) were both rejected ("çok kötü" — user flagged the hero/pattern area, the ŞUBE/ÜYE/PUAN stats row, the general green/black atmosphere, AND the overall composition as all wrong). v3 — flat near-black background, thin-underline form fields (no boxed/filled inputs), green (`#8BC34A`) used only functionally (focus underline + submit button, never as ambient glow/gradient/pattern) — was approved as "çok daha iyi". One follow-up bug (a negative-margin CSS hack misaligning the invalid-credentials error text) was fixed. **This visual direction is FINAL for login.**
2. The same 4 already-shipped screens (Ana Sayfa/Dersler/Gelişimim/Üyeliğim) were also mocked in this new language (still HTML, using the app's real Fake-repository content, not lorem) and approved as "aynı dil" (same language) — see decision below on restyling the real shipped code to match.
3. User then said "bu tasarımı uygulayacağız, en başından başla" (we'll implement this design, start from the beginning) — that's what triggered moving from pure visual exploration into a real brainstorming session for the backend-integrated Auth feature itself (data model, endpoints, token strategy, mobile wiring).
4. Mid-brainstorm, user also raised a previously-undiscussed requirement: users with no tenant/Company. This turned out to already fit the existing (Backend Foundation) domain model with zero changes needed — see below.

**Approved artifact (login + 4 screens, both now final):** https://claude.ai/artifact/MZ3o6pBqNd2rYawmG97hNS (owned by this session/user; read it back with `Artifact action:"read"` if a fresh session needs to see the actual mockup rather than just this text description).

## Decisions locked in so far (do not re-ask, do not re-litigate without the user)

- **Visual language (both repos' concern, but a mobile/Flutter fact):** flat single-plane dark background (no gradients/glow/diagonal patterns anywhere), thin 1px underline-style form fields (no filled/boxed `TextFormField` look), green used ONLY on interactive/functional elements (focused field underline, primary button, selected states) — never as ambient wash, never a decorative stats/trust row. This is a real, deliberate rollback from a busier direction the user explicitly rejected twice — don't drift back toward gradients/badges/hero-pattern treatments in future screens without being asked.
- **The 4 already-shipped screens WILL be restyled** to this same visual language as part of this feature's implementation (user confirmed explicitly after an initial back-and-forth about what "restyle" even meant — confirmed intent was "we approved a design, use it, don't change it," i.e. yes, apply it everywhere, not login-only). Screen logic/data/providers do not change, only the visual layer (replace `Card`/filled-box styling with the thin-line/flat-surface treatment). Scope this as its own task(s) in the implementation plan, separate from the auth wiring itself.
- **Tenant-less / open-membership model — the core new architectural decision:**
  - ALL self-registered users are plain Members. There is no company/tenant picker anywhere in the mobile registration flow, and no "request to join a gym" UI. Registration is fully open (email or phone + password + name), producing a `User` row with **zero** `Assignment` rows.
  - A user becomes connected to a specific Company/Branch **only when that tenant (Company-side staff) creates an `Assignment` row for them** (`Role = Member`, `CompanyId` + `BranchId` set) — the connection is tenant-initiated, never user-initiated. User's own words: "millet üye olsun üye olan kişiyi tenant paket tanımlarsa o tenant verilerini görsün" / "Tüm kullanıcılar üye olacak. Tenantlar üyeleri kendi müşterisi olarak seçerse o tenanta ait bilgiler üyelere gelecek."
  - **No domain model changes needed for this** — confirmed by reading the actual Backend Foundation code, not assumed: `Core/GymAppApi.Domain/Entities/User.cs` has no `CompanyId` at all; `Assignment.cs` already has nullable `CompanyId`/`BranchId` + `Role` (`AssignmentRole` enum already includes `Member`, alongside `SuperAdmin`/`GymAdmin`/`BranchManager`/`Trainer`). A brand-new user with zero Assignments IS the tenant-less state — this was apparently already anticipated when Backend Foundation's Task 3 (Domain: Identity & Tenancy Entities) was designed, nothing to add or change there.
  - **Trainer/other staff roles are explicitly out of scope for mobile registration** — "Antrenör kim olduğuna tenant kendi karar verir" (the tenant decides who's a Trainer). Mobile self-registration only ever produces a Member; any other `AssignmentRole` is assigned by the tenant through its own (not-yet-built) tooling, unrelated to this plan.
  - Until a user has at least one active `Assignment`, the mobile app needs a **new "no active membership yet" empty state** (not an error state) on the content screens — not yet designed, still open.
- **This plan's scope DOES include a minimal backend "assign" endpoint** (create an `Assignment` row for a user) so the tenant-connection state can be exercised end-to-end for real (via Swagger/Postman, no UI) — user explicitly chose this over leaving it for a separate plan. It does NOT include any admin-side UI/screen for staff to search/assign users — that's a separate future plan (different persona, likely a different surface entirely, e.g. a web admin panel).
  - **Still open/undecided:** whether this assign endpoint itself needs auth-gating (e.g. require a GymAdmin/SuperAdmin JWT) or stays unauthenticated for now like the existing Branch CRUD endpoints (precedent from Backend Foundation) — needs a decision before the spec is finalized. Leaning unauthenticated-for-now given there's no way to even obtain a GymAdmin token yet (nothing seeds one), but not yet confirmed with the user.
- **Real Package/Membership backend stays OUT of scope** — even after a user gets an Assignment (tenant-connected), what they see on Home/Classes/Progress/Membership screens is still the existing `Fake...Repository` mock content, unchanged. This plan only makes the AUTH/tenant-connection state real; the actual package/class/progress data backend is separate future work (consistent with Backend Foundation's own explicit out-of-scope list for Package/Membership/Classes).
- **Auth method: email-or-phone + password.** No SMS OTP anywhere (rejected the original mobile-foundation-design doc's phone+OTP vision as unnecessary cost/delay) — matches the already-approved login mockup exactly (single-step, no OTP screen).
- **Role scope for THIS login: Member-only.** No role/branch context-selection step after login (that concept from the original design doc is dropped for this plan) — see the tenant-less/staff-roles bullet above for why.
- **Token strategy: access + refresh JWT.** Short-lived access token (e.g. ~1h) + long-lived refresh token (hashed at rest in DB, rotated on use) — chosen over a single long-lived token for standard security/UX trade-off (stay logged in for weeks without repeated password entry, but a leaked access token has limited blast radius). Needs a refresh endpoint + a refresh-token table/entity in the eventual plan.
- Password hashing continues to reuse `Microsoft.AspNetCore.Identity.PasswordHasher<T>` (already noted as the intended approach in `User.cs`'s own doc comment — not a new decision, just confirmed still correct).

## Still open (not yet asked / not yet resolved) — resume brainstorming here

1. Assign-endpoint auth gating (see above).
2. "Şifremi unuttum" (forgot password) — real flow in this plan, or an intentional no-op placeholder (like `homeCheckInButton` already is elsewhere in this app) deferred to a future plan?
3. New Register/Sign-up screen's exact fields and copy (email vs phone as primary identifier — or both? full name required at signup?) — not yet designed, should reuse the login mockup's exact visual skeleton (same thin-line fields).
4. The new "no active membership yet" empty-state screen's content/copy — not yet designed.
5. Whether `AuthRepository`'s interface reshape (token return, typed error distinction between invalid-credentials vs network-error, matching the two error states already in the approved mockup) has any other shape implications not yet surfaced.

## Next action if resuming

1. Read this file in full first (supersedes the old "CONFIRMED next task" pointer in [[project-member-experience-status]], which only knew about the login-visual-design step, not this backend/tenant decision).
2. Continue the `superpowers:brainstorming` session from the "Still open" list above — do not re-ask anything already decided above.
3. Once all open items are resolved, present the full design per the brainstorming skill's flow, write the spec to `docs/superpowers/specs/`, get user approval, then hand off to `writing-plans`.
4. This feature spans both repos — the spec/plan will likely need tasks in both GymAppApi (auth endpoints, Assignment/refresh-token persistence, register/login/refresh/assign endpoints) and GymApp (real `AuthRepository`, Register screen, restyled 4 screens, new empty-membership state, secure token storage). Keep following [[feedback-memory-location]] — this file stays the mobile-side source of truth; only add a short pointer note (not a duplicate) to GymAppApi's own memory.
