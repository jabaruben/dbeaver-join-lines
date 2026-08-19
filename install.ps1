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


$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Repo = Join-Path $PackageRoot "repository"

if (-not (Test-Path $Repo)) {
    throw "The repository folder is missing next to install.ps1."
}

if (Get-Process dbeaver -ErrorAction SilentlyContinue) {
    throw "Close DBeaver before installing the plugin."
}

$DBeaverExe = Resolve-DBeaverExecutable -DBeaverHome $DBeaverHome
$RepoUri = Convert-ToFileUri $Repo
$IU = "io.github.jabaruben.dbeaver.joinlines.feature.feature.group"

Write-Host "Installing DBeaver Join Lines..."
& $DBeaverExe `
    -nosplash `
    -application org.eclipse.equinox.p2.director `
    -repository $RepoUri `
    -installIU $IU

if ($LASTEXITCODE -ne 0) {
    throw "Installation failed with exit code $LASTEXITCODE."
}

Write-Host "DBeaver Join Lines installed successfully."
