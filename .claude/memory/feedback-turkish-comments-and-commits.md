---
name: feedback-turkish-comments-and-commits
description: User wants ALL code comments, ALL git commit messages, AND all chat replies to the user written in Turkish only, in both GymApp and GymAppApi. Read this before writing any comment, commit message, or chat response.
metadata:
  type: feedback
---

# Write code comments, commit messages, AND chat replies in Turkish only (2026-09-19, reinforced same day)

User's original instruction, mid-session (said while working in GymAppApi, applies here too): "kod açıklamalarını türkçeye çevir her zaman türkçe yazsın commit satırları" (translate code comments to Turkish, commit lines should always be written in Turkish).

**Reinforced later the same day, sharply, after Claude kept replying in English in chat:** "bir daha uyarmayacağım seni bana sadece türkçe açıklama yaz. kod stırına da sadece türkçe açıklama yaz" (I won't warn you again - write explanations to me only in Turkish. Also write only Turkish comments in code lines). Every chat reply to this user, in every repo/session, goes in Turkish only from here on - no exceptions.

This repo (GymApp) already had its own comment-translation pass (commit `85b9483`, "Translate code comments to Turkish") — that convention is now an explicit, standing rule, not a one-off. Commit messages also go in Turkish from now on (still no Claude/AI attribution line, per CLAUDE.md — this only changes the message's language).

Full rationale/detail lives in GymAppApi's own copy of this memory file (`feedback-turkish-comments-and-commits.md`) — this is a pointer, per the established cross-repo convention (see `feedback-never-remove-registration.md`).
