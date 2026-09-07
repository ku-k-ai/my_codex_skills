#requires -Version 7.0
<#
.SYNOPSIS
  A wizard walks a human through a manual procedure, step by step.

Everything above the "STAGES" marker is the wizard library: do not hand-edit
it after copying. Author the per-step stages below the marker.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Wizard library: the PowerShell counterpart to template.sh.
$script:TotalStages = 0
$script:StageIndex = 0
$script:EnvFile = if ($env:ENV_FILE) { $env:ENV_FILE } else { '.env' }
$script:WrittenEnv = [System.Collections.Generic.List[string]]::new()
$script:WrittenSecret = [System.Collections.Generic.List[string]]::new()
$script:Skipped = [System.Collections.Generic.List[string]]::new()

function Clear-WizardScreen {
  if (-not [Console]::IsOutputRedirected) {
    Clear-Host
  }
}

function Write-WizardLine {
  param(
    [Parameter(Mandatory)][string]$Text,
    [ConsoleColor]$Color = [ConsoleColor]::Gray
  )
  Write-Host $Text -ForegroundColor $Color
}

function Pause-Wizard {
  param([string]$Message = 'Press Enter to continue')
  [void](Read-Host "  $Message")
}

function Banner {
  param([Parameter(Mandatory)][string]$Title)
  Clear-WizardScreen
  Write-WizardLine "`n  $Title" Cyan
  Write-WizardLine "  $script:TotalStages stages`n" DarkGray
  Write-WizardLine '  You drive the browser; this wizard tells you exactly what to do and' DarkGray
  Write-WizardLine '  captures the values you copy back. Stop any time with Ctrl-C and re-run' DarkGray
  Write-WizardLine '  later, since it remembers values already saved.' DarkGray
  Pause-Wizard 'Ready to start?'
}

function Stage {
  param([Parameter(Mandatory)][string]$Name)
  Clear-WizardScreen
  $script:StageIndex++
  Write-WizardLine "`n  > Stage $script:StageIndex/$script:TotalStages · $Name`n" Cyan
}

function Say  { param([Parameter(Mandatory)][string]$Message) Write-WizardLine "  $Message" Gray }
function Step { param([Parameter(Mandatory)][string]$Message) Write-WizardLine "  • $Message" Cyan }
function Note { param([Parameter(Mandatory)][string]$Message) Write-WizardLine "  $Message" DarkGray }
function Warn { param([Parameter(Mandatory)][string]$Message) Write-WizardLine "  ⚠ $Message" Yellow }

function Open-Url {
  param([Parameter(Mandatory)][Uri]$Url)
  Write-WizardLine "  ↗ opening $($Url.AbsoluteUri)" Green
  try {
    if ($IsWindows) {
      Start-Process -FilePath $Url.AbsoluteUri | Out-Null
      return
    }

    $opener = Get-Command 'xdg-open' -ErrorAction SilentlyContinue
    if (-not $opener) { $opener = Get-Command 'open' -ErrorAction SilentlyContinue }
    if ($opener) {
      & $opener.Source $Url.AbsoluteUri *> $null
      if ($LASTEXITCODE -ne 0) { throw "opener exited with code $LASTEXITCODE" }
      return
    }

    Warn "couldn't open a browser; visit it manually: $($Url.AbsoluteUri)"
  } catch {
    Warn "couldn't open a browser, so visit it manually: $($Url.AbsoluteUri)"
  }
}

function Confirm-Wizard {
  param([Parameter(Mandatory)][string]$Question)
  $reply = Read-Host "  ? $Question [y/N]"
  return $reply -match '^[Yy]$'
}

