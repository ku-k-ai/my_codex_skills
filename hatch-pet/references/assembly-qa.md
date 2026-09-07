# V2 assembly and QA workflow

> Adapted for Codex, 2026-09-08: assembly gates, independent QA, and portable command routing. Source: the original hatch-pet v2 workflow. The skill and these references are Apache-2.0; retain [LICENSE.txt](../LICENSE.txt) when distributing them.

Use this reference after standard rows are validated, or whenever assembling, reviewing, repairing, or packaging a v2 pet. Before acting, read [codex-pet-contract.md](codex-pet-contract.md), [animation-rows.md](animation-rows.md), [qa-rubric.md](qa-rubric.md), and [command-conventions.md](command-conventions.md). Every `scripts/...` path below is relative to the directory containing the hatch-pet `SKILL.md`; resolve it as an absolute `$SKILL_DIR`. Confirm the shell before using a `bash` block and use the PowerShell argument-array forms when running on Windows.

## Required V2 Look-Direction Stage

The 8×9 standard atlas is intermediate-only. Every new pet must complete this sequence:

1. Write `qa/look-mechanics.md` for the specific character.
2. Generate one grounded four-cardinal strip, extract and approve `000`, `090`, `180`, and `270` in viewer/screen coordinates.
3. Generate one coherent eight-pose row 9 from those anchors, deterministically register it, and pass edge, semantic, and continuity checks.
4. Generate one coherent eight-pose row 10 using the approved anchors and completed row 9, then run the same checks.
5. Assemble the 8×11 atlas, run the single final despill, validate v2 geometry, create all QA media, run blind and labeled direction review, and obtain independent final visual QA.
6. Package `pet.json` and `spritesheet.webp` together and write `qa/run-summary.json` only after every required artifact exists.

Row 10 is not ready until row 9 has passed deterministic registration, post-registration edge diagnostics, labeled semantics, and continuity review. Reviewed warnings may remain; hard semantic or continuity failures require complete row regeneration.

## Look mechanics decision

Before prompting either look row, ask what natural motion this character uses when looking around. Record what stays anchored, what leads the gaze, what follows, and what bends, shifts, turns, squashes, stretches, or deforms. Name the natural pose family for each cardinal, which body side becomes visible, which features become occluded, and how each held, worn, or attached prop follows or lags.

Choose mechanics from the construction: flexible wire bends from an anchored base; soft bodies deform around a stable lower body; a separate head turns; ears, fur, and antennae follow through; physical eyeballs rotate as whole globes; flat screen or sticker eyes keep their surface fixed while drawn features change; rigid or screen-like characters may hinge, yaw, pitch, vibrate, or move attached features without rotating the whole sprite. For humanoids, eyes, eyelids, and eyebrows usually lead, with restrained head/neck and upper-body follow-through. Preserve facial proportions and move anatomical parts with rigid or near-rigid motion during programmatic repair.

Define a motion budget. Each 22.5-degree step should move the participating parts by roughly the same visual amount; a larger bend, scale change, prop shift, or silhouette change needs an explicit mechanics reason. Row 9 follows `000 -> 090 -> 180`. Row 10 follows `180 -> 270 -> 000`; `337.5` must be one step before the approved `000`.

Generate a coherent 16-pose family rather than unrelated variants. Keep a stable feet, base, torso, lower-body, or other grounded anchor. Adjacent direction cells, including `157.5 -> 180`, `337.5 -> 000`, and the row boundary, must progress without jumps, side flips, teleporting parts, or registration changes. Every look cell must visibly differ from the neutral/rest frame at final pet size.

Do not use whole-sprite rotation, whole-cell rotation, skewing, or affine tilting to fake gaze. A literal whole-object rotation is acceptable only for a genuinely rotating rigid object when the mechanics decision explicitly justifies it. Eyeless object pets should preserve a natural front, display face, playable surface, or iconic viewing angle and express attention through an object-specific lean, hinge, tip aim, yaw, pitch, bend, squash, vibration, follow-through, or attached-part motion.

Preserve the source eye design. Do not paint replacement googly eyes, eye whites, floating pupils, detached eye dots, or a second eye layer. Physical eyes change as one surface including sclera, iris, pupil, eyelids, rim, and highlights; do not slide only an iris or pupil across a fixed eye white. Flat printed, sticker, or screen eyes may change only their surface features. Procedural eye compositing is permitted only when clipped to the original aperture and visibly inside the head silhouette in every direction. If the original construction cannot be preserved, regenerate the whole look cell or row with that construction.

