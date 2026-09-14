---
name: project-member-experience-status
description: GymApp Flutter mobile — Member Experience plan (login + 4-tab mock-data app, replacing the Branch proof-of-concept) execution status. Read this first if resuming, more current than project-mobile-foundation-status.md for anything after 2026-09-14's pivot.
metadata:
  type: project
---

# GymApp Mobile — Member Experience Status

**Plan:** `docs/superpowers/plans/2026-09-14-member-experience.md` (17 tasks) — read it in full before resuming. **Spec:** `docs/superpowers/specs/2026-09-14-member-experience-design.md`.

**Why this plan exists (context for a fresh session):** The prior "Mobile Foundation" plan (see [[project-mobile-foundation-status]]) built a technically-proven but product-thin app: architecture + theme + one backend-gated screen (Branch list/create). After seeing it running, the user was unhappy — they expected the real "MAT & MOVE" mockup app, not a Branch admin screen. User said explicitly: "ben senden böyle bir şey istemedim, uygulamayı inşa etmeni istiyorum" (I didn't ask for this, I want you to build the app). Through an iterative visual-brainstorming session (browser-based mockup tool, v1→v2→v3 with real user feedback each round — too much icon/color/texture clutter, neon green too harsh, button text too bold, random stock photos looked bad/irrelevant), the team landed on an approved v3 visual design, then the user explicitly said: **delete the Branch feature entirely** ("tasarım o olamaz, sil bence") and **build all 5 mockup screens now with mock/local data**, not gated on real backends.

**Key design decisions locked in (do not re-litigate without the user):**
- `AppColors.primary` changed `#C6FF3D` → `#8BC34A` (neon lime → calmer mid-tone green) — direct user feedback ("çok cırtlak", "göz yoruyor"), not an accident.
- Branch feature fully deleted (Task 1) — not archived, not reused. Where "şube/admin yönetimi" eventually lands is an explicitly open, deferred question per the user ("önce ana tasarımı çıkaralım daha sonra onu nereye koyacağımıza karar veririz").
- 5 screens, mock/local data via `Fake...Repository` per feature (`auth`, `home`, `classes`, `progress`, `membership`), same `domain/data/presentation` pattern the Branch feature proved — just without a DTO/JSON layer, since there's no network involved.
- No real auth, no persistence — app always starts at `/login`, any non-empty credentials succeed.
- `StatefulShellRoute.indexedStack` (go_router) for the 4-tab shell; router rebuilds via `ref.watch(authStateProvider)` inside `@riverpod GoRouter appRouter(...)` rather than `refreshListenable` machinery.

**Environment/tooling notes carried over from the Mobile Foundation plan (still true):** PowerShell tool required for all `flutter`/`dart` commands (Bash/Git Bash can't invoke the CLI correctly here); `AsyncValue.copyWithPrevious` is `@internal`, never use it — use a private cache field instead if "preserve last good value across a failed reload" is needed; `NavigationBar` requires ≥2 destinations (not a risk in this plan — 4 real tabs); `build_runner`'s `--delete-conflicting-outputs` flag is deprecated/ignored but harmless, keep passing it; no real browser screenshot tool is available in this environment (no `chromium-cli`, `claude-in-chrome` not connected) — Task 17's manual smoke test relies on log/analyze-based verification, not visual screenshots, and that's an accepted limitation, not a shortcut to flag.

## Task checklist

- [x] Task 1 — Remove the Branch Feature — Last commit: `e180a49` "Remove Branch feature and replace router with temporary placeholder" (spec ✅, code-quality ✅ "Ready to merge: Yes"). Clean, total deletion (14 files) — `lib/features/` no longer exists at all. `lib/core/widgets/app_shell.dart` is now a temporary orphan (nothing imports it) — this is correct/expected, Task 15 rewrites it, not a bug to fix early. `app_router.dart` replaced with the minimal one-route placeholder from the plan, to be replaced for real in Task 16.
- [x] Task 2 — Update `AppColors.primary` to a Calmer Green — Last commit: `65269ae` "Tone down primary accent from neon lime to a calmer green" (spec ✅, code-quality ✅ "Ready to merge: Yes"). Exactly 2 lines changed (`primary`, `successSurface`), nothing else. Contrast vs `onPrimary` recomputed: ~9.25:1, well clear of WCAG AAA even.
- [x] Task 3 — Rewrite Localization (remove Branch keys, add Member Experience keys) — Last commits: `e205a09` "Replace Branch localization keys with Member Experience keys" + `d038d35` "Fix Turkish localization copy inconsistencies" (spec ✅ incl. all placeholder arities cross-checked against Tasks 6/8/14's actual call sites — clean, no mismatch; code-quality ✅ after fix — 4 Turkish copy issues found: `homeCheckInButton` collided verbatim with `loginSubmitButton` ("Giriş Yap" reused for two different actions), `progressTechnique` was plural breaking its sibling gauge labels' singular pattern, `membershipFreezeButton`/`classesReservedButton` had register/vocabulary mismatches vs. their sibling strings — all fixed, plus one free bonus grammar fix (`homeWeeklyAttendanceLabel` missing the "-ki" relativizer)). **If any later task adds a new ARB key, give the Turkish copy the same real-read scrutiny** — this reviewer caught genuine native-speaker-level issues (collision, singular/plural mismatch, register inconsistency) that a structural/arity check alone would have missed entirely.
- [ ] Task 4 — `CircularStatGauge` Widget
- [ ] Task 5 — Auth Feature (fake repository + auth state)
- [ ] Task 6 — Login Screen
- [ ] Task 7 — Home Feature (domain + fake repository + provider)
- [ ] Task 8 — Home Screen (Ana Sayfa)
- [ ] Task 9 — Classes Feature (domain + fake repository w/ reservation mutation + provider)
- [ ] Task 10 — Classes Screen (Dersler)
- [ ] Task 11 — Progress Feature (domain + fake repository + family provider)
- [ ] Task 12 — Progress Screen (Gelişimim)
- [ ] Task 13 — Membership Feature (domain + fake repository w/ freeze mutation + provider)
- [ ] Task 14 — Membership Screen (Üyeliğim)
- [ ] Task 15 — Real `AppShell` (4-tab floating nav bar)
- [ ] Task 16 — Real Router (`/login` + 4-branch `StatefulShellRoute`)
- [ ] Task 17 — Manual End-to-End Smoke Test

## Next action if resuming

1. Read this file, then `docs/superpowers/plans/2026-09-14-member-experience.md` in full.
2. Run `git log --oneline` in `C:\Users\MBEYAZBULUT\Documents\GitHub\GymApp` to confirm which tasks actually landed — trust git over this file if they disagree.
3. Continue subagent-driven-development (implementer → spec reviewer → code-quality reviewer, fix-and-re-review loop on any issues) from the first unchecked task above.
4. Update this checklist + commit SHA after every task's code-quality review passes.
5. UI tasks (6, 8, 10, 12, 14, 15) must also be checked against `.claude/memory/feedback-design-quality-bar.md` in code-quality review, not just functional correctness — the user has given very specific, demanding visual feedback multiple times this project (nav bar quality, button font weight, accent color harshness) and expects that same bar met without being asked again.
