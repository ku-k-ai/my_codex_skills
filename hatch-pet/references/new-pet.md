# New pet workflow

> Adapted for Codex, 2026-09-08: new-pet route extracted for progressive disclosure. Source: the original hatch-pet workflow.

Use this reference for a pet created from text, a concept, a brand handoff, or reference art. Before starting, read [codex-pet-contract.md](codex-pet-contract.md), [animation-rows.md](animation-rows.md), and [command-conventions.md](command-conventions.md). If image work is delegated, read [visual-workers.md](visual-workers.md) before dispatching workers. Finish through [assembly-qa.md](assembly-qa.md).

Every command such as `scripts/prepare_pet_run.py` means `<skill-root>/scripts/prepare_pet_run.py`, where `<skill-root>` is the directory containing the hatch-pet `SKILL.md`. Set `$SKILL_DIR` to that absolute directory as described in [command-conventions.md](command-conventions.md). Confirm the shell before using a fenced `bash` example; PowerShell uses the argument-array translation there.

## Inputs and visual identity

Choose or infer a short pet name and one-sentence description. Accept text-only concepts, one or more authorized reference images, or a compact brand handoff. If no image is supplied, the selected base output becomes the canonical identity reference for every row. Preserve the same face, proportions, materials, palette, markings, silhouette, and props across the run. A reference image grounds identity and style; it does not dictate final cell geometry.

Choose `auto` unless the user names a style. Supported presets are `pixel`, `plush`, `clay`, `sticker`, `flat-vector`, `3d-toy`, `painterly`, `brand-inspired`, and `auto`. Any style is acceptable when the whole-body silhouette reads inside `192x208`, detail remains legible at pet size, the style is stable across rows, and the background is a clean removable chroma key. Do not add text, labels, UI, readable logos, or scenery.

Treat transparency as a sprite property from the beginning. Every generated pixel must belong to the pet or be cleanly removable chroma-key background. Prefer pose and expression changes over decorative effects. The deterministic pipeline owns alpha and edge cleanup; do not add a second visual cleanup pass.

### Pet-Safe Styles

The style presets and pet-size readability rules above apply to every row. Non-pixel styles are first-class when the whole-body silhouette, face, material, palette, and props remain consistent.

### Transparency And Effects

Allowed effects are state-relevant, attached to or overlapping the silhouette, in the same frame slot, opaque enough to extract, non-chroma-key colored, and small enough to read at `192x208`. Avoid wave marks, motion arcs, speed lines, afterimages, blur, smears, detached stars or sparkles, floating punctuation or icons, loose tears or smoke, shadows, glows, halos, scenery, grids, guide marks, checkerboards, stray pixels, disconnected outline fragments, cropped parts, and poses that cross a neighboring slot.

State semantics are part of the visual contract:

- `idle`: calm breathing, blink, tiny bob, or subtle material sway with visible micro-variation. Keep it distinct from waving, walking, jumping, working, reviewing, or reacting.
- `running-right` and `running-left`: directional drag movement with a visibly alternating cadence. The pet must face and travel in the named screen direction; express motion through the body, limbs, and attached props.
- `waving`: a paw, hand, wing, or limb pose with no wave marks or floating effects.
- `jumping`: vertical body movement with no shadow, dust, landing mark, impact burst, or floor cue.
- `failed`: a readable error, sad, or deflated reaction. Attached opaque smoke, tears, or stars are allowed; detached effects and symbols are not.
- `waiting`: an expectant asking pose for approval, help, or user input, distinct from idle and review.
- `running`: active task work, processing, scanning, typing, or focused effort. It is not literal foot-running or locomotion.
- `review`: focused inspection through lean, blink, eyes, head tilt, or hand position; do not add new papers, code, UI, punctuation, or props.

## Visible Progress Plan

Create and update this checklist before and during the run:

