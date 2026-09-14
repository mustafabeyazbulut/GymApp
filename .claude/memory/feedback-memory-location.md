---
name: feedback-memory-location
description: Mobile-related memory must always be saved in this repo (GymApp), never in the backend (GymAppApi) repo's memory.
metadata:
  type: feedback
---

All Flutter/mobile-related project memory (status, decisions, environment setup, design system) must be written to **this repo's** `.claude/memory/`, not to `GymAppApi`'s memory folder — even when the work touches both repos (e.g. mobile consuming a backend endpoint).

**Why:** User explicitly said "unutma mobille ilgili herşeyi mobil tarafında memori de sakla" (2026-09-14) while kicking off Flutter work — the two repos are separate git projects intended to be worked on independently/from different sessions, so mobile context must be self-contained here, matching how [[project-mobile-foundation-status]] was already written (absolute Windows paths back to the backend repo only as cross-references, not as the memory's home).

**How to apply:** When a task spans both repos (e.g. "mobile screen X consumes backend endpoint Y"), the mobile-facing facts (screen scope, UI/state decisions, what endpoint shape is expected) go in GymApp's memory; only genuinely backend-side facts (API behavior, DB state, backend task progress) belong in GymAppApi's memory. Don't duplicate the same fact in both — link with a note referencing the other repo's file/commit instead.