function ConvertFrom-DotEnvValue {
  param(
    [Parameter(Mandatory)][AllowEmptyString()][string]$RawValue
  )
  if ($RawValue.Length -lt 2) { return $RawValue }

  $first = $RawValue[0]
  $last = $RawValue[$RawValue.Length - 1]
  if (($first -eq "'" -and $last -eq "'") -or ($first -eq '"' -and $last -eq '"')) {
    $inner = $RawValue.Substring(1, $RawValue.Length - 2)
    if ($first -eq "'") { return $inner }

    # Decode only the three writer escapes. Everything else stays literal;
    # dotenv text is data and is never expanded or executed.
    $builder = [Text.StringBuilder]::new()
    for ($index = 0; $index -lt $inner.Length; $index++) {
      $character = $inner[$index]
      if ($character -eq '\' -and ($index + 1) -lt $inner.Length) {
        $next = $inner[$index + 1]
        if ($next -eq '\' -or $next -eq '"' -or $next -eq '$') {
          [void]$builder.Append($next)
          $index++
          continue
        }
      }
      [void]$builder.Append($character)
    }
    return $builder.ToString()
  }
  return $RawValue
}

function ConvertTo-DotEnvValue {
  param(
    [Parameter(Mandatory)][AllowEmptyString()][string]$Value
  )
  if ($Value.Contains("`r") -or $Value.Contains("`n")) { throw 'dotenv values must be one line' }

  $needsQuotes = $Value.Length -eq 0
  foreach ($character in $Value.ToCharArray()) {
    if ([char]::IsWhiteSpace($character) -or $character -eq '#' -or $character -eq "'" -or $character -eq '"' -or $character -eq '\' -or $character -eq '$') {
      $needsQuotes = $true
      break
    }
  }
  if (-not $needsQuotes) { return $Value }

  # Double quotes make spaces, #, quotes, backslashes, and literal $ stable
  # across a read/write round trip. The parser above decodes these escapes
  # without invoking a shell or expanding an environment variable.
  $escaped = $Value.Replace('\', '\\').Replace('"', '\"').Replace('$', '\$')
  return '"' + $escaped + '"'
}

function Get-ExistingEnvValue {
  param([Parameter(Mandatory)][string]$Key)
  if (-not (Test-Path -LiteralPath $script:EnvFile -PathType Leaf)) { return $null }
  $resolved = (Resolve-Path -LiteralPath $script:EnvFile).Path
  $value = $null
  foreach ($line in [IO.File]::ReadLines($resolved)) {
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2 -and $parts[0].Trim() -eq $Key) {
      $value = ConvertFrom-DotEnvValue $parts[1]
    }
  }
  return $value
}

function Ask {
  param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Prompt
  )
  $current = Get-ExistingEnvValue $Key
  $suffix = if ($null -ne $current -and $current.Length -gt 0) { ' [Enter keeps current]' } else { '' }
  $inputValue = Read-Host "  $Prompt$suffix"
  if ([string]::IsNullOrEmpty($inputValue) -and $null -ne $current) { $inputValue = $current }
  return $inputValue
}

function ConvertFrom-SecureInput {
  param([Parameter(Mandatory)][Security.SecureString]$SecureValue)
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
}

function Ask-Secret {
  param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Prompt
  )
  $current = Get-ExistingEnvValue $Key
  $suffix = if ($null -ne $current -and $current.Length -gt 0) { ' [Enter keeps current]' } else { '' }
  $secureValue = Read-Host "  $Prompt$suffix" -AsSecureString
  $inputValue = ConvertFrom-SecureInput $secureValue
  if ([string]::IsNullOrEmpty($inputValue) -and $null -ne $current) { $inputValue = $current }
  return $inputValue
}

function Write-Env {
  param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][AllowEmptyString()][string]$Value
  )
  if ($Key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw "invalid .env key: $Key" }
  if ($Value.Contains("`r") -or $Value.Contains("`n")) { throw "value for $Key must be one line" }

  $envPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($script:EnvFile)
  if (Test-Path -LiteralPath $envPath -PathType Leaf) {
    $lines = [IO.File]::ReadAllLines($envPath)
  } else {
    $lines = @()
  }
  $output = [System.Collections.Generic.List[string]]::new()
  foreach ($line in $lines) {
    $parts = $line -split '=', 2
    if ($parts.Count -ne 2 -or $parts[0].Trim() -ne $Key) { [void]$output.Add($line) }
  }
  [void]$output.Add("$Key=$(ConvertTo-DotEnvValue $Value)")
  [IO.File]::WriteAllLines($envPath, $output.ToArray(), [Text.UTF8Encoding]::new($false))
  [void]$script:WrittenEnv.Add($Key)
  Write-WizardLine "  ✓ wrote $Key → $script:EnvFile" Green
}

