# Visual generation and independent QA workers

> Adapted for Codex, 2026-09-08: worker boundaries and isolated QA are disclosed only for visual jobs. Source: the original hatch-pet worker contract.

Use this reference when dispatching a base, standard-row, cardinal-strip, look-row, blind-direction, or final visual-QA worker. Read [command-conventions.md](command-conventions.md) for runtime and shell handling, [codex-pet-contract.md](codex-pet-contract.md) for the v2 package contract, and [animation-rows.md](animation-rows.md) for the fixed row contract. For the final worker, also read [qa-rubric.md](qa-rubric.md). The parent owns the run directory, manifest, deterministic scripts, package, repairs, and cleanup.

## Lightweight Visual Workers

Use one lightweight worker per visual job. A worker may generate or inspect only its assigned artifact and returns a compact result. Workers must use `$imagegen` for image generation after loading `${CODEX_HOME:-$HOME/.codex}/skills/.system/imagegen/SKILL.md` (on PowerShell, resolve `$env:CODEX_HOME` or `$HOME\.codex`); they must not call an image API or image CLI directly, draw or tile sprites locally, edit manifests, copy files into `decoded/`, run deterministic image scripts, package, clean up, or open unrelated files.

The parent sends every input image listed in `imagegen-jobs.json` with its role label. The base may be prompt-only when no reference exists. Every row-strip job must have grounded input images, including the canonical base and its layout guide where the manifest lists them. A layout guide is an invisible construction reference: its boxes, labels, colors, borders, and marks must not appear in the output.

Workers return no Markdown previews, base64, or extra attachments. A generation worker returns exactly its selected source path and one concise QA note. The parent copies that exact selected source to the decoded output path, runs incremental checks, and only then marks the manifest job complete.

The parent may keep up to three generation workers active when at least three independent jobs are ready, backfilling as capacity permits. Use fewer when dependencies expose fewer jobs. Run final visual QA as one worker after deterministic processing and close a worker after consuming its result. Prefer a smaller capable model such as `gpt-5.4-mini` with medium reasoning for discovery or visual workers when an override is available; use the parent/default model for orchestration or when no suitable smaller worker exists.

## Subagent Delegation

Parent responsibilities:

- inspect `imagegen-jobs.json` and dispatch only jobs whose dependencies are complete
- attach the prompt file and all listed grounding images to each worker
- copy the selected output to the manifest's decoded path and make `references/canonical-base.png` from the selected base
- run incremental extraction/inspection and the approved `running-left` mirror derivation
- write and approve the pet-specific look mechanics plan and four cardinal anchors
- run deterministic registration, assembly, despill, validation, QA-sheet creation, consensus, packaging, repair, and cleanup

Base worker:

- handle exactly `base`, read `prompts/base-pet.md`, and use all listed reference images
- return only the selected source and one-sentence QA note

Row worker:

- handle exactly one standard or look row, read its prompt and retry prompt, and use all listed inputs
- perform a quick visual check for frame count, identity, chroma background, spacing, clipping, components, and detached effects
- for a `look-row-strip`, generate all eight pose groups together as one coherent family from the approved cardinal strip; do not independently restyle cells
- return only the selected source and one-sentence QA note

Blind direction workers:

- be fresh isolated workers that inspect only `qa/direction-blind-pairs.png`
- classify every A/B pair on the axis named in the sheet as `screen-left`, `screen-right`, `up`, `down`, or `ambiguous`
- never see the labeled direction sheet, prompts, degree order, answer key, prior verdicts, atlas, or another blind worker's output
- return one JSON object containing every pair and short landmark evidence, with no other text

Final visual-QA worker:

- inspect the final standard and extended contact sheets, focused direction sheet, preview GIFs, semantics, continuity, blind validation, v2 validation, and review artifacts
- verify all 11 rows share identity, style, palette, silhouette, face, proportions, materials, and props and satisfy the Codex app contract
- return a compact result with repair notes; do not edit, queue repairs, package, clean up, or inspect unrelated files

## Base worker prompt

