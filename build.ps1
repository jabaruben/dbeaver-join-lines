param(
    [string]$DBeaverHome,
    [string]$Version = "1.0.0"
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


$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DBeaverExe = Resolve-DBeaverExecutable -DBeaverHome $DBeaverHome

if (Get-Process dbeaver -ErrorAction SilentlyContinue) {
    throw "Close DBeaver before building the p2 repository."
}

$BuildRoot = Join-Path $ProjectRoot "build"
$Site = Join-Path $BuildRoot "site"
$Repo = Join-Path $BuildRoot "repository"
$Dist = Join-Path $ProjectRoot "dist"

Remove-Item $BuildRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $Dist -Recurse -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force (Join-Path $Site "plugins") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $Site "features") | Out-Null
New-Item -ItemType Directory -Force $Repo | Out-Null
New-Item -ItemType Directory -Force $Dist | Out-Null

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$BundleId = "io.github.jabaruben.dbeaver.joinlines"
$FeatureId = "io.github.jabaruben.dbeaver.joinlines.feature"

# Bundle JAR
$PluginJar = Join-Path $Site "plugins\$BundleId`_$Version.jar"
$PluginRoot = Join-Path $ProjectRoot "plugin"

$fs = [System.IO.File]::Open($PluginJar, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($spec in @(
        @{ Source = (Join-Path $PluginRoot "META-INF\MANIFEST.MF"); Entry = "META-INF/MANIFEST.MF" },
        @{ Source = (Join-Path $PluginRoot "plugin.xml"); Entry = "plugin.xml" }
    )) {
        $entry = $zip.CreateEntry($spec.Entry)
        $stream = $entry.Open()
        try {
            $bytes = [System.IO.File]::ReadAllBytes($spec.Source)
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Dispose()
        }
    }
} finally {
    $zip.Dispose()
    $fs.Dispose()
}

# Feature JAR
$FeatureJar = Join-Path $Site "features\$FeatureId`_$Version.jar"
$FeatureXml = Join-Path $ProjectRoot "feature\feature.xml"

$fs = [System.IO.File]::Open($FeatureJar, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $entry = $zip.CreateEntry("feature.xml")
    $stream = $entry.Open()
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FeatureXml)
        $stream.Write($bytes, 0, $bytes.Length)
    } finally {
        $stream.Dispose()
    }
} finally {
    $zip.Dispose()
    $fs.Dispose()
}

$RepoUri = Convert-ToFileUri $Repo
$CategoryUri = Convert-ToFileUri (Join-Path $ProjectRoot "category.xml")

Write-Host "Publishing features and bundles..."
& $DBeaverExe `
    -nosplash `
    -application org.eclipse.equinox.p2.publisher.FeaturesAndBundlesPublisher `
    -metadataRepository $RepoUri `
    -artifactRepository $RepoUri `
    -source $Site `
    -compress `
    -publishArtifacts

if ($LASTEXITCODE -ne 0) {
    throw "FeaturesAndBundlesPublisher exited with code $LASTEXITCODE."
}

Write-Host "Publishing category..."
& $DBeaverExe `
    -nosplash `
    -application org.eclipse.equinox.p2.publisher.CategoryPublisher `
    -metadataRepository $RepoUri `
    -categoryDefinition $CategoryUri `
    -compress

if ($LASTEXITCODE -ne 0) {
    throw "CategoryPublisher exited with code $LASTEXITCODE."
}

if (-not ((Test-Path (Join-Path $Repo "content.jar")) -or (Test-Path (Join-Path $Repo "content.xml")))) {
    throw "The p2 repository does not contain content.jar/content.xml."
}

$PackageDir = Join-Path $Dist "DBeaverJoinLines-$Version"
New-Item -ItemType Directory -Force $PackageDir | Out-Null
Copy-Item $Repo (Join-Path $PackageDir "repository") -Recurse
Copy-Item (Join-Path $ProjectRoot "install.ps1") $PackageDir
Copy-Item (Join-Path $ProjectRoot "uninstall.ps1") $PackageDir
Copy-Item (Join-Path $ProjectRoot "README-INSTALL.txt") $PackageDir
Copy-Item (Join-Path $ProjectRoot "LICENSE") $PackageDir

$PackageZip = Join-Path $Dist "DBeaverJoinLines-$Version-portable.zip"
Compress-Archive -Path "$PackageDir\*" -DestinationPath $PackageZip -Force

Write-Host ""
Write-Host "Build complete:"
Write-Host "  $PackageZip"
