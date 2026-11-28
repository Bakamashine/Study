<#
.SYNOPSIS
    Helper script for creating and building lab LaTeX projects.

.DESCRIPTION
    -CreateLatexProject scaffolds a new project from Programs\texstyles.
    -AllBuildLatexProject builds an existing project with make and merges
    main.pdf with title.pdf. Missing values are requested interactively.

.PARAMETER Help
    Displays help and exits without validating any paths.

.PARAMETER ClearDirectory
    Reserved for future use; currently does nothing.

.PARAMETER CreateLatexProject
    Create a new LaTeX project under -Directory.

.PARAMETER AllBuildLatexProject
    Build and merge an existing LaTeX project in -Directory.

.PARAMETER Directory
    Existing directory to work in. Prompted for when omitted.

.PARAMETER LabNumber
    Lab number; the new project directory is named '<LabNumber>lab'.

.PARAMETER Workname
    New project directory name when -LabNumber is not supplied.

.PARAMETER Debug
    Print debug messages.

.EXAMPLE
    .\artisan.ps1 -Help

.EXAMPLE
    .\artisan.ps1 -CreateLatexProject -Directory 'D:\Projects\Study' -LabNumber 2

.EXAMPLE
    .\artisan.ps1 -AllBuildLatexProject -Directory 'D:\Projects\Study\2lab'

.NOTES
    Use Get-Help .\artisan.ps1 -Full for the same information.
#>
param(
    [Alias('h')]
    [switch]$Help,
    [switch]$ClearDirectory,
    [switch]$CreateLatexProject,
    [switch]$AllBuildLatexProject,
    [string]$Directory,
    [string]$LabNumber,
    [string]$Workname,
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

function Show-Help {
    Write-Host @'
artisan.ps1 - helper for lab LaTeX projects

Usage:
  .\artisan.ps1 [-Help] [-CreateLatexProject | -AllBuildLatexProject]
                [-ClearDirectory] [-Directory <path>]
                [-LabNumber <n> | -Workname <name>] [-Debug]

Parameters:
  -Help, -h                 Show this help and exit.
  -CreateLatexProject       Create a new LaTeX project in -Directory from
                            Programs\texstyles.
  -AllBuildLatexProject     Run make in an existing project and merge
                            main.pdf with title.pdf into merged.pdf.
  -ClearDirectory           Reserved for future use; currently does nothing.
  -Directory <path>         Existing directory to work in; prompted for if omitted.
  -LabNumber <n>            Lab number; new project directory is '<n>lab'.
  -Workname <name>          New project directory name when -LabNumber is omitted;
                            prompted for if omitted too.
  -Debug                    Print debug messages.

Examples:
  .\artisan.ps1 -Help
  .\artisan.ps1 -CreateLatexProject -Directory 'D:\Projects\Study' -LabNumber 2
  .\artisan.ps1 -CreateLatexProject -Directory 'D:\Projects\Study' -Workname 'My lab'
  .\artisan.ps1 -AllBuildLatexProject -Directory 'D:\Projects\Study\2lab'

'@

    return
}

if ($Help) {
    Show-Help
    return
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
    $newDir = $null
    if (-not $LabNumber) {
        $Workname = Ask $Workname "Workname"
        $newDir = Join-Path $Directory $Workname
    } else {
        $newDir = Join-Path $Directory ($LabNumber + "lab")
    }
    
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
