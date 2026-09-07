---
name: hatch-pet
description: Create, repair, validate, visually QA, and package Codex-compatible v2 animated pets when the result must be an 8x11 atlas with 9 standard animation rows and 16 clockwise look directions.
---

# Hatch Pet

> Adapted for Codex, 2026-09-08: route-based disclosure and runtime portability. Distributed under Apache-2.0; see [LICENSE.txt](LICENSE.txt). Source: the original hatch-pet workflow and its existing references.

## Purpose

Use this skill for a new Codex pet, an upgrade of existing pet art or an atlas, a repair of a failed run, or a brand-informed mascot. The finished package is a v2 pet, not merely a collection of generated images.

The shared contract is fixed:

- 8 columns × 11 rows, `192x208` cells, final `1536x2288` PNG or WebP.
- Rows `0-8` are the nine standard states; rows `9-10` are the fixed clockwise 16-direction look loop.
- `pet.json` includes `spriteVersionNumber: 2` and points to the packaged spritesheet.
- The `1536x1872` 8×9 atlas is an intermediate review artifact and is never packaged as a new pet.
- Every used cell is populated, every unused standard-row cell is transparent, and transparency/chroma QA is closed by the deterministic final pass.
- A package is complete only after independent visual QA, direction semantics, continuity review, v2 validation, and the run summary are present.

Read [codex-pet-contract.md](references/codex-pet-contract.md) for the package shape and [animation-rows.md](references/animation-rows.md) for row counts and timings. Read [qa-rubric.md](references/qa-rubric.md) when accepting or repairing a result. These are the single sources of truth for the fixed contract. The v2 look, independent QA, and package anchors live in [assembly-qa.md#required-v2-look-direction-stage](references/assembly-qa.md#required-v2-look-direction-stage), [assembly-qa.md#direction-acceptance-policy](references/assembly-qa.md#direction-acceptance-policy), and [assembly-qa.md#acceptance-criteria](references/assembly-qa.md#acceptance-criteria).

## Choose a route

Read only the route references needed for the current job. Each route ends at the assembly/QA gate; do not claim completion before that gate passes.

| Situation | Read in this order |
|---|---|
| New pet from text, art, or a generated concept | [new-pet.md](references/new-pet.md), then [visual-workers.md](references/visual-workers.md) for delegated image work, then [assembly-qa.md](references/assembly-qa.md) |
| Existing atlas, built-in pet, or failed run | [repair-upgrade.md](references/repair-upgrade.md), then [visual-workers.md](references/visual-workers.md) for any regenerated row, then [assembly-qa.md](references/assembly-qa.md) |
| Bare brand, product, company, or prospect name | [brand-discovery.md](references/brand-discovery.md), then choose the new or repair route; skip discovery when concrete avatar instructions or reference art already provide the grounding |
| Acting as a base, row, cardinal, blind-direction, or final-QA worker | [visual-workers.md](references/visual-workers.md); follow the one-job boundary and return format in that file |
| Assembling, validating, reviewing, packaging, or repairing QA failures | [assembly-qa.md](references/assembly-qa.md); read [repair-upgrade.md](references/repair-upgrade.md) when the failure requires a new source row |

The route references link back to the contract, row table, and QA rubric at the point where those invariants are needed. Do not load every route reference for a single job.

## Shared execution rules

### Image generation

Use `$imagegen` for every normal visual job: the base image, standard row strips, the four-cardinal strip, and both coherent look-row strips. Before invoking it, load the installed image-generation skill at `${CODEX_HOME:-$HOME/.codex}/skills/.system/imagegen/SKILL.md` (on PowerShell, resolve `$env:CODEX_HOME` or `$HOME\.codex`) and follow its current reference and fallback rules. Do not call an image API, image CLI, local raster generator, or one-off generation script directly. If that skill requires confirmation for a fallback, ask before continuing.

Use a concise, state-specific, sprite-production prompt as the authoritative visual specification and attach every grounding image listed in `imagegen-jobs.json`. Keep longer policy and QA rules in this skill and its deterministic checks; do not wrap a pet prompt in the generic `$imagegen` shared prompt schema. The base may be prompt-only when no image exists; every row job needs its listed references, including the canonical base and layout guide where specified. Deterministic scripts may prepare guides, extract frames, mirror an approved `running-left`, assemble, validate, measure continuity, and make QA media; they never invent missing visual content or populate row outputs.

### Runtime, paths, and shell

Before any bundled script, call `load_workspace_dependencies` and use the exact returned Python executable. If that tool is unavailable, read [command-conventions.md](references/command-conventions.md), verify a compatible existing Python and Pillow installation, and use it when the probe passes. An absent bundled runtime alone is not a stop condition; a failed compatibility probe is.

Every `scripts/...` path in the route references is relative to the hatch-pet skill root, the directory containing this `SKILL.md`. Resolve that directory to an absolute `SKILL_DIR` before running a command. Confirm the execution shell first. The fenced `bash` blocks are POSIX examples; on PowerShell use the argument-array forms and JSON/file-operation translations in [command-conventions.md](references/command-conventions.md). Never paste POSIX variable, `jq`, `cp`, `rm`, or `mkdir` syntax into PowerShell unchanged.

### Provenance, storage, and rights

Copy a worker's selected source to the manifest's decoded path, run the required incremental checks, and only then mark that job complete. Keep one lightweight worker per visual job, have workers return only their selected path and QA note, and keep generated image payloads out of the parent response. Inspect the final contact sheets rather than opening every generated PNG in the parent run. Remove a selected original from the image-generation output directory only after its decoded copy exists and only when cleanup is requested by the active route.

For storage-sensitive full runs, offer the `$imagegen` CLI fallback when it is available; that route requires local API credentials and explicit user confirmation. It remains an `$imagegen`-owned fallback and does not authorize a direct image API or CLI call. When removing a selected built-in output, remove its now-empty generation directory only after confirming the exact path.

User-provided reference art must be authorized for this use; retain source and license/attribution notes in the run record when they are available. Brand research supplies broad mascot cues and evidence, not permission to reproduce a logo or other protected mark. Do not copy logos, readable marks, slogans, UI screenshots, or text into a pet. Preserve this skill's [LICENSE.txt](LICENSE.txt) when distributing the skill.

### Visible progress and convergence

Keep a visible four-step checklist for every run: `Getting <Pet> ready`, `Imagining <Pet>'s main look`, `Picturing <Pet>'s poses`, and `Hatching <Pet>`. Mark a step complete only when its file, image, or decision exists; repair runs start at the first relevant step. The route references define the work behind each step.

Classify a failure before acting: visual semantics, identity, source-edge geometry, component connectivity, extraction, chroma, continuity, or final visual QA. Fix deterministic failures deterministically, regenerate only when the source is wrong, preserve properties that passed, and compare the replacement with the previous result. When the same root failure recurs twice, change the strategy or visual construction instead of repeating a prompt variation. Time targets help prioritize work; they never waive a contract or QA gate.

## Completion gate

The parent owns manifest updates, deterministic processing, packaging, repair decisions, and cleanup. A run is complete only when [assembly-qa.md](references/assembly-qa.md) reports the v2 atlas, one successful final despill, `validate_atlas.py --require-v2`, per-direction semantics, continuity review, independent blind direction QA, independent final visual QA, `qa/review.json` without errors, and `qa/run-summary.json`. The final staged package contains `pet.json` and `spritesheet.webp` together under the required pets directory.

If a route cannot produce the required evidence, stop with the missing artifact and the smallest next action; do not silently downgrade to v1 or package the 8×9 intermediate.