Pupil-only motion is an exception requiring a mechanics reason. Large-eye, cyclops, and round rigid-body pets usually rotate whole eye globes. Separate-head pets combine eye movement with head turn, tilt, appendage follow-through, and a stable torso. Props near the face may become side-on or partly hidden; tools may lag while attached; worn props follow the body; cords and straps arc continuously. Do not keep a prop and character in the same front-facing relationship across all directions.

## Cardinal and look-row generation

Use the approved `decoded/look-anchors-approved.png` as the direction basis. The cardinal strip order is fixed:

```text
000 up / 12 o'clock
090 screen-right
180 down
270 screen-left
```

Row order is fixed:

```text
row 9:  000, 022.5, 045, 067.5, 090, 112.5, 135, 157.5
row 10: 180, 202.5, 225, 247.5, 270, 292.5, 315, 337.5
```

Both look rows are normal `$imagegen` jobs with the canonical base, approved 8×9 contact sheet, cardinal strip, and any manifest-listed layout guide attached. Generate each row as one complete eight-frame family. Never ask imagegen for a complete 8×11 atlas and never paste independently generated repair cells into a newly generated coherent row.

After copying row 9 to `decoded/look-row-9.png`, register it with the same transform used by final assembly and inspect the eight registered cells at normal pet size:

```bash
CHROMA_KEY=$(jq -r '.chroma_key.hex' "$RUN_DIR/pet_request.json")
"$PYTHON" "$SKILL_DIR/scripts/assemble_extended_atlas.py" \
  --base-atlas "$RUN_DIR/final/spritesheet.webp" \
  --look-row-9 "$RUN_DIR/decoded/look-row-9.png" \
  --neutral-cell "$RUN_DIR/frames/idle/00.png" \
  --chroma-key "$CHROMA_KEY" \
  --chroma-threshold 96 \
  --registered-row-output "$RUN_DIR/qa/look-row-9-registered.png" \
  --registration-manifest-output "$RUN_DIR/qa/look-row-9-registration.json"
```

Record row-9 semantic evidence and adjacent continuity. A hard failure requires resynthesizing the complete row and repeating registration and review. Only then mark `look-row-9` complete; that completion releases row 10 in `imagegen-jobs.json`. Row 10 must use the approved row-9 registration and transform, not a new scale or baseline.

### Direction Acceptance Policy

Judge the 16 cells as one ordered animation family. Cardinals must be unmistakable at normal pet size: `000` up, `090` right, `180` down, and `270` left. Diagonals and intermediates should occupy the intended quadrant and advance through the clockwise loop. Minor pupil, nose, eyelid, or feature-placement differences alone are warnings; gross wrong quadrants, reversals, identity changes, and broken mechanics are failures.

Hard failures require complete containing-row regeneration:

- a cardinal is wrong or ambiguous, including a blind cardinal classification that contradicts or cannot confirm it
- labeled review finds a wrong principal quadrant, a missing required axis, or a visible loop reversal
- the ordered loop backtracks, crosses quadrants, snaps, pops in scale, jumps registration, changes identity, or breaks a prop attachment
- deterministic structural validation fails, or review finds clipping, an accidental transparent interior hole, seam band, replacement eyes, or materially broken sprite
- whole-sprite rotation, deformation, or eye mechanics break identity or coherence

Review warnings do not require regeneration by themselves when labeled normal-size review confirms the intended direction and the loop remains cohesive:

- an intermediate resembles a neighbor or a diagonal cue is subtle
- blind reviewers disagree, vote `ambiguous`, or produce an opposite-sign intermediate majority
- continuity metrics report a diff, center, area, or alpha-hole candidate without a visible snap, pop, seam, or broken silhouette

Create `qa/direction-semantics.json` with `pass`, `warning`, or `fail` for all 16 directions. Each entry includes `verdict`, `expected`, `observed`, and `reason`, with separate visible horizontal and vertical evidence for diagonals. A warning may record intermediate blind uncertainty; it never waives a wrong or ambiguous cardinal, wrong quadrant, or reversal. If any direction receives `fail`, strengthen the containing row prompt and resynthesize that complete row.

## Extended assembly and transparency

Use the run's selected chroma key from `pet_request.json` for every assembly path. Omitting it can classify a magenta key as sprite pixels.

```bash
CHROMA_KEY=$(jq -r '.chroma_key.hex' "$RUN_DIR/pet_request.json")
```

