# Command conventions and runtime fallback

> Adapted for Codex, 2026-09-08: runtime fallback and shell-portable command examples. Source: the original hatch-pet command blocks.

This reference applies whenever a route runs a bundled script. The skill root is the directory containing `SKILL.md`; every script path below is relative to that root. Resolve it once as an absolute `SKILL_DIR`, then pass absolute paths to the interpreter.

## Runtime selection

1. Call the Codex `load_workspace_dependencies` tool before running a script. Set `PYTHON` to the exact Python executable returned by that tool. The bundled runtime is preferred because it supplies the known Pillow dependency.
2. If the tool is unavailable or returns no usable Python, probe an existing interpreter instead of stopping immediately. A candidate is acceptable only when it is Python 3.10 or newer and `from PIL import Image` imports successfully:

   ```powershell
   $Candidates = @('python', 'py')
   $Python = $null
   foreach ($Candidate in $Candidates) {
       try {
           $Version = & $Candidate -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
           $VersionExit = $LASTEXITCODE
           $Pillow = & $Candidate -c "from PIL import Image; print('ok')" 2>$null
           $PillowExit = $LASTEXITCODE
           $VersionOk = $false
           if ($Version -match '^\s*\d+\.\d+\s*$') {
               $VersionOk = ([version]$Version.Trim() -ge [version]'3.10')
           }
           if ($VersionOk -and $VersionExit -eq 0 -and $PillowExit -eq 0 -and $Pillow -eq 'ok') {
               $Python = (& $Candidate -c "import sys; print(sys.executable)" 2>$null).Trim()
               break
           }
       } catch { }
   }
   if ($null -eq $Python) {
       throw 'No compatible Python with Pillow was found for hatch-pet scripts.'
   }
   ```

   Prefer a fully resolved executable path when a candidate is accepted. The absence of the bundled runtime is recoverable; a failed Python/Pillow probe is the actual dependency blocker. Do not install packages or change the environment as an implicit workaround.

## Shell choice

Confirm the shell before copying a command block. The `bash` blocks in the route references are POSIX examples and require a POSIX shell with the shown utilities. In PowerShell, use the PowerShell forms below or translate the whole invocation; do not paste POSIX variable expansion, command substitution, `jq`, `cp`, `rm`, or `mkdir` syntax unchanged.

### PowerShell setup and argument arrays

```powershell
$SkillDir = (Resolve-Path 'C:\path\to\hatch-pet').Path
$Python = 'C:\path\to\python.exe' # exact path from load_workspace_dependencies or the fallback probe
$RunDir = 'C:\path\to\run'
$PetArgs = @(
    (Join-Path $SkillDir 'scripts/prepare_pet_run.py')
    '--pet-name'; 'Example'
    '--description'; 'One sentence about the pet.'
    '--output-dir'; $RunDir
    '--pet-notes'; 'Stable visual identity and persona notes.'
    '--style-preset'; 'auto'
)
& $Python @PetArgs
if ($LASTEXITCODE -ne 0) { throw 'hatch-pet script failed.' }
```

Use one `@PetArgs` array per Python invocation. Put the script path first, preserve each flag/value as its own array item, and check `$LASTEXITCODE` before accepting output. For a script invocation that needs no additional flags, call `& $Python (Join-Path $SkillDir 'scripts/prepare_pet_run.py')` and still check `$LASTEXITCODE`.

### PowerShell equivalents for shell operations

| POSIX example | PowerShell form |
|---|---|
| `mkdir -p "$RunDir/qa"` | `New-Item -ItemType Directory -Force -Path (Join-Path $RunDir 'qa')` |
| `cp $Source $Destination` | `Copy-Item -LiteralPath $Source -Destination $Destination -Force` |
| `rm -f $Source` | `Remove-Item -LiteralPath $Source -Force` after checking the exact path |
| `dirname "$RunDir/$OutputRel"` | `[IO.Path]::GetDirectoryName((Join-Path $RunDir $OutputRel))` |
| `date -u +...` | `(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')` |
| `mktemp` | `Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())` |

Create destination directories before copying. Resolve and inspect cleanup targets before removing anything; the generated-image cleanup in the workflow is limited to the selected source and its now-empty containing directory.

### PowerShell JSON and manifest operations

When `jq` is unavailable, use PowerShell's JSON cmdlets for the parent-owned manifest and package operations. Keep the same fields and update only the selected job:

```powershell
$ManifestPath = Join-Path $RunDir 'imagegen-jobs.json'
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json -AsHashtable
$Job = @($Manifest.jobs) | Where-Object { $_.id -eq $JobId } | Select-Object -First 1
if ($null -eq $Job) { throw "Unknown job: $JobId" }
$Job['status'] = 'complete'
$Job['source_path'] = $Source
$Job['completed_at'] = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$Manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ManifestPath -Encoding utf8
```

For a read-only job listing:

```powershell
$Manifest = Get-Content -LiteralPath (Join-Path $RunDir 'imagegen-jobs.json') -Raw | ConvertFrom-Json
$Manifest.jobs | Select-Object id, kind, status, depends_on, prompt_file, retry_prompt_file, input_images, output_path, derivation_policy
```

Keep generated prompts, decoded images, QA reports, and manifests under the active run directory. The skill root supplies scripts and references; it is not the run-output directory.
