---
name: social-fetch
description: "Fetch social posts by URL with an available public API or browser, normalize the fields actually retrieved, and report incomplete data. Use for X/Twitter, LinkedIn, Instagram, TikTok, Bluesky, Reddit, Mastodon, Threads, or Hacker News posts."
metadata:
  version: 0.1.1
---

# /social-fetch — Pull any social post by URL

Normalized fetcher for social posts across platforms. Detects platform from URL, tries strategies in order, returns the same JSON shape regardless of source.

## Step 1 — Detect platform

| URL pattern | Platform |
|---|---|
| `x.com/<user>/status/<id>` or `twitter.com/<user>/status/<id>` | **x** (Twitter) |
| `linkedin.com/posts/<slug>` or `linkedin.com/feed/update/urn:li:activity:<id>` | **linkedin** |
| `linkedin.com/in/<handle>` (profile, recent activity) | **linkedin-profile** |
| `instagram.com/p/<id>` or `instagram.com/reel/<id>` | **instagram** |
| `tiktok.com/@<user>/video/<id>` | **tiktok** |
| `bsky.app/profile/<handle>/post/<rkey>` | **bluesky** |
| `reddit.com/r/<sub>/comments/<id>/...` | **reddit** |
| `<mastodon-instance>/@<user>/<id>` (e.g. mastodon.social, hachyderm.io) | **mastodon** |
| `threads.net/@<user>/post/<id>` | **threads** |
| `news.ycombinator.com/item?id=<id>` | **hn** |
| `youtube.com/watch?v=<id>` or `youtu.be/<id>` | → defer to `watch-video` |

If the URL doesn't match any pattern, ask the user what platform it is.

## Step 2 — Pick strategy chain

Read `references/strategies.md` for the per-platform strategy chain. Each platform has 2–5 strategies tried in order.

Key principles:
- Start with the first actually usable public API or browser strategy for the platform; do not infer coverage from a source label.
- Paid APIs (ScrapeCreators / Apify) are opt-in fallbacks: use them only when the requested depth needs them, an environment key is already set, and the user has authorized that depth.
- Treat a response as complete only when every requested field was observed. A response may be useful and still be partial.

## Step 3 — Execute strategy

For each permitted strategy in the chain:
1. Try it and record the source, status, and fields present in the response.
2. Parse and normalize the response, preserving explicit zero values and empty lists while marking absent fields as missing.
3. If every requested field is present, return `completeness.status: "complete"`.
4. If useful fields are present but some requested fields are absent, retain the best partial result and try another permitted strategy only when it can fill those fields. A failed request (404, 402, auth wall, or empty response) is recorded before continuing.

After exhausting the chain, return the best result with `completeness.status: "partial"` when any post data was retrieved. Name the exact missing fields, the strategies tried, why they failed or stopped, and what is needed to unlock them (for example, an already-authorized paid key). Return an error only when no usable post data was retrieved.

## Step 4 — Normalize output

Return this shape regardless of platform (see `references/output-schema.md` for the full spec + platform-specific examples):

```json
{
  "platform": "x",
  "url": "https://x.com/example/status/1234567890",
  "fetched_at": "2026-06-17T14:35:00Z",
  "raw_source": "scrapecreators",
  "completeness": {
    "status": "complete",
    "requested": ["post", "author"],
    "available": ["post", "author"],
    "missing": []
  },
  "author": {
    "handle": "@example",
    "name": "the user Ganim",
    "verified": true
  },
  "posted_at": "2026-06-17T16:53:00Z",
  "text": "The 80/20 of a useful AI second brain: ...",
  "media": [],
  "engagement": {
    "likes": 51,
    "reposts": 13,
    "replies": 9,
    "bookmarks": 7,
    "views": 32700
  },
  "is_thread": false,
  "thread": [],
  "replies": []
}
```

Fields with no equivalent on a platform (e.g., `bookmarks` on Mastodon) get `null`, not `0`. Missing data is different from zero data.

