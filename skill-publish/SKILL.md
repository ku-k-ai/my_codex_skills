---
name: skill-publish
description: Install, import, create, or update a personal Codex Skill and immediately mirror publishable changes to ku-k-ai/my_codex_skills. Use whenever the user asks to add, install, reflect, sync, or update a personal Skill. Do not use for OpenAI-managed or plugin-cache Skills.
---

# Skill Publish

Complete the requested Skill work and its Git mirror as one event-driven workflow. Use the system `skill-installer` for GitHub installation and `skill-creator` when authoring or substantially adapting a Skill.

Before publication:

1. Work only under `~/.codex/skills`; never mirror `.system`, plugin caches, or `pptx`.
2. For third-party content, inspect the upstream license and NOTICE, preserve the required text in the installed Skill, and stop publication if redistribution is unclear or prohibited.
3. Make only the compatibility edits needed for Codex. Preserve attribution and record that an adaptation was made.
4. Exclude secrets, credentials, transcripts, generated reports, caches, and unrelated artifacts.
5. Add `.codex-skill-sync.json` with `upstream`, `license`, `redistribution_reviewed: true`, and `license_file` for third-party Skills. Use `upstream: local` only for content owned by the user.
6. After reviewing the finished contents, approve that exact snapshot with `run_sync_codex_skills.ps1 -Approve <skill-name>`. Reapprove if any file changes afterward.

The `PostToolUse` Hook detects the finished file change and mirrors it to `C:\Users\kuyan\Desktop\code\codex_skills`. To verify or retry immediately after approval, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\hooks\run_sync_codex_skills.ps1" -SyncNow
```

Confirm the mirror repository is clean and at `origin/main` after the push. If the Hook defers a Skill, read `~/.codex/hooks/state/skill-sync/sync.log`, resolve only the reported publication gate, and retry. Never bypass a license, secret, dirty-worktree, deletion, or non-fast-forward gate.