1. `Getting <Pet> ready.` Confirm name, description, source images, style, notes, run folder, and any compact brand handoff.
2. `Imagining <Pet>'s main look.` Generate, select, copy, and approve the canonical base image.
3. `Picturing <Pet>'s poses.` Generate and incrementally validate rows `0-8`, write the pet-specific look mechanics plan, then generate rows `9-10` through [assembly-qa.md](assembly-qa.md).
4. `Hatching <Pet>.` Assemble, independently review, validate, package, and report the v2 outputs.

Mark a step complete only when its actual file, image, or decision exists. A 30-minute planning target can prioritize the dependency path but never waives a row, direction, transparency, or package gate.

## Time Budget And Convergence

At each failure, classify the root condition, fix deterministic problems deterministically, regenerate only when the source is wrong, preserve passing properties, and compare the replacement. After the same root failure recurs twice, change the strategy or visual construction.

Use the target as a planning aid: preparation 2 minutes, base 3, standard rows 10, look directions 8, final QA and packaging 5, and buffer 2. Continue when the work is converging and bounded; elapsed time never removes a required check.

## Default Workflow

### 1. Prepare the run

For a bare brand or prospect name, complete [brand-discovery.md](brand-discovery.md) first and pass only its compact handoff fields into the run. Use the prepared manifest as the dependency graph for every visual job.

```bash
SKILL_DIR="/absolute/path/to/hatch-pet"
"$PYTHON" "$SKILL_DIR/scripts/prepare_pet_run.py" \
  --pet-name "<Name>" \
  --description "<one sentence>" \
  --reference /absolute/path/to/reference.png \
  --output-dir /absolute/path/to/run \
  --pet-notes "<stable pet description>" \
  --brand-discovery-file /absolute/path/to/brand-discovery.md \
  --brand-name "<optional researched brand name>" \
  --brand-brief "<optional compact researched brand cue sentence>" \
  --brand-source "https://example.com/source" \
  --style-preset auto \
  --style-notes "<optional freeform style notes>" \
  --force
```

All flags are optional except those needed to express the user's constraints. For text-only input, put the concept in `--pet-notes` and omit `--reference`; the script infers missing metadata as needed. For a brand handoff, pass `--brand-discovery-file`, `avatar_seed` as `--pet-notes` when it is the best available avatar description, `brand_name`, `brand_brief`, and each source URL as a repeated `--brand-source`.

Inspect `imagegen-jobs.json` for the next ready jobs. A job is ready when it is not complete and every id in `depends_on` is complete.

```bash
jq '.jobs[] | {id, kind, status, depends_on, prompt_file, retry_prompt_file, input_images, output_path, derivation_policy}' \
  /absolute/path/to/run/imagegen-jobs.json
```

### Visual Job Graph

A normal run has up to 13 visual jobs: one base, nine standard row strips, one four-cardinal anchor strip, and two coherent look-row strips. An approved deterministic `running-left` mirror can replace one generated row job only after `running-right` is visually approved; all other states remain their own grounded jobs. `prepare_pet_run.py` creates matching layout guides for the nine standard rows, both look rows, and the cardinal strip. Treat those guides as invisible construction references.

### Look Direction Sequence

The four cardinal anchors establish `000` up, `090` screen-right, `180` down, and `270` screen-left. Row 9 then follows `000` through `157.5`; row 10 follows `180` through `337.5`. Complete the full sequence in [assembly-qa.md](assembly-qa.md).

### Visual Provenance And Grounding

Only the base job may be prompt-only. Every row job uses every manifest-listed grounding image, and the parent copies the selected exact output into `decoded/` before marking its job complete. Deterministic scripts process already-generated visual outputs and never populate row outputs.

### 2. Generate the base and standard rows

Use [visual-workers.md](visual-workers.md) for the worker prompts and one-job boundaries. Generate and copy `base` first; the selected base is the visual source of truth. Then generate `idle` and `running-right` as the early identity and gait checks. Generate each remaining state as its own row. Attach every image listed for that job, including its layout guide and canonical base where the manifest calls for them. Do not use a complete atlas generated by `$imagegen`.

After selecting an output, copy it to the manifest's decoded output path. For `base`, also create `references/canonical-base.png`.

