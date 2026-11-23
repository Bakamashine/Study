param(
    [switch]$ClearDirectory,
    [switch]$CreateLatexProject,
    [switch]$AllBuildLatexProject,
    [string]$Directory,
    [string]$LabNumber,
    [switch]$Debug
)


function Write-DebugMsg {
    param([string]$Message)
    if ($Debug) {
        Write-Host "[debug] $Message"
    }
}

function checkIsNotExists {
  [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "The path '$Path' does not exist."
    }
    return $Path
}
$programsDir = Join-Path $PSScriptRoot 'Programs'
$compiledDir = Join-Path $programsDir 'Compiled'
$pdfMergerDir = Join-Path $compiledDir "PdfMerger"
$pdfMergerExe = Join-Path $pdfMergerDir 'PdfMerger.exe'
$texStylesDir = Join-Path $programsDir "texstyles"


Write-DebugMsg "programsDir: $programsDir"
Write-DebugMsg "compiledDir: $compiledDir"
Write-DebugMsg "pdfMergerExe: $pdfMergerExe"

checkIsNotExists $programsDir
checkIsNotExists $compiledDir
checkIsNotExists $pdfMergerExe

function Ask {
param ([string] $val, $desc)
    Write-DebugMsg " [Ask] $val"
    if (-not $val) {
        return Read-Host "$desc : "
    }
    return $val
}

function AskPath {
param (
# [Parameter(Mandatory = $true)]
[string] $val, $desc)
    Write-DebugMsg " [Ask] $val"
    if (!$val) {
        $t = Read-Host "$desc : "
        checkIsNotExists $t
        return $t
    }
    return $val
}

if ($AllBuildLatexProject) {
    $Directory = AskPath $Directory "Directory"
    $mainFile = Join-Path $Directory "main.tex"
    $gostStyle = Join-Path $Directory "gost.sty"
    if ((Test-Path $mainFile) -and (Test-Path $gostStyle)) {
        Set-Location $Directory
        try {
            make
            if ($LASTEXITCODE -ne 0) {
                throw "Makefile returned $LASTEXITCODE with error"
            }
        } finally {
            Pop-Location
        }

        Set-Location $PSScriptRoot 
        $mainPdf = Join-Path $Directory "main.pdf"
        $titlePdf = Join-Path $Directory "title.pdf"
        checkIsNotExists $mainPdf
        checkIsNotExists $titlePdf
        & $pdfMergerExe "$mainPdf" "$titlePdf"
        if ($LASTEXITCODE -ne 0) {
            throw "PDF Merger failed. Exit code: $LASTEXITCODE"
        }
        $outputPdf = Join-Path $pdfMergerDir "merged.pdf"
        if (-not (Test-Path $outputPdf)) {
            $outputPdf = Join-Path $PSScriptRoot "merged.pdf"
        }
        Copy-Item $outputPdf $Directory -Force
    }
}

if ($CreateLatexProject) {
    $Directory = AskPath $Directory "Directory"
    $LabNumber = Ask $LabNumber "NewLabName"
    $newDir = Join-Path $Directory ($LabNumber + "lab")
    New-Item -ItemType Directory $newDir
    $gostFile = Join-Path $texStylesDir "gost.sty"
    $mainFile = Join-Path $texStylesDir "main.tex"
    $makefile = Join-Path $texStylesDir "Makefile"
    $images = Join-Path $texStylesDir "img"
    checkIsNotExists $mainFile
    checkIsNotExists $gostFile
    checkIsNotExists $makefile
    Copy-Item $mainFile $newDir
    Copy-item $gostFile $newDir
    Copy-Item $makefile $newDir
    Copy-Item -Recurse $images $newDir 
}
