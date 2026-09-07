# Auth keys — unlocking paid fallback strategies

Public APIs and browser strategies cover many cases. Paid keys add fallback capacity for X, LinkedIn, Instagram, TikTok, and Threads, but they do not guarantee complete data; completeness is determined from the fields actually returned.

## Which key unlocks what

| Key | Unlocks | Cost (approx, 2026) |
|---|---|---|
| `$SCRAPECREATORS_API_KEY` | X (tweets + threads + replies), LinkedIn posts, Instagram, TikTok, possibly Threads | Pay-as-you-go, ~$0.005–$0.02/post depending on endpoint |
| `$APIFY_API_TOKEN` | Nearly any platform via "Actors" (X, IG, TikTok, LinkedIn, Threads, even niche ones) | Per-actor pricing, often $1–$5 / 1K results |

## Setting up

### PowerShell 7 session

Use a secret manager for long-lived credentials when one is available. For a
one-session PowerShell setup, paste each key into a hidden prompt and verify
only that the variable is set:

```powershell
function Set-SessionSecret {
  param([Parameter(Mandatory)][string]$Name)
  $secure = Read-Host "Paste $Name" -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $value = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    Set-Item -Path "Env:$Name" -Value $value
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
}

Set-SessionSecret 'SCRAPECREATORS_API_KEY'
Set-SessionSecret 'APIFY_API_TOKEN'
if ($env:SCRAPECREATORS_API_KEY) { 'SCRAPECREATORS_API_KEY is set' }
if ($env:APIFY_API_TOKEN) { 'APIFY_API_TOKEN is set' }
```

The verification output must never include a key prefix or a character count.
On Windows, persist a value through the user environment only after the hidden
prompt has completed, then open a new PowerShell session:

```powershell
[Environment]::SetEnvironmentVariable('SCRAPECREATORS_API_KEY', $env:SCRAPECREATORS_API_KEY, 'User')
[Environment]::SetEnvironmentVariable('APIFY_API_TOKEN', $env:APIFY_API_TOKEN, 'User')
```

### ScrapeCreators

1. Sign up at https://scrapecreators.com
2. Get API key from dashboard
3. Set `SCRAPECREATORS_API_KEY` with the hidden PowerShell prompt above, or
   use the secret manager supported by the execution environment.
4. Open a new shell only after the secret manager has made the variable
   available; verify with the presence check above.

### Apify

1. Sign up at https://apify.com (free tier exists; pay-as-you-go after)
2. Get API token from Settings → Integrations → API
3. Set `APIFY_API_TOKEN` with the hidden PowerShell prompt above, or use the
   secret manager supported by the execution environment.
4. Open a new shell only after the secret manager has made the variable
   available; verify with the presence check above.

## Without paid keys

If neither key is set, try the available public API and browser strategies.
Some responses will be complete and others partial; record the fields actually
returned and list the missing requested fields. In particular, do not assign a
fixed coverage tier to an X response from the platform or assume that a paid
response is complete without checking it.

Paid fallback is useful when:
- Building corpus (deep-research running many fetches)
- Analyzing thread structure or reply trees on X
- Inspiration-account analysis on Instagram / TikTok (where public/browser access is often sparse)

## Cost discipline

When using paid strategies:
- Always check the cache first (`~/Documents/social-fetches/_cache/` if it exists)
- Default to 24h cache TTL
- Don't auto-enrich with `--with-replies` or `--thread` unless requested — these multiply quota use and cross the paid boundary when a paid strategy is required
- For high-volume work (e.g., fetching last 50 posts from an inspiration account), batch via Apify actors (cheaper per item) instead of ScrapeCreators per-call

## When to set up paid

Don't set up keys preemptively. Set them up when:
- A real workflow (deep-research, inspiration analysis, competitor monitoring) is being blocked
- You've done >10 fetches and the available public/browser strategies are missing data you need
- You're starting on `swipe-save` or another skill where social capture is central

If `social-fetch` falls through to "no paid key set" on the same platform 3+ times in a session, it'll surface a one-time prompt.
