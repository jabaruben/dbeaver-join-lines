param(
    [string]$DBeaverHome
)

$ErrorActionPreference = "Stop"

function Resolve-DBeaverExecutable {
    param([string]$DBeaverHome)

    $candidates = @()

    if ($DBeaverHome) {
        $candidates += (Join-Path $DBeaverHome "dbeaverc.exe")
        $candidates += (Join-Path $DBeaverHome "dbeaver.exe")
    }

    $candidates += "$env:LOCALAPPDATA\DBeaver\dbeaverc.exe"
    $candidates += "$env:LOCALAPPDATA\DBeaver\dbeaver.exe"
    $candidates += "$env:ProgramFiles\DBeaver\dbeaverc.exe"
    $candidates += "$env:ProgramFiles\DBeaver\dbeaver.exe"
    $candidates += "${env:ProgramFiles(x86)}\DBeaver\dbeaverc.exe"
    $candidates += "${env:ProgramFiles(x86)}\DBeaver\dbeaver.exe"

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }

    throw "DBeaver was not found. Use -DBeaverHome 'C:\Path\To\DBeaver'."
}

function Convert-ToFileUri {
    param([string]$Path)
    return ([System.Uri]::new((Resolve-Path $Path).Path)).AbsoluteUri
}


if (Get-Process dbeaver -ErrorAction SilentlyContinue) {
    throw "Close DBeaver before uninstalling the plugin."
}

$DBeaverExe = Resolve-DBeaverExecutable -DBeaverHome $DBeaverHome
$IU = "io.github.jabaruben.dbeaver.joinlines.feature.feature.group"

Write-Host "Uninstalling DBeaver Join Lines..."
& $DBeaverExe `
    -nosplash `
    -application org.eclipse.equinox.p2.director `
    -uninstallIU $IU

if ($LASTEXITCODE -ne 0) {
    throw "Uninstallation failed with exit code $LASTEXITCODE."
}

Write-Host "DBeaver Join Lines uninstalled successfully."
