# Repair and upgrade workflow

> Adapted for Codex, 2026-09-08: repair and upgrade route extracted for progressive disclosure. Source: the original hatch-pet workflow.

Use this reference for existing character art, a built-in pet, a standard/v2 atlas, or a run whose deterministic or visual QA failed. Read [codex-pet-contract.md](codex-pet-contract.md), [animation-rows.md](animation-rows.md), [qa-rubric.md](qa-rubric.md), and [command-conventions.md](command-conventions.md) before changing files. Use [visual-workers.md](visual-workers.md) for regenerated images and finish through [assembly-qa.md](assembly-qa.md).

Every `scripts/...` path means `<skill-root>/scripts/...`, with `<skill-root>` resolved from the directory containing the hatch-pet `SKILL.md`. Confirm the shell before using `bash` blocks; PowerShell uses the argument-array and file-operation forms in [command-conventions.md](command-conventions.md).

## Existing Inputs and Upgrades

Treat character art, generated images, standard or v2 atlases, contact sheets, and built-in pet art as grounding inputs. Preserve source art as a visual reference while validating its geometry. Do not assume a supplied image already has final cell boundaries. Check the source and its license or user authorization before using it.

- For a valid user-provided 8×9 atlas, deterministically and visually validate rows `0-8`, use it as the intermediate standard atlas, generate rows `9-10`, and package only the resulting v2 8×11 atlas.
- For a valid user-provided 8×11 atlas, preserve approved standard rows. If a look cell fails, regenerate the complete containing coherent 8-frame row before deterministic reassembly. A newly generated one-off repair cell cannot be placed beside cells from another generation.
- For an approved user-provided coherent 16-cell look set, individual-cell assembly is available only as an input upgrade path. It is never a way to patch a newly generated look row.
- For a built-in pet, extract its atlas or a neutral/idle cell and use that as the canonical identity reference after inspection.
- Include every image that defines head shape, face, palette, markings, material, flame, ears, hair, props, or look mechanics when generating a replacement row.
- If a renderer or source provides a dedicated neutral/front frame, pass it to the assembler as `--neutral-cell`; otherwise use the approved idle/default frame. The directional `000` cell always means up and never serves as neutral.

The v2 contract remains mandatory for upgrades: `1536x2288`, `192x208` cells, rows `0-8` plus all 16 fixed-order look directions, `spriteVersionNumber: 2`, final despill and `validate_atlas.py --require-v2`. Never package the 8×9 intermediate.

## Repair Workflow

Read the relevant `qa/review.json`, deterministic report, direction semantics, continuity report, and independent visual-QA note before regenerating. Classify the failure as visual semantics, identity, source-edge geometry, component connectivity, extraction, chroma, continuity, or final visual QA. Change the smallest scope that can remove the root condition:

1. Fix deterministic extraction, registration, or manifest errors with the existing scripts.
2. Regenerate one standard row when one standard state is wrong.
3. Regenerate the complete containing coherent look row when a look direction is wrong, ambiguous, or identity-breaking.
4. Rebuild the atlas and rerun every downstream deterministic and visual gate affected by the replacement.

Preserve all properties that passed and compare the replacement against the prior output. If the same root failure recurs twice, change the pose construction, look mechanics, source layout, or extraction strategy. Do not keep varying a prompt while moving the same failure between cells.

## Replacing a row

Use the existing job's prompt, retry prompt, input images, and output path. A replacement source must be copied into the same decoded path and the manifest must retain `status: "complete"` only after row extraction and inspection pass. The selected source and new completion timestamp replace the old provenance fields.

```bash
RUN_DIR=/absolute/path/to/run
JOB_ID=<failed-row-id>
SOURCE=/absolute/path/to/replacement-row.png
OUTPUT_REL=$(jq -r --arg id "$JOB_ID" '.jobs[] | select(.id == $id) | .output_path' \
  "$RUN_DIR/imagegen-jobs.json")
cp "$SOURCE" "$RUN_DIR/$OUTPUT_REL"
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

For a coherent look-row repair, keep all eight poses in one regenerated source strip. Re-register the complete row with the exact final-assembly transform, rerun post-registration edge diagnostics, and record explicit labeled semantics and adjacent continuity before allowing the next row or assembly stage. Do not paste a replacement normalized cell into an otherwise new generated row.

For a supplied coherent 16-cell upgrade, use the documented `--look-cells-dir` assembly path only after the source set itself is approved as coherent and authorized:

```bash
"$PYTHON" "$SKILL_DIR/scripts/assemble_extended_atlas.py" \
  --base-atlas "$RUN_DIR/final/spritesheet.webp" \
  --look-cells-dir /absolute/path/to/look-cells \
  --neutral-cell "$RUN_DIR/frames/idle/00.png" \
  --chroma-key "$CHROMA_KEY" \
  --chroma-threshold 96 \
  --output "$RUN_DIR/final/spritesheet-extended.png" \
  --webp-output "$RUN_DIR/final/spritesheet-extended.webp" \
  --manifest-output "$RUN_DIR/final/spritesheet-extended.json"
```

## Completion after repair

Run the same downstream gates required for a new pet: deterministic frame inspection, v2 assembly, one final edge-local despill, v2 atlas validation, contact sheets and previews, explicit semantics for all directions, continuity review, three isolated blind direction workers with consensus, independent final visual QA, and package manifest validation. [assembly-qa.md](assembly-qa.md) is authoritative for command order and completion evidence.

Keep the previous QA artifacts when they explain the repair, and add the new report rather than hiding a failed attempt. Remove debug sources only after the repaired package is accepted and the user did not request them.