Extended assembly recovers each complete pose group from the original-resolution row, preserves left-to-right order, and computes one shared scale from the neutral frame's height and lower-body anchor plus every pose's left/right extents. It crops each source exactly once, never enlarges an already resampled cell, and applies near-edge clipping checks only after normalization. If pose-group recovery is ambiguous or row 10 cannot fit row 9's approved transform, resynthesize row 10; do not rescale row 9, patch a final cell, or relax the edge threshold.

```bash
"$PYTHON" "$SKILL_DIR/scripts/assemble_extended_atlas.py" \
  --base-atlas "$RUN_DIR/final/spritesheet.webp" \
  --registered-row-9 "$RUN_DIR/qa/look-row-9-registered.png" \
  --row-9-registration "$RUN_DIR/qa/look-row-9-registration.json" \
  --look-row-10 "$RUN_DIR/decoded/look-row-10.png" \
  --neutral-cell "$RUN_DIR/frames/idle/00.png" \
  --chroma-key "$CHROMA_KEY" \
  --chroma-threshold 96 \
  --output "$RUN_DIR/final/spritesheet-extended.png" \
  --webp-output "$RUN_DIR/final/spritesheet-extended.webp" \
  --manifest-output "$RUN_DIR/final/spritesheet-extended.json"
```

PowerShell passes the same arguments as an array:

```powershell
$AssemblyArgs = @(
    (Join-Path $SkillDir 'scripts/assemble_extended_atlas.py')
    '--base-atlas'; (Join-Path $RunDir 'final/spritesheet.webp')
    '--registered-row-9'; (Join-Path $RunDir 'qa/look-row-9-registered.png')
    '--row-9-registration'; (Join-Path $RunDir 'qa/look-row-9-registration.json')
    '--look-row-10'; (Join-Path $RunDir 'decoded/look-row-10.png')
    '--neutral-cell'; (Join-Path $RunDir 'frames/idle/00.png')
    '--chroma-key'; $ChromaKey
    '--chroma-threshold'; '96'
    '--output'; (Join-Path $RunDir 'final/spritesheet-extended.png')
    '--webp-output'; (Join-Path $RunDir 'final/spritesheet-extended.webp')
    '--manifest-output'; (Join-Path $RunDir 'final/spritesheet-extended.json')
)
& $Python @AssemblyArgs
if ($LASTEXITCODE -ne 0) { throw 'Extended assembly failed.' }
```

Look cells must share the neutral/default practical scale, baseline, body registration, and lower-body anchor. Reject cells that float, slide laterally while only changing gaze, or differ noticeably in size. If a dedicated neutral frame exists, pass it with `--neutral-cell`; otherwise the assembler falls back to the populated neutral/default or first visible idle frame.

Run one deterministic edge-local spill-suppression pass on the completed v2 atlas. The pass preserves alpha, clears RGB below fully transparent pixels, and reports its algorithm and parameters.

The pass selects every translucent silhouette-boundary pixel and every opaque boundary pixel whose chroma points toward the run's key, then extends clean interior RGB outward through that band in linear light. Its report and the atlas validator are authoritative for chroma contamination.

```bash
"$PYTHON" "$SKILL_DIR/scripts/despill_chroma_edges.py" \
  "$RUN_DIR/final/spritesheet-extended.png" \
  --output "$RUN_DIR/final/spritesheet-extended.png" \
  --webp-output "$RUN_DIR/final/spritesheet-extended.webp" \
  --chroma-key "$CHROMA_KEY" \
  --json-out "$RUN_DIR/qa/chroma-despill-extended.json"
```

The final despill report is authoritative for chroma. When it has `ok: true` and v2 validation passes, do not regenerate imagery, rerun despill, tune thresholds, or add another chroma pass because of perceived fringe. If either deterministic check fails, report a pipeline failure and do not use image retries as a substitute. The 8×9 intermediate is never despilled; rows `0-8` and look rows `9-10` are cleaned together exactly once.

Reject accidental fully transparent holes inside filled bodies, including horizontal bands, seam rows, scanline gaps, sliced-tile boundaries, and see-through interior stripes. Intentional negative-space openings in the design remain allowed. Inspect suspect cells on a high-contrast background or alpha mask; ordinary geometry validation alone cannot decide an interior hole.

Validate and create the extended contact sheet:

```bash
"$PYTHON" "$SKILL_DIR/scripts/validate_atlas.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --json-out "$RUN_DIR/final/validation-extended.json" \
  --chroma-key "$CHROMA_KEY" \
  --require-v2
"$PYTHON" "$SKILL_DIR/scripts/make_contact_sheet.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --output "$RUN_DIR/qa/contact-sheet-extended.png"
```