```bash
RUN_DIR=/absolute/path/to/run
JOB_ID=<job-id>
SOURCE=/absolute/path/to/generated-output.png
OUTPUT_REL=$(jq -r --arg id "$JOB_ID" '.jobs[] | select(.id == $id) | .output_path' \
  "$RUN_DIR/imagegen-jobs.json")
mkdir -p "$(dirname "$RUN_DIR/$OUTPUT_REL")"
cp "$SOURCE" "$RUN_DIR/$OUTPUT_REL"
if [ "$JOB_ID" = "base" ]; then
  mkdir -p "$RUN_DIR/references"
  cp "$RUN_DIR/$OUTPUT_REL" "$RUN_DIR/references/canonical-base.png"
fi
```

For every standard row, extract and inspect that row before marking its job complete. This keeps a clipping, component, or extraction failure local to the row that produced it.

```bash
ROW_QA_DIR="$RUN_DIR/qa/rows/$JOB_ID"
"$PYTHON" "$SKILL_DIR/scripts/extract_strip_frames.py" \
  --decoded-dir "$RUN_DIR/decoded" \
  --output-dir "$ROW_QA_DIR/frames" \
  --states "$JOB_ID" \
  --method auto
"$PYTHON" "$SKILL_DIR/scripts/inspect_frames.py" \
  --frames-root "$ROW_QA_DIR/frames" \
  --json-out "$ROW_QA_DIR/review.json" \
  --states "$JOB_ID" \
  --require-components
```

Treat errors as an immediate repair request and inspect warnings before acceptance. Chroma cleanup belongs to the single final despill pass in [assembly-qa.md](assembly-qa.md); it is not a row-regeneration trigger. If only component extraction fails while the source strip has stable scale and placement, rerun extraction with the deliberate `stable-slots` correction and `--allow-stable-slots` instead of regenerating the image.

Retry a row once with its manifest-provided `retry_prompt_file` only when `$imagegen` returns a transport-level `Bad Request`. Keep the same input images and canonical base. If the retry fails, report the row and prompt paths; do not switch generation layers.

### 3. Approve running-left and cardinals

Generate `running-right` before deciding whether `running-left` can be derived. Mirror only after visual inspection confirms that identity, prop placement, markings, lighting, facing, and direction remain correct when flipped. The deterministic script mirrors each frame slot in place and preserves temporal order; a whole-strip mirror that reverses timing is invalid.

```bash
"$PYTHON" "$SKILL_DIR/scripts/derive_running_left_from_running_right.py" \
  --run-dir "$RUN_DIR" \
  --confirm-appropriate-mirror \
  --decision-note "<why mirroring preserves this pet's identity>"
```

If mirroring changes meaning or identity, generate `running-left` as its own grounded `$imagegen` row. Never derive `waiting`, `running`, `failed`, `review`, `jumping`, or `waving` from another state.

After standard rows pass, run the prepared `look-cardinals` job. Extract all four anchors, compose the approved strip, and review them at normal pet size before either look row. The fixed viewer-coordinate order is `000` up, `090` screen-right, `180` down, and `270` screen-left. For a face, nose tip and pupils must cross to the corresponding side of the head center; an ambiguous cardinal blocks the next stage.

```bash
CHROMA_KEY=$(jq -r '.chroma_key.hex' "$RUN_DIR/pet_request.json")
"$PYTHON" "$SKILL_DIR/scripts/extract_cardinal_anchors.py" \
  --strip "$RUN_DIR/decoded/look-cardinals.png" \
  --output-dir "$RUN_DIR/decoded/look-anchors" \
  --chroma-key "$CHROMA_KEY" \
  --json-out "$RUN_DIR/qa/cardinal-anchors.json"
"$PYTHON" "$SKILL_DIR/scripts/compose_cardinal_anchor_strip.py" \
  --anchors-dir "$RUN_DIR/decoded/look-anchors" \
  --output "$RUN_DIR/decoded/look-anchors-approved.png"
```