function Set-Secret {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][AllowEmptyString()][string]$Value
  )
  $gh = Get-Command 'gh' -ErrorAction SilentlyContinue
  if ($gh) {
    & $gh.Source auth status *> $null
    if ($LASTEXITCODE -eq 0) {
      $Value | & $gh.Source secret set $Name *> $null
      if ($LASTEXITCODE -eq 0) {
        [void]$script:WrittenSecret.Add($Name)
        Write-WizardLine "  ✓ set GitHub secret $Name" Green
        return
      }
    }
  }
  [void]$script:Skipped.Add("GitHub secret $Name (set it manually: gh secret set $Name)")
  Warn "skipped GitHub secret ${Name}: gh not ready; set it later"
}

function Set-Var {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][AllowEmptyString()][string]$Value
  )
  $gh = Get-Command 'gh' -ErrorAction SilentlyContinue
  if ($gh) {
    & $gh.Source auth status *> $null
    if ($LASTEXITCODE -eq 0) {
      & $gh.Source variable set $Name --body $Value *> $null
      if ($LASTEXITCODE -eq 0) {
        Write-WizardLine "  ✓ set GitHub variable $Name" Green
        return
      }
    }
  }
  [void]$script:Skipped.Add("GitHub variable $Name")
  Warn "skipped GitHub variable ${Name}: gh not ready; set it later"
}

function Finish {
  Clear-WizardScreen
  if ($script:Skipped.Count -gt 0) {
    Write-WizardLine "`n  Wizard finished with manual follow-up" Yellow
  } else {
    Write-WizardLine "`n  ✓ Setup complete" Green
  }
  if ($script:WrittenEnv.Count -gt 0) { Note "wrote $($script:WrittenEnv.Count) value(s) to ${script:EnvFile}: $($script:WrittenEnv -join ', ')" }
  if ($script:WrittenSecret.Count -gt 0) { Note "set $($script:WrittenSecret.Count) GitHub secret(s): $($script:WrittenSecret -join ', ')" }
  if ($script:Skipped.Count -gt 0) {
    Write-Host ''
    Warn 'still to do by hand:'
    foreach ($item in $script:Skipped) { Note "  - $item" }
  }
  Write-Host ''
}

# ──────────────────────────────────────────────────────────────────────────
# STAGES: author this section. One Stage per step the human takes.
# Replace the example below. Set $script:TotalStages to match your stages.
# ──────────────────────────────────────────────────────────────────────────

$script:TotalStages = 1

Banner 'Stripe setup'

# ── Example stage: replace with your real steps ───────────────────────────
Stage 'Stripe: API keys'
Say "We'll grab your Stripe test keys and store them for local dev + CI."
Open-Url 'https://dashboard.stripe.com/test/apikeys'
Step 'On the API keys page, copy the Publishable key (starts pk_test_).'
$StripePublishableKey = Ask 'STRIPE_PUBLISHABLE_KEY' 'Paste the publishable key:'
Step "Click 'Reveal test key' on the Secret key row, then copy it."
$StripeSecretKey = Ask-Secret 'STRIPE_SECRET_KEY' 'Paste the secret key:'
Write-Env 'STRIPE_PUBLISHABLE_KEY' $StripePublishableKey
Write-Env 'STRIPE_SECRET_KEY' $StripeSecretKey
Set-Secret 'STRIPE_SECRET_KEY' $StripeSecretKey
# ──────────────────────────────────────────────────────────────────────────

Finish