## Labeled and blind direction QA

Create the focused labeled direction sheet and the randomized blind challenge:

```bash
"$PYTHON" "$SKILL_DIR/scripts/make_direction_qa_sheet.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --output "$RUN_DIR/qa/look-directions.png"
"$PYTHON" "$SKILL_DIR/scripts/make_direction_blind_qa_sheet.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --output "$RUN_DIR/qa/direction-blind-pairs.png" \
  --answer-key "$RUN_DIR/qa/direction-blind-answer-key.json"
```

The focused sheet shows neutral/rest beside all 16 look cells at approximately in-app display size, labeled by degree and expected direction. Inspect the full body and zoomed head/upper-body views. Measure adjacent continuity separately and treat metrics as review evidence:

```bash
"$PYTHON" "$SKILL_DIR/scripts/measure_direction_continuity.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --json-out "$RUN_DIR/qa/look-continuity.json"
```

Give three fresh isolated workers only `qa/direction-blind-pairs.png`, write their classifications to separate verdict files, and never expose the answer key, degree labels, labeled sheet, atlas, prompts, prior QA, or another worker's result. Combine strict per-cell majority and apply the hidden answer key only to that consensus:

```bash
"$PYTHON" "$SKILL_DIR/scripts/combine_direction_blind_verdicts.py" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts-1.json" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts-2.json" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts-3.json" \
  --json-out "$RUN_DIR/qa/direction-blind-verdicts.json"
"$PYTHON" "$SKILL_DIR/scripts/validate_direction_blind_verdicts.py" \
  --answer-key "$RUN_DIR/qa/direction-blind-answer-key.json" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts.json" \
  --json-out "$RUN_DIR/qa/direction-blind-validation.json"
```

The hidden key has seven horizontal and seven vertical pairs. Cardinal pairs are hard gates: a mismatch or ambiguous majority leaves `ok: false`. Intermediate mismatches, same-direction votes, or ambiguous majorities remain warnings for labeled normal-size review. Blind QA is mandatory even when all labeled cells look correct.

### Blind Review Severity Resolution

When blind or final visual QA fails, inspect its reasons, the labeled sheet, `qa/direction-semantics.json`, and `qa/look-continuity.json` before regenerating:

- `major`: wrong or ambiguous cardinal; labeled wrong quadrant or visible reversal; conspicuous snap, scale pop, identity change, broken attachment, clipping, interior seam/hole, or deterministic validation failure. Repair is required.
- `minor`: exact pupil/nose placement differs from the numerical ideal; a near-vertical cue is subtle; isolated reviewers disagree or return `ambiguous`; intermediate blind majority conflicts while the labeled loop reads correctly; or continuity metrics warn without a visible defect. An explicit override may accept it.

Record every accepted minor override in `qa/blind-review-resolution.json` with `decision: "accept"`, `severity: "minor"`, failed checks, labeled/continuity evidence, and `reviewed_by: "parent"` or `"user"`. Never override a major failure or use an override to hide missing evidence. Keep the blind sheet, consensus, validation, labeled semantics, continuity report, and resolution file in the QA artifacts.

Inspect `qa/contact-sheet-extended.png`, `qa/look-directions.png`, `qa/look-continuity.json`, and the preview GIFs as an ordered loop. Record visual semantics for every expected direction. Reject identity drift, missing/blank frames, guide pixels, nontransparent panels, cropping, slot overlap, detached effects, shadows, glows, smears, dust, wrong state motion, size popping, wrong facing, reversed/non-alternating gait, and inert idle loops. Deterministic despill and v2 validation decide chroma after cleanup.

The parent may not self-approve a repaired look direction. Obtain the independent final visual-QA worker specified in [visual-workers.md](visual-workers.md) after all relevant artifacts exist. Explicit user inspection can supplement the record but does not replace this independent gate.

## Acceptance Criteria

The following package steps are part of the acceptance gate.

### Package Completion

Only after deterministic and visual gates pass, stage the v2 package. The manifest field is mandatory because omitting it makes the app interpret the atlas as v1.

