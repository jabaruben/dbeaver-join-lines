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

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must use semantic version format X.Y.Z (for example 1.0.1)."
}

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DBeaverExe = Resolve-DBeaverExecutable -DBeaverHome $DBeaverHome

if (Get-Process dbeaver -ErrorAction SilentlyContinue) {
    throw "Close DBeaver before building the p2 repository."
}

$BuildRoot = Join-Path $ProjectRoot "build"
$Site = Join-Path $BuildRoot "site"
$Repo = Join-Path $BuildRoot "repository"
$Generated = Join-Path $BuildRoot "generated"
$Dist = Join-Path $ProjectRoot "dist"

Remove-Item $BuildRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $Dist -Recurse -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force (Join-Path $Site "plugins") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $Site "features") | Out-Null
New-Item -ItemType Directory -Force $Repo | Out-Null
New-Item -ItemType Directory -Force $Generated | Out-Null
New-Item -ItemType Directory -Force $Dist | Out-Null

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$BundleId = "io.github.jabaruben.dbeaver.joinlines"
$FeatureId = "io.github.jabaruben.dbeaver.joinlines.feature"

# Generate versioned metadata without modifying the source tree.
$ManifestSource = Join-Path $ProjectRoot "plugin\META-INF\MANIFEST.MF"
$ManifestGenerated = Join-Path $Generated "MANIFEST.MF"
(Get-Content $ManifestSource -Raw) `
    -replace '(?m)^Bundle-Version:\s*.*$', "Bundle-Version: $Version" |
    Set-Content $ManifestGenerated -Encoding ascii -NoNewline

$FeatureSource = Join-Path $ProjectRoot "feature\feature.xml"
$FeatureGenerated = Join-Path $Generated "feature.xml"
$featureContent = Get-Content $FeatureSource -Raw
$featureContent = $featureContent -replace 'version="\d+\.\d+\.\d+"', "version=`"$Version`""
$featureContent | Set-Content $FeatureGenerated -Encoding utf8

$CategorySource = Join-Path $ProjectRoot "category.xml"
$CategoryGenerated = Join-Path $Generated "category.xml"
$categoryContent = Get-Content $CategorySource -Raw
$categoryContent = $categoryContent -replace 'io\.github\.jabaruben\.dbeaver\.joinlines\.feature_\d+\.\d+\.\d+\.jar', "$FeatureId`_$Version.jar"
$categoryContent = $categoryContent -replace 'version="\d+\.\d+\.\d+"', "version=`"$Version`""
$categoryContent | Set-Content $CategoryGenerated -Encoding utf8

# Bundle JAR
$PluginJar = Join-Path $Site "plugins\$BundleId`_$Version.jar"
$PluginXml = Join-Path $ProjectRoot "plugin\plugin.xml"

$fs = [System.IO.File]::Open($PluginJar, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($spec in @(
        @{ Source = $ManifestGenerated; Entry = "META-INF/MANIFEST.MF" },
        @{ Source = $PluginXml; Entry = "plugin.xml" }
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

$fs = [System.IO.File]::Open($FeatureJar, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $entry = $zip.CreateEntry("feature.xml")
    $stream = $entry.Open()
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FeatureGenerated)
        $stream.Write($bytes, 0, $bytes.Length)
    } finally {
        $stream.Dispose()
    }
} finally {
    $zip.Dispose()
    $fs.Dispose()
}

$RepoUri = Convert-ToFileUri $Repo
$CategoryUri = Convert-ToFileUri $CategoryGenerated

Write-Host "Publishing features and bundles for version $Version..."
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