```text
Generate the hatch-pet base image.

Run dir: <absolute run dir>
Job id: base
Prompt file: <absolute base prompt file>
Input images:
- <absolute path> — <role>

Use $imagegen only. Read the base prompt and attach every listed input image. If the prompt contains brand inspiration, use it only as broad mascot-safe guidance; do not copy logos, readable marks, UI screenshots, slogans, or text. Before returning, visually check that the result is one centered full-body pet on a flat chroma background, with no text, scenery, shadows, or detached effects.

Do not edit manifests, copy into decoded, mark jobs complete, generate rows, run image-processing scripts, repair, package, or open unrelated files. Do not include Markdown image previews, base64, or extra attachments in the final response.

Return exactly:
selected_source=/absolute/path/to/selected-output.png
qa_note=<one sentence>
```

## Four-cardinal worker prompt

```text
Generate one hatch-pet four-cardinal anchor strip.

Run dir: <absolute run dir>
Job id: look-cardinals
Prompt file: <absolute prompt file>
Input images:
- <absolute path> — <role>

Use $imagegen only. Read the cardinal-strip prompt and attach every listed input image. Read qa/look-mechanics.md. Screen-left and screen-right are viewer/image coordinates, never character-relative coordinates. Before returning, verify all four slots in order without relying on their labels: for a face, cite the nose-tip and pupil positions relative to the head center; for other pets, cite the natural aiming feature. Any ambiguous cardinal fails the strip.

Do not edit manifests, copy files, generate rows, assemble, package, or inspect unrelated files. Do not include image previews or attachments in the final response.

Return exactly:
selected_source=/absolute/path/to/selected-output.png
qa_note=<one sentence with concrete landmark evidence for all four cardinals>
```

## Row worker prompt

```text
Generate one hatch-pet row.

Run dir: <absolute run dir>
Row id: <row-id>
Prompt file: <absolute prompt file>
Retry prompt file: <absolute retry prompt file>
Input images:
- <absolute path> — <role>
- <absolute path> — <role>

Use $imagegen only. Read the row prompt and attach every listed input image. For a look-row-strip job, also read and obey qa/look-mechanics.md; use the approved cardinal strip for direction meaning and draw all eight cells together as one coherent family with even intermediate steps. Never paste, reuse, or independently restyle individual cells. If imagegen returns Bad Request, retry once with the retry prompt and the same input images.

Before returning, visually check exact frame count, canonical-base identity, flat chroma background, complete separated unclipped poses, and no detached effects or guide marks. For a look-row-strip, verify eight separated pose groups in the required left-to-right order, no neighboring overlap, no foreground cropped at an outer canvas edge, and a consistent scale and baseline. Exact crop, shared-scale normalization, recentering, and final-cell edge validation occur deterministically after generation. Enforce the row prompt's state rules: no detached effects, no wave marks for waving, no speed lines or dust for directional running rows, no literal foot-running for the non-directional running row, and only attached opaque sprite-like tears, smoke, or stars when the state permits them.

Do not edit manifests, copy into decoded, mark jobs complete, mirror rows, run image-processing scripts, repair, package, or open unrelated files. Do not include Markdown image previews, base64, or extra attachments in the final response.

Return exactly:
selected_source=/absolute/path/to/selected-output.png
qa_note=<one sentence>
```

## Isolated blind direction prompt

Spawn each of the three blind workers with no prior conversation context when the worker system supports isolation. Give each worker only the randomized sheet. The answer key remains parent-only until consensus is formed.

```text
Classify one required gaze axis in an unlabeled hatch-pet A/B challenge.

Blind sheet: <absolute run dir>/qa/direction-blind-pairs.png

Inspect only this sheet. Do not open the atlas, labeled direction sheet, prompts, prior QA, degree order, answer key, or any other file.

Each row contains two normal-size pet cells labeled A and B and identifies the axis to judge. For a horizontal row, classify each cell as exactly screen-left, screen-right, or ambiguous. For a vertical row, classify each cell as exactly up, down, or ambiguous.

Judge only what is readable at the displayed pet size. Use visible landmarks such as pupils, nose tip relative to head center, face surface, head turn, eyelids, or the pet's natural aiming feature. If the requested axis is not definite without enlarging or guessing, classify it as ambiguous; do not invent confidence.

Do not infer from A/B order. If A and B point the same way, report the same classification; do not force one left and one right.

Return exactly one JSON object and nothing else:
{"pairs":[{"pair":"horizontal-1|vertical-1","A":"screen-left|screen-right|up|down|ambiguous","B":"screen-left|screen-right|up|down|ambiguous","reason":"short landmark evidence"}]}

Include every pair shown in the sheet.
```

