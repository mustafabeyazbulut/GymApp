---
name: feedback-design-quality-bar
description: Every screen built in GymApp, even proof-of-concept ones, must match the visual polish/quality of the reference "MAT & MOVE" mockup — not a rough placeholder approximation.
metadata:
  type: feedback
---

The UI quality bar is non-negotiable: whatever screens get built (including the Mobile Foundation plan's Branch list proof-of-concept screen) must look and feel as polished as the reference mockup screenshot (ChatGPT-generated "MAT & MOVE" concept: Ana Sayfa/Dersler/Gelişimim/Üyeliğim) — not a rough/generic Material-default placeholder that only borrows the two accent colors.

**Why:** User said "devam et ama tasarım birebir aynı kalite de olacak mutlaka" (2026-09-14) — continue, but the design absolutely must be the same quality. This is a stronger bar than what [[project-mobile-foundation-status]]'s existing spec implies ("placeholder theme, single AppTheme file, easy to swap later") — the *colors* being placeholder (brand not final) is fine and already agreed, but the *craft level* (spacing rhythm, card elevation/shadow, corner radius, icon consistency, typography weight/hierarchy, tap-target sizing, bottom-nav treatment) is not allowed to be a rough draft, even on early/scaffolding screens.

**How to apply:** When writing or reviewing any Flutter screen implementation task in this repo:
- Treat every screen as production-grade UI, not a technical placeholder, regardless of whether it's a "proof of concept" for architecture purposes.
- Reuse the mockup's concrete visual patterns where a screen's content allows it: rounded cards with subtle depth, generous padding, bold lime-green primary CTA buttons with dark text for contrast, clear icon+label bottom nav, avatar/image treatment, small pill/badge tags (e.g. "Aktif", category tags).
- Don't ship a "we'll polish it later" version of a screen and call the task done — code-quality review for UI tasks should explicitly check visual polish against this bar, not just functional correctness.
- If a concrete visual question comes up that the mockup doesn't answer (e.g. exact font family, icon pack), make a reasonable high-quality choice consistent with the mockup's aesthetic rather than defaulting to Flutter's stock Material look.