## Step 5 — Optional enrichments

Based on flags / asks:

| Flag | Behavior |
|---|---|
| `--with-replies` | Fetch top-level replies (1 hop) when requested; mark the result partial if any requested replies were not retrieved. |
| `--thread` | If requested, fetch the whole same-author thread; mark missing siblings instead of inferring them. |
| `--raw` | Include the raw API/scrape response in the output (for debugging) |
| `--media` | Download media files (images/videos) to `~/Documents/social-fetches/<platform>-<id>/` |

Default: just the post itself, no replies, no media download (just URLs).

Thread and reply enrichment is an explicit depth boundary. Before the first paid call, confirm that the user wants that depth and that the matching environment key is already configured. If the boundary is not met, stop before the paid call and report the missing fields and setup path.

## Step 6 — Cache (optional)

If `~/Documents/social-fetches/_cache/` exists, cache successful fetches there by `{platform}-{id}.json` for 24h. Saves API quota when the same post is referenced repeatedly across skills.

Skip cache if `--no-cache` flag is set or for `--with-replies` / `--thread` (likely-stale).

## Composes with

- `deep-research` — cite specific posts in research briefs. When research surfaces a relevant tweet/post URL, fetch and include in the brief.
- `jab-hook` — pull recent posts from inspiration accounts for deeper format analysis (currently uses agent-browser inline; should call this skill instead).
- `business-brainstorm` — pull competitor / operator commentary as evidence during scoring.
- `second-brain` — capture a post into `raw/` with the `tweet-` / `bookmark-` prefix; the structured output makes for cleaner raw files than a screenshot or copy-paste.
- `watch-video` — for YouTube URLs (or any video — Loom, Vimeo, Riverside, MP4), route there instead.

## Known limits

- **X and other anti-bot platforms**: access and field coverage vary by endpoint, session, and time. Classify the actual response; do not assign a fixed coverage tier from the platform or price of the strategy.
- **LinkedIn**: browser access may expose profile activity while a specific post is gated; report the fields observed for the URL at hand.
- **Instagram / TikTok / Threads**: browser and metadata fallbacks may be sparse. Paid fallbacks can add fields but still require an observed-field check.
- **Bluesky / Mastodon / HN / Reddit**: their public APIs often expose rich fields, but actual coverage still wins over the platform default.
- **Private / deleted posts**: no strategy can supply fields that the service does not expose. Try Wayback Machine for deleted content and report the remaining gaps.

If a platform consistently fails on the available public/browser strategies and the user uses it often, prompt to set up the paid key (see `references/auth-keys.md`).

## Notes on quality

- **Strategy chain, not single-source.** Every platform has a fallback ladder documented in `references/strategies.md`. If one step fails or omits requested fields, degrade gracefully to the next permitted step and keep the best observed result.
- **Structured output over screenshots.** Downstream skills (jab-hook, deep-research, second-brain) need JSON with author + text + engagement fields, not an image. Even when the underlying strategy is a screenshot, extract text before returning.
- **Cache aggressively, invalidate honestly.** 24h TTL on `~/Documents/social-fetches/_cache/` prevents API burn when the same post is referenced across multiple skills in a session. `--with-replies` / `--thread` skip cache because replies age fast.
- **Respect paid-key economics.** ScrapeCreators / Apify calls cost real money. Confirm the requested depth before the first paid call, and never spend paid quota merely to turn an unverified partial response into an assumed complete one.
- **Media download is opt-in.** Default is post text only; `--media` downloads images/videos. Silent media downloads eat disk quickly.
- **Private / deleted content is a hard stop.** No strategy chain rescues private accounts or deleted posts. Suggest Wayback Machine for deleted content and stop.
- **Rate-limits are per-platform.** Public endpoints and browser sessions can hit rate limits or burn session fingerprints. Space out calls in loops or the workflow degrades to worse-than-manual.