Combine exactly three isolated verdict files with `scripts/combine_direction_blind_verdicts.py` and apply the hidden answer key only to the consensus with `scripts/validate_direction_blind_verdicts.py`. Cardinal mismatches or ambiguity fail the blind gate. Intermediate disagreement or ambiguity remains review evidence and may be accepted only through the labeled normal-size loop review and the minor-issue resolution described in [assembly-qa.md](assembly-qa.md).

## Final visual-QA prompt

```text
Visually QA one finalized hatch-pet contact sheet.

Run dir: <absolute run dir>
Contact sheet: <absolute run dir>/qa/contact-sheet.png
V2 contact sheet: <absolute run dir>/qa/contact-sheet-extended.png
Focused direction QA sheet: <absolute run dir>/qa/look-directions.png
Direction semantics JSON: <absolute run dir>/qa/direction-semantics.json
Blind direction validation JSON: <absolute run dir>/qa/direction-blind-validation.json
Look continuity JSON: <absolute run dir>/qa/look-continuity.json
Preview dir: <absolute run dir>/qa/previews
Review JSON: <absolute run dir>/qa/review.json
V2 validation JSON: <absolute run dir>/final/validation-extended.json

Inspect the contact sheet and preview GIFs visually. Confirm the same pet identity, style, palette, silhouette, face, proportions, and props across rows 0 idle, 1 running-right, 2 running-left, 3 waving, 4 jumping, 5 failed, 6 waiting, 7 running, and 8 review.

Require qa/direction-blind-validation.json to have ok: true, or require an explicit accepted minor override in qa/blind-review-resolution.json. Cardinal mismatches or ambiguity are major and block packaging. For intermediate warnings or a worker-level fail, inspect the labeled normal-size pose and ordered loop; accept only a minor issue with no wrong-quadrant pose or reversal.

Inspect the 16 direction cells as a labeled ordered loop and review qa/look-continuity.json. Produce pass, warning, or fail for every expected direction: 000 up, 022.5 up-right, 045 up-right, 067.5 up-right, 090 right, 112.5 down-right, 135 down-right, 157.5 down-right, 180 down, 202.5 down-left, 225 down-left, 247.5 down-left, 270 left, 292.5 up-left, 315 up-left, and 337.5 up-left. Record separate horizontal and vertical landmark evidence for every diagonal. Fail wrong or ambiguous cardinals, labeled wrong-quadrant poses, and visible reversals. Record blind uncertainty on intermediate poses as warnings when labeled review and loop context confirm the intended direction.

Fail rows with identity drift, missing or blank frames, copied guide marks, white or nontransparent backgrounds, cropped bodies, slot overlap, detached effects, shadows, glows, smears, dust, state-incompatible motion, unintended size popping, wrong facing, reversed or non-alternating gait, or idle loops that are effectively static. Judge chroma on the cleaned extended contact sheet after the final despill report and v2 validation; those deterministic results are authoritative for chroma.

Do not edit files, queue repairs, package, clean up, or inspect unrelated files.

Return exactly:
visual_qa=pass|fail
qa_note=<one sentence summary>
direction_semantics=<semicolon-separated labels with pass/warning/fail and short visual reason>
review_warnings=<semicolon-separated accepted warnings, or none>
repair_rows=<comma-separated row ids, or none>
repair_notes=<short row-specific notes, or none>
```

The final visual-QA worker is independent evidence. The parent cannot self-approve a repaired look direction; use this worker for the required independent gate. Explicit user inspection can add evidence but does not replace the independent final visual-QA result. Every expected direction must still be recorded in `qa/direction-semantics.json`, and every worker-level override must be recorded in `qa/blind-review-resolution.json` with evidence.