If a cardinal fails, regenerate only that anchor with its `prompts/look-anchor-repairs/<degree>.md`, replace the extracted file, and rerun `compose_cardinal_anchor_strip.py`. Mark a visual job complete only after its selected source has been copied, its deterministic checks pass, and the semantic review exists. Parent-owned manifest updates can use `jq` in POSIX shells or the PowerShell JSON form in [command-conventions.md](command-conventions.md).

### 4. Build and review the intermediate 8×9 atlas

Once all nine standard jobs are incrementally validated, extract the full standard rows, inspect them, compose the intermediate atlas, and render contact-sheet and motion-preview evidence.

```bash
mkdir -p "$RUN_DIR/final" "$RUN_DIR/qa"
"$PYTHON" "$SKILL_DIR/scripts/extract_strip_frames.py" \
  --decoded-dir "$RUN_DIR/decoded" \
  --output-dir "$RUN_DIR/frames" \
  --states all \
  --method auto
"$PYTHON" "$SKILL_DIR/scripts/inspect_frames.py" \
  --frames-root "$RUN_DIR/frames" \
  --json-out "$RUN_DIR/qa/review.json" \
  --require-components
"$PYTHON" "$SKILL_DIR/scripts/compose_atlas.py" \
  --frames-root "$RUN_DIR/frames" \
  --output "$RUN_DIR/final/spritesheet.png" \
  --webp-output "$RUN_DIR/final/spritesheet.webp"
"$PYTHON" "$SKILL_DIR/scripts/make_contact_sheet.py" \
  "$RUN_DIR/final/spritesheet.webp" \
  --output "$RUN_DIR/qa/contact-sheet.png"
"$PYTHON" "$SKILL_DIR/scripts/render_animation_previews.py" \
  --frames-root "$RUN_DIR/frames" \
  --output-dir "$RUN_DIR/qa/previews"
```

If playback shows extraction-induced size popping or baseline jumps while the source strip is stable, rerun extraction with `--method stable-slots`, inspect with `--allow-stable-slots`, and repeat atlas/contact-sheet/preview generation. Use that mode only as an evidence-based correction; it must not hide clipped poses or an unstable source.

Review `qa/contact-sheet.png`, the row GIFs, and `qa/review.json` before proceeding. Block progress for identity or style drift, prop handedness changes, clipped or cropped bodies, wrong facing, reversed or inert loops, detached effects, interior transparent holes, repeated tiles, or visible guide pixels. This contact sheet predates final chroma cleanup, so key-color fringe there is judged only after the cleaned v2 atlas exists.

The intermediate output should include:

```text
run/
  pet_request.json
  imagegen-jobs.json
  prompts/
  decoded/
  frames/frames-manifest.json
  final/spritesheet.webp
  qa/contact-sheet.png
  qa/previews/*.gif
  qa/review.json
```

Do not package this 8×9 atlas. Hand the run to [assembly-qa.md](assembly-qa.md) for the required v2 look stage, final despill, blind direction QA, independent visual review, packaging, and completion evidence.

## PowerShell check example

The same incremental check uses argument arrays in PowerShell:

```powershell
$SkillDir = (Resolve-Path 'C:\path\to\hatch-pet').Path
$RowQaDir = Join-Path $RunDir ('qa/rows/' + $JobId)
$ExtractArgs = @(
    (Join-Path $SkillDir 'scripts/extract_strip_frames.py')
    '--decoded-dir'; (Join-Path $RunDir 'decoded')
    '--output-dir'; (Join-Path $RowQaDir 'frames')
    '--states'; $JobId
    '--method'; 'auto'
)
& $Python @ExtractArgs
if ($LASTEXITCODE -ne 0) { throw 'Row extraction failed.' }
$InspectArgs = @(
    (Join-Path $SkillDir 'scripts/inspect_frames.py')
    '--frames-root'; (Join-Path $RowQaDir 'frames')
    '--json-out'; (Join-Path $RowQaDir 'review.json')
    '--states'; $JobId
    '--require-components'
)
& $Python @InspectArgs
if ($LASTEXITCODE -ne 0) { throw 'Row inspection failed.' }
```
