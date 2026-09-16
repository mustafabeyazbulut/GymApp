---
name: feedback-visual-language
description: The app's concrete visual design language (colors, form fields, layout rules) is locked in — always design/build new screens to this, don't propose or drift toward gradients/hero-patterns/decorative color again.
metadata:
  type: feedback
---

This is now the **standing visual language for every screen in GymApp**, not just the Auth feature it was designed for. User's own words when asking this to be saved: "tasarımı kaydet, bilsin her zaman bu şekilde olacağını" (save the design, it should know it'll always be this way) — after finalizing the Login/Register/Forgot-Password mockup through 3 rounds (see [[project-real-auth-design]] for the full back-and-forth). Apply this to any future screen without being asked again; only revisit if the user explicitly says so.

**Why this exists:** two earlier visual directions were both rejected as "çok kötü" — v1 had a gradient hero + a ŞUBE/ÜYE/PUAN stats row, v2 replaced that with a top hero/pattern section + bottom sheet. Both were flagged for the SAME underlying mistake: decorative/ambient use of color and layout flourish not tied to any real interaction. v3 fixed this by making every visual element earn its place functionally, and was approved as "çok daha iyi."

## The rules

- **Flat, single-plane dark background always.** No gradients, no radial glows, no diagonal-line/pattern textures, no "hero" sections with their own background treatment. One `AppColors.background` behind everything.
- **The accent green (`#8BC34A`) is used ONLY functionally** — a focused field's underline, a primary button's fill, a selected chip/tab/pill. It is never used as an ambient wash, a decorative badge color, or a "trust/stats" row (a ŞUBE/ÜYE/PUAN-style row was explicitly rejected for exactly this reason).
- **Form fields are thin 1px underlines, not filled/boxed inputs.** Label in small uppercase muted text above, value below, a hairline `AppColors.border` bottom border that turns `AppColors.primary` (1.5px) on focus and `AppColors.error` on validation error.
- **Errors are a single line of red text right under the affected field(s), never a boxed/colored banner.** Network/connectivity issues use the app's existing thin `SnackBar`-style bottom bar (see Classes/Membership screens), never a new elevated "toast card" component.
- **No decorative icon badges, no rotated-square logo treatments with drop shadows, no stock-photo or illustration content anywhere.** The brand mark is a plain thin-ring icon + small tracked-caps wordmark, nothing more elaborate.
- **A screen's brand mark/logo must sit at a visually FIXED position across every state of that screen**, regardless of how much content a given state adds (an extra error line, a success banner, etc.). Don't lay out a screen's header by vertically centering the whole content block if different states of that same screen can have different content heights — that was a real, twice-reported bug ("logo kaymış") caused by `justify-content:center` centering a taller error-state block differently than a shorter empty-state block. Prefer a fixed top offset (or absolute-positioning the mark itself) so cross-state comparison always lines up.
- Applies to already-shipped screens too, not just new ones — the existing Home/Classes/Progress/Membership screens are being restyled to this same language as part of the current Real Auth plan (see [[project-real-auth-design]]), replacing their filled/rounded `Card` look with this thin-line/flat-surface treatment, without changing any of their logic or data.
- **"Thin-line/flat-surface" above is about form INPUT fields only — content cards (the mockup's `.kard`) are a different, separately-defined element and DO have a background fill.** Confirmed by reading the actual mockup CSS directly: `.kard { background:var(--surface1); border:1px solid var(--line); border-radius:14px; }` — i.e. `AppColors.surface` fill + hairline `AppColors.border` + `AppSpacing.radiusLg`, matching the app's own `cardTheme` in `app_theme.dart`. A real bug shipped from misreading this rule as "no fill anywhere": the Membership screen's summary/payment-history/settings cards were built with `border` only and no `color:`, so they had no visible fill and blended into the background — user flagged it twice ("şık değil") before the fill was added back. Any new `Container`-based card must set `color: AppColors.surface` explicitly; don't infer "flat" to mean "no fill" for cards. Dialogs get the same fill+border treatment via the theme's `dialogTheme` (also added after a similar "dark corners" complaint — Material3's default elevation tint on an unset `colorScheme.surface` was the actual cause, not the border radius).

## Reference

Approved mockup (all states, kept up to date as new flows get designed): https://claude.ai/artifact/MZ3o6pBqNd2rYawmG97hNS