```bash
PET_ID=$(jq -r '.pet_id' "$RUN_DIR/pet_request.json")
DISPLAY_NAME=$(jq -r '.display_name' "$RUN_DIR/pet_request.json")
DESCRIPTION=$(jq -r '.description' "$RUN_DIR/pet_request.json")
PET_DIR="${CODEX_HOME:-$HOME/.codex}/pets/$PET_ID"
mkdir -p "$PET_DIR"
cp "$RUN_DIR/final/spritesheet-extended.webp" "$PET_DIR/spritesheet.webp"
jq -n --arg id "$PET_ID" --arg displayName "$DISPLAY_NAME" --arg description "$DESCRIPTION" \
  '{id: $id, displayName: $displayName, description: $description, spriteVersionNumber: 2, spritesheetPath: "spritesheet.webp"}' \
  > "$PET_DIR/pet.json"
```

PowerShell package equivalent:

```powershell
$Request = Get-Content -LiteralPath (Join-Path $RunDir 'pet_request.json') -Raw | ConvertFrom-Json
$PetRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME 'pets' } else { Join-Path $HOME '.codex/pets' }
$PetDir = Join-Path $PetRoot $Request.pet_id
New-Item -ItemType Directory -Force -Path $PetDir | Out-Null
Copy-Item -LiteralPath (Join-Path $RunDir 'final/spritesheet-extended.webp') -Destination (Join-Path $PetDir 'spritesheet.webp') -Force
[ordered]@{
    id = $Request.pet_id
    displayName = $Request.display_name
    description = $Request.description
    spriteVersionNumber = 2
    spritesheetPath = 'spritesheet.webp'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PetDir 'pet.json') -Encoding utf8
```

Write the run summary after packaging, including every required QA artifact and the package directory:

```bash
jq -n \
  --arg run_dir "$RUN_DIR" \
  --arg spritesheet "$RUN_DIR/final/spritesheet-extended.webp" \
  --arg validation "$RUN_DIR/final/validation-extended.json" \
  --arg chroma_despill "$RUN_DIR/qa/chroma-despill-extended.json" \
  --arg contact_sheet "$RUN_DIR/qa/contact-sheet-extended.png" \
  --arg direction_sheet "$RUN_DIR/qa/look-directions.png" \
  --arg direction_semantics "$RUN_DIR/qa/direction-semantics.json" \
  --arg blind_direction_validation "$RUN_DIR/qa/direction-blind-validation.json" \
  --arg blind_review_resolution "$RUN_DIR/qa/blind-review-resolution.json" \
  --arg continuity "$RUN_DIR/qa/look-continuity.json" \
  --arg review "$RUN_DIR/qa/review.json" \
  --arg package "$PET_DIR" \
  '{ok: true, spriteVersionNumber: 2, run_dir: $run_dir, spritesheet: $spritesheet, validation: $validation, chroma_despill: $chroma_despill, contact_sheet: $contact_sheet, direction_sheet: $direction_sheet, direction_semantics: $direction_semantics, blind_direction_validation: $blind_direction_validation, blind_review_resolution: $blind_review_resolution, continuity: $continuity, review: $review, package: $package}' \
  > "$RUN_DIR/qa/run-summary.json"
```

The completion gate requires all of the following:

- final PNG or WebP exactly `1536x2288`, based on `192x208` cells and 8×11 layout
- rows `0-8` satisfy [animation-rows.md](animation-rows.md); all 16 look directions are present in fixed clockwise order
- `pet.json` has `spriteVersionNumber: 2`, points to the staged spritesheet, and is staged beside it
- used cells are non-empty, unused standard-row cells are fully transparent, and the final despill report has `ok: true`
- `validate_atlas.py --require-v2` passes with the run's chroma key and `qa/review.json` has no errors
- cardinal anchors are extracted, clipping-checked, and semantically approved; row 9 and row 10 each pass registration, edge, semantic, and continuity gates
- `qa/direction-semantics.json` covers all 16 directions with explicit evidence; no hard failures remain
- three isolated blind workers produce a consensus and `qa/direction-blind-validation.json` is `ok: true`, or a documented minor override is accepted without a cardinal failure
- contact sheets, per-row motion previews, focused direction sheet, and independent final visual-QA result exist and are reviewed
- `qa/look-continuity.json` has no unexplained visible snap, pop, identity change, broken silhouette, or semantic discontinuity
- output rights and source/attribution notes are retained when supplied; the skill's Apache-2.0 `LICENSE.txt` remains with distributed skill files

After acceptance, retain the manifest and QA evidence requested by the user. If cleanup is requested, remove prompts, layout guides, generated row strips, extracted frames, PNG intermediates, the 8×9 atlas, and the imagegen job manifest only after the accepted evidence and final package exist. Never remove the final package or its manifest as part of ordinary cleanup.
