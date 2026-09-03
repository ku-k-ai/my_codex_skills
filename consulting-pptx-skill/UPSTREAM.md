# Upstream provenance

- Upstream: https://github.com/gozen3ji/consulting-pptx-skill
- Imported commit: `ccd4a588d6fc3c21a291579cfd5ca6e759a71f20`
- Upstream license: MIT; preserved in `LICENSE.upstream`
- Imported on: 2026-09-03

## Local Codex adaptations

- Rewrote the `SKILL.md` frontmatter description for Codex activation and overlap control.
- Added Codex-safe path, workspace-output, Windows, dependency, and QA guidance.
- Added `agents/openai.yaml` and `.codex-skill-sync.json`.
- Added a Codex note to the upstream README.
- Kept the renderer, templates, rules, schema, and checks intact except for Windows-safe filesystem paths, file URLs, and module resolution.
- Shortened the first bundled sample title because the upstream example failed its own 40-character title check.
