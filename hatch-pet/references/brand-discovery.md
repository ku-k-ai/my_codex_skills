# Brand discovery route

> Adapted for Codex, 2026-09-08: brand research route extracted for progressive disclosure. Source: the original hatch-pet brand-discovery workflow.

Read this reference only when the user gives a brand, product, company, or prospect name without a concrete avatar description or reference image, or explicitly asks for brand research. Then continue with [new-pet.md](new-pet.md) or [repair-upgrade.md](repair-upgrade.md). Do not run discovery when the user's concrete art or avatar brief already supplies the visual grounding unless research was requested.

## Brand Discovery

### Scope and evidence

Run a lightweight discovery worker using web search. Search 2–4 relevant sources, preferring the official brand site, product pages, documentation, about pages, press pages, and brand pages. Use reputable secondary sources only when official sources are too thin. The goal is a mascot-ready visual and personality brief, not market research.

The brief must cover:

- identity and category: canonical name, product type, and what it does
- audience and use context: who it serves and where the pet will appear
- visual system: palette, shapes, line quality, materials, typography feel, iconography, and patterns
- personality and tone: emotional traits, energy, formality, and playfulness
- product/domain motifs: objects, workflows, verbs, metaphors, and environments
- mascot translation cues: candidate forms, signature traits, props, and what reads at pet size
- avoidances: logos or text, trademark-sensitive elements, misleading cues, competitor confusion, and poor mascot fits
- evidence and confidence: source URLs and notes where a conclusion is weak or inferred

Mark mascot guidance inferred from sources as inference. Do not reproduce logos, readable marks, UI screenshots, slogans, or text. Brand sources are evidence for broad cues and do not grant permission to reproduce protected artwork or imply endorsement. Use only authorized reference art and keep its license/attribution information with the run when supplied.

## Discovery worker prompt

```text
Research a brand for hatch-pet mascot creation.

Brand/product/prospect: <brand name>
User context: <short user request>
Output file: <absolute path to brand-discovery.md>

Use web search. Prefer official brand, product, docs, about, press, or brand pages. Use reputable secondary sources only if official sources are too thin. Write an adaptive markdown brief to the output file. Headings may flex by brand, but the brief must cover:
- identity/category: canonical name, product type, what it does
- audience/use context: who it serves and where it appears
- visual system: palette, shapes, line quality, materials, typography feel, iconography, patterns
- personality/tone: emotional traits, energy, formality, playfulness
- product/domain motifs: objects, workflows, verbs, metaphors, environments
- mascot translation cues: candidate forms, signature traits, props, what must read at pet size
- avoidances: logos/text, trademark-sensitive elements, misleading cues, competitor confusion, poor mascot fits
- evidence/confidence: source URLs plus notes where evidence is weak or inferred

Do not copy logos, readable marks, UI screenshots, slogans, or text. Clearly label mascot guidance that is inferred rather than directly sourced.

End the brief with a `Generation handoff` section containing exactly:
- brand_name=<canonical brand/product name>
- brand_brief=<one sentence, max 45 words, covering palette/tone/domain motifs/personality>
- avatar_seed=<short mascot-safe visual idea, no logo copying>
- avoid=<short comma-separated list>
- brand_sources=<comma-separated source URLs>

Return exactly:
brand_discovery_file=<absolute output file path>
brand_name=<canonical brand/product name>
brand_brief=<same compact sentence from Generation handoff>
avatar_seed=<same short seed from Generation handoff>
avoid=<same short avoid list from Generation handoff>
brand_sources=<same comma-separated URLs from Generation handoff>
```

The worker must not generate images, prepare a run folder, edit manifests, or edit unrelated files. The parent saves the markdown brief before preparing the run, then passes its compact fields to `prepare_pet_run.py`:

```text
--brand-discovery-file <brief path>
--brand-name <brand_name>
--brand-brief <brand_brief>
--brand-source <source URL>   # repeat once per URL
--pet-notes <avatar_seed>     # only when the user gave no better avatar description
```

Keep the full brief for review; only the compact handoff fields shape generation prompts. If web search is unavailable and the user gave only a bare brand name, request brand cues before generating. Do not substitute guessed brand facts for missing evidence.
