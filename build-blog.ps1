param(
    [switch]$BuildMD,
    [switch]$DeleteOrphanHTML,
    [switch]$DeleteOrphanMD,
    [switch]$DeleteCorresponding,
    [switch]$ListCorresponding,
    [switch]$DeleteNonCorresponding,
    [switch]$CopyFiles
)

<# **Sam's Static Site Generator**

##TODO##
    - Filter out .obsidian and other hidden folder - see Where-Object below; see how trustworthy that is.
    - Set correct permissions and filter correct files for export to host
    - Investigate Markdig further; see if it handles Wikilinks better
    - Add option to move orphaned files to new directory
#>

# Set Progress Bar Style to popup
$PSStyle.Progress.View = 'Classic'

$Blog = 'C:\Users\Samag\Downloads\test'
$OutDir = Join-Path $Blog 'output'
$InDir = Join-Path $Blog 'input'

$UpdatedObjects = @()
$MissingHTMLFiles = @()
$MatchedObjects = @()

# Create output directory if it doesn't exist
if (!(Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir
}

# Find each item in InDir
Get-ChildItem $InDir -Recurse | 
Where-Object { $_.FullName -notmatch "\\\..*\\?"} | 
ForEach-Object -Process {
    # Get subpath of InDir, combine with OutDir for new object location
    $RelativePath = $_.FullName.Substring($InDir.Length + 1)
    $OutNewFile = Join-Path $OutDir $RelativePath
    $OutNewObject = Get-Item $OutNewFile -ErrorAction SilentlyContinue
    
    # Check if object is either missing or older than the original file
    if (!$OutNewObject -or $OutNewObject.LastWriteTimeUtc -lt $_.LastWriteTimeUtc) {
        Write-Host "Old or missing file; adding to list $($_.Name) -> $OutNewFile"  -ForegroundColor Yellow
        $UpdatedObjects += $_
    } else { 
        Write-Host "No changes to $($OutNewObject.BaseName) detected, skipping."  -ForegroundColor Yellow
    }
}


Write-Host "Updated or new objects in InDir ($($UpdatedObjects.Length)): "  -ForegroundColor Yellow
$UpdatedObjects | Format-Table Name, FullName -AutoSize -HideTableHeaders

<# Match items to either a) existing files in $InDir b) .md files that correspond
to built HTML files; will flag any non-matching MD/non-md files and ignore
matching HTML files; ##TODO## add feature to ignore list of hand-built HTML
files (Better the keep them in input dir, and skip MD processing? Add to
server separately from files built by this program?). 

Also add ability to get table view of both sets of files and what they match
with #>

# Find all objects in out dir
$OutObjects = Get-ChildItem $OutDir -Recurse

# Find matching item in in dir, if it exists
$OutObjects | 
ForEach-Object -Process {
    # Get subpath of OutDir, combine with InDir for old object location
    $RelativePath = $_.FullName.Substring($OutDir.Length + 1)
    $InOldFile = Join-Path $InDir $RelativePath

    # Find any files in OutDir that have matching item in InDir
    $InOldObject = Get-Item $InOldFile -ErrorAction SilentlyContinue
    if ($InOldObject) {
        $MatchedObjects += $_
    }
    
    # Find HTML files that have a corresponding MD file in InDir
    if ( $_.Extension -eq ".html" ) {
        $ExpectedMDObject = Get-Item (Join-Path $_.Directory "$($_.BaseName).md") -ErrorAction SilentlyContinue
        if ($ExpectedMDObject) {
            $MatchedObjects += $_
        }
    }

    # Find MD files in OutDir with missing HTML
    if ( $_.Extension -eq ".md" ) {
        $ExpectedHTMLObject = Get-Item (Join-Path $_.Directory "$($_.BaseName).html") -ErrorAction SilentlyContinue
        if (!$ExpectedHTMLObject) {
            $MissingHTMLFiles += $_
        }
    }
}
$NonCorresponding = $OutObjects | Where-Object { $MatchedObjects -NotContains $_ }

Write-Host "Corresponding Files ($($MatchedObjects.Length)): "  -ForegroundColor Yellow
$MatchedObjects | Format-Table Name, FullName -AutoSize -HideTableHeaders

Write-Host "Non-Corresponding Files ($($NonCorresponding.Length)): "  -ForegroundColor Yellow
$NonCorresponding | Format-Table Name, FullName -AutoSize -HideTableHeaders

Write-Host ".md files in OutDir with missing HTML ($($MissingHTMLFiles.Length)): "  -ForegroundColor Yellow
$MissingHTMLFiles | Format-Table Name, FullName -AutoSize -HideTableHeaders

$BuildList = $MissingHTMLFiles

Write-Host "Current Build List ($($BuildList.Length)): "  -ForegroundColor Yellow
$BuildList | Format-Table Name, FullName -AutoSize -HideTableHeaders

### Everything below here should be commands/not alter data structures
# -DeleteCorresponding - Delete anything that already exists in the input
# directy for a clean build
if ($DeleteCorresponding) {
    $MatchedObjects | 
    Where-Object {!(Test-Path $_ -PathType Container)} | 
    Sort-Object FullName -Unique | 
    ForEach-Object -Process {
        Write-Host "Deleting $($_.FullName) - Exists in InDir"
        Remove-Item $_
    }
    $MatchedObjects | 
    Where-Object {(Test-Path $_ -PathType Container)} | 
    Sort-Object FullName -Unique | 
    ForEach-Object -Process {
        Write-Host "Deleting $($_.FullName) Folder if empty - Exists in InDir"
        $Children = Get-ChildItem $_ -ErrorAction SilentlyContinue
        if (!$Children) { Remove-Item $_ }
    }
}

# -DeleteNonCorresponding - Delete anything that **doesn't** already exist in InDir for a clean build
if ($DeleteNonCorresponding) {
    $NonCorresponding | 
    Where-Object {!(Test-Path $_ -PathType Container)} | 
    Sort-Object FullName -Unique | 
    ForEach-Object -Process {
        Write-Host "Deleting $($_.FullName) - No matching .md, and/or missing from InDir"
        Remove-Item $_
    }
    
    $NonCorresponding | 
    Where-Object {(Test-Path $_ -PathType Container)} | 
    Sort-Object FullName -Unique | 
    ForEach-Object -Process {
        Write-Host "Deleting $($_.FullName) folder if empty - no matching InDir subfolder"
        $Children = Get-ChildItem $_ -ErrorAction SilentlyContinue
        if (!$Children) { Remove-Item $_ }
    }
}

# -DeleteOrphanHTML - Removes any OutDir .html files that don't have a source .md
if ($DeleteOrphanHTML) {
    $NonCorresponding | Where-Object { $_.Extension -eq ".html" } | ForEach-Object {
        Write-Host "Deleting $($_.FullName)"
        Remove-Item $_
    }
}

# -DeleteOrphanMD - Removes any OutDir .md files that don't have an InDir .md
if ($DeleteOrphanMD) {
    $NonCorresponding | Where-Object { $_.Extension -eq ".md" } | ForEach-Object {
        Write-Host "Deleting $($_.FullName)"
        Remove-Item $_
    }
}

# -CopyFiles - Copy new or changed files from InDir. Note duplicated process for
# finding destination path.
if ($CopyFiles) {
    $UpdatedObjects | ForEach-Object {
        $RelativePath = $_.FullName.Substring($InDir.Length + 1)
        $OutNewFile = Join-Path $OutDir $RelativePath
        Copy-Item -Path $_ -Destination $OutNewFile -Container -Force
        $OutNewObject = Get-Item $OutNewFile
        # Check whether object is file or folder - folders can be skipped
        if (!(Test-Path $OutNewObject -PathType Container)) {
            Write-Host "$($OutNewObject.BaseName) is a file - adding to modified list"  -ForegroundColor Yellow
            $BuildList += $OutNewObject
        } else {
            Write-Host "$($OutNewObject.BaseName) is a folder - no further action neccessary"  -ForegroundColor Yellow
        }
    }
    Write-Host "Current Build List (After copy completion) ($($BuildList.Length)): "  -ForegroundColor Yellow
    $BuildList | Format-Table Name, FullName -AutoSize -HideTableHeaders   
}

# -BuildMD command line option - build HTML file for every MD file.
<# Build .html file for each modified or new .md file, or any that are missing
a corresponding .html file; deduplicate before running. Ignores images, etc.
##TODO## Choose what to do with orphaned .MD files - right now, they're removed
from the set of files to build #>
if ($BuildMD) {
    Write-Host "Current Build List (before BuildMD) ($($BuildList.Length)): "  -ForegroundColor Yellow
    $BuildList | Format-Table Name, FullName -AutoSize -HideTableHeaders
    $MDList = $BuildList | 
    Sort-Object FullName -Unique |
    Where-Object { $_.Extension -eq ".md" } |
    Where-Object { $_ -NotIn $NonCorresponding.FullName }
    Write-Host "Current Build List after filtering ($($MDList.Length)): "  -ForegroundColor Yellow
    $MDList | Format-Table Name, FullName -AutoSize -HideTableHeaders

    $MDList | ForEach-Object -Begin { 
        Write-Progress -Activity "Starting MD processing" -Status "START"
        $MDCounter = 0
    } -Process {
        $OutHTMLFile = Join-Path $_.Directory "$($_.BaseName).html"
        pandoc --defaults $Blog\pandoc.yaml -o $OutHTMLFile $_.fullname
        ++$MDCounter
        Write-Progress -Activity "Processing MD Files: " -CurrentOperation $OutHTMLFile -PercentComplete (( $MDCounter / $MDList.Count )*100) -Status "WORKING"
    } -End { 
        Write-Progress -Activity "Completed MD processing" -Status "END" -Completed
    }
}