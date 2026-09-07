# Per-platform strategies

Each platform has 2–5 strategies tried in order. Start with an actually
available public API or browser strategy. Use a paid fallback only for a
requested depth, when its environment key is already configured, and classify
the response from the fields it actually contains.

---

## bluesky

**Reliability: high.** Public API, usually without authentication.

### Strategy 1 — Public AppView API (DEFAULT)

URL: `https://bsky.app/profile/<handle>/post/<rkey>`

```powershell
# Resolve handle → DID
$did = (Invoke-RestMethod -Uri 'https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=<handle>').did

# Build AT-URI and fetch the post + thread
$atUri = "at://$did/app.bsky.feed.post/<rkey>"
$encodedUri = [Uri]::EscapeDataString($atUri)
Invoke-RestMethod -Uri "https://public.api.bsky.app/xrpc/app.bsky.feed.getPostThread?uri=$encodedUri" |
  ConvertTo-Json -Depth 30
```

Returns the post + immediate parent + first-level replies in one call. Perfect for `--with-replies`.

---

## mastodon

**Reliability: high.** Public API, no auth for public statuses.

### Strategy 1 — Status endpoint

URL pattern: `https://<instance>/@<user>/<status-id>`

```powershell
# Single status
$headers = @{ Accept = 'application/json' }
Invoke-RestMethod -Headers $headers -Uri 'https://<instance>/api/v1/statuses/<status-id>' |
  ConvertTo-Json -Depth 30

# With replies
Invoke-RestMethod -Headers $headers -Uri 'https://<instance>/api/v1/statuses/<status-id>/context' |
  ConvertTo-Json -Depth 30
```

Note: instance and ID parsed from URL. Web URL `https://hachyderm.io/@user/123456` → API `https://hachyderm.io/api/v1/statuses/123456`.

---

## hn

**Reliability: high.** Public Algolia API.

### Strategy 1 — Algolia items API

URL pattern: `https://news.ycombinator.com/item?id=<id>`

```powershell
Invoke-RestMethod -Uri 'https://hn.algolia.com/api/v1/items/<id>' |
  ConvertTo-Json -Depth 30
```

Returns the item + full nested comment tree. Comments are recursive — flatten or limit depth per `--with-replies` flag.

---

## reddit

**Reliability: medium.** The `.json` suffix may work but is rate-limited per IP (~60 req/min).

### Strategy 1 — Append `.json` to URL

URL pattern: `https://www.reddit.com/r/<sub>/comments/<id>/<slug>/`

```powershell
$headers = @{ 'User-Agent' = 'social-fetch/0.1 (+https://example.invalid/social-fetch)' }
Invoke-RestMethod -Headers $headers -Uri '<url>.json' |
  ConvertTo-Json -Depth 30
```

Returns `[post, comments_tree]` as a 2-element array. Set a real User-Agent — Reddit blocks a default client UA.

### Strategy 2 — Wayback Machine fallback

If rate-limited or post deleted:

```powershell
$wayback = Invoke-RestMethod -Uri 'https://archive.org/wayback/available?url=<encoded-url>'
$wayback.archived_snapshots.closest.url
```

Returns Wayback URL — re-fetch from there.

---

## x (twitter)

**Reliability: variable.** X access and field coverage depend on the endpoint,
browser session, and current service behavior.

### Strategy 1 — available browser or API access

Use an available X endpoint or `agent-browser` session. Record which fields
were returned; a browser response can be complete for the requested post or
partial when the page withholds fields.

```powershell
agent-browser open "<url>"
Start-Sleep -Seconds 3
agent-browser snapshot 2>&1 | Select-Object -First 50
# Parse the returned text and metadata, then classify observed coverage
```

If a sign-up modal appears, dismiss it when the browser exposes a safe
interactive control and then re-check the returned fields.

### Strategy 2 — Nitter mirror (UNRELIABLE)

Nitter instances are frequently rate-limited or down. Try if running:

```powershell
# Pick a known-working instance (rotate if down)
$instances = @('nitter.net', 'nitter.lacontrevoie.fr', 'nitter.privacydev.net')
foreach ($instance in $instances) {
  try {
    $response = Invoke-WebRequest -Uri "https://$instance/<user>/status/<id>"
    if ($response.StatusCode -eq 200) {
      $response.Content
      break
    }
  } catch {
    # Try the next mirror.
  }
}
```

### Strategy 3 — Wayback Machine

```powershell
$wayback = Invoke-RestMethod -Uri 'https://archive.org/wayback/available?url=https://twitter.com/<user>/status/<id>'
$wayback.archived_snapshots.closest.url
```

Older tweets often cached; recent ones rarely.

### Strategy 4 — ScrapeCreators API (PAID, recommended for X)

Requires `$env:SCRAPECREATORS_API_KEY`. If unset, stop at the paid boundary and
surface the setup path; do not silently create a paid call.

```powershell
$headers = @{ 'x-api-key' = $env:SCRAPECREATORS_API_KEY }
Invoke-RestMethod -Headers $headers -Uri 'https://api.scrapecreators.com/v1/twitter/tweet?url=<encoded-url>' |
  ConvertTo-Json -Depth 30
```

Endpoint exact path may differ — verify in ScrapeCreators docs on first use.

### Strategy 5 — Apify scraper (PAID)

Requires `$env:APIFY_API_TOKEN`. Use the `apify/twitter-scraper` actor or a community equivalent.

```powershell
$body = @{ tweetUrls = @('<url>'); maxItems = 1 } | ConvertTo-Json
Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $body `
  -Uri "https://api.apify.com/v2/acts/<actor-id>/run-sync-get-dataset-items?token=$($env:APIFY_API_TOKEN)" |
  ConvertTo-Json -Depth 30
```

---

## linkedin

**Reliability: medium.** agent-browser works for some content.

### Strategy 1 — agent-browser + dismiss modal

```powershell
agent-browser open "<url>"
Start-Sleep -Seconds 3
# Detect signup modal and dismiss
agent-browser snapshot -i 2>&1 | Select-Object -First 20
# If first interactive element is "Dismiss" button:
agent-browser click '@e1'
Start-Sleep -Seconds 2
agent-browser snapshot 2>&1 | Select-Object -First 100
```

Works well for `linkedin.com/in/<handle>` profile pages (recent activity feed visible).
Specific post URLs (`linkedin.com/posts/...`) usually require login — fall through.

### Strategy 2 — ScrapeCreators API (PAID)

```powershell
$headers = @{ 'x-api-key' = $env:SCRAPECREATORS_API_KEY }
Invoke-RestMethod -Headers $headers -Uri 'https://api.scrapecreators.com/v1/linkedin/post?url=<encoded-url>' |
  ConvertTo-Json -Depth 30
```

### Strategy 3 — Apify (PAID)

Use `apify/linkedin-profile-scraper` or `apify/linkedin-post-scraper` actor.

---

## instagram

**Reliability: variable.** Heavy anti-bot behavior can make browser and metadata responses sparse.

### Strategy 1 — Open Graph fallback (LIMITED — just description/image)

```powershell
$page = Invoke-WebRequest -UserAgent 'Mozilla/5.0 social-fetch/0.1' -Uri '<url>'
[regex]::Matches($page.Content, '<meta.+?property="og:(title|description|image)".+?content="(.*?)"') |
  ForEach-Object { $_.Groups[1].Value + ': ' + $_.Groups[2].Value }
```

Returns metadata only. No engagement counts. Often blocked.

### Strategy 2 — ScrapeCreators API (PAID, recommended for IG)

```powershell
$headers = @{ 'x-api-key' = $env:SCRAPECREATORS_API_KEY }
Invoke-RestMethod -Headers $headers -Uri 'https://api.scrapecreators.com/v1/instagram/post?url=<encoded-url>' |
  ConvertTo-Json -Depth 30
```

### Strategy 3 — Apify (PAID)

Use `apify/instagram-scraper` actor.

---

## tiktok

**Reliability: variable.** Browser and metadata access can be sparse.

### Strategy 1 — Open Graph fallback (LIMITED)

```powershell
$page = Invoke-WebRequest -UserAgent 'Mozilla/5.0 social-fetch/0.1' -Uri '<url>'
[regex]::Matches($page.Content, '<meta.+?property="og:(title|description|video)".+?content="(.*?)"') |
  ForEach-Object { $_.Groups[1].Value + ': ' + $_.Groups[2].Value }
```

### Strategy 2 — ScrapeCreators API (PAID)

```powershell
$headers = @{ 'x-api-key' = $env:SCRAPECREATORS_API_KEY }
Invoke-RestMethod -Headers $headers -Uri 'https://api.scrapecreators.com/v1/tiktok/video?url=<encoded-url>' |
  ConvertTo-Json -Depth 30
```

### Strategy 3 — Apify (PAID)

Use `apify/tiktok-scraper` actor.

---

## threads

**Reliability: variable.** Meta's anti-bot behavior can make browser and metadata access sparse.

### Strategy 1 — Open Graph fallback (LIMITED)

```powershell
$page = Invoke-WebRequest -UserAgent 'Mozilla/5.0 social-fetch/0.1' -Uri '<url>'
[regex]::Matches($page.Content, '<meta.+?property="og:(title|description)".+?content="(.*?)"') |
  ForEach-Object { $_.Groups[1].Value + ': ' + $_.Groups[2].Value }
```

### Strategy 2 — ScrapeCreators API (PAID, if supported)

Check ScrapeCreators docs for Threads endpoint — coverage varies.

### Strategy 3 — Apify (PAID)

Use a Threads scraper actor (search Apify marketplace).

---

## Strategy chain summary

| Platform | Public/browser strategies | Paid fallback (only at the requested-depth boundary) |
|---|---|---|
| bluesky | Direct API | — |
| mastodon | Direct API | — |
| hn | Algolia API | — |
| reddit | `.json` suffix → Wayback | — |
| x | agent-browser → Nitter → Wayback | ScrapeCreators → Apify |
| linkedin | agent-browser (modal dismiss) | ScrapeCreators → Apify |
| instagram | OG tags | ScrapeCreators → Apify |
| tiktok | OG tags | ScrapeCreators → Apify |
| threads | OG tags | ScrapeCreators → Apify |
