# 1. Configuration
$ApiKey = '823afd74b1afc3240d4a135c5f88f29b'
$ParentFolder = 'P:\!encodedHolding'
#$VolumeName = "Monty Python and the Holy Grail" # Example DVD Volume Name
$Results = @()

# 2. Get all folders in the directory
$Folders = Get-ChildItem -Path $ParentFolder -Directory

foreach ($Folder in $Folders) {
    $FolderName = $Folder.Name

    if ($Folder.Name -like "*tmdb*") {
        continue
    }

    Write-Host "Searching for: $FolderName..."

    # 3. Clean the Folder Name
    # Removes years in brackets, underscores, and common file terms
    $CleanQuery = $FolderName -replace '[\(\)\[\]_.]', ' ' -replace '(?i)1080p|720p|bluray|remux', ''
    $EncodedQuery = [uri]::EscapeDataString($CleanQuery.Trim())

    $Url = "https://api.themoviedb.org/3/search/movie?api_key=$ApiKey&query=$EncodedQuery"

    try {
        $Response = Invoke-RestMethod -Uri $Url -Method Get

        if ($Response.results.Count -gt 0) {
            $Movie = $Response.results[0]
            $Year = ($Movie.release_date -split '-')[0]
            
            # 4. Store the data in an object
            $Results += [PSCustomObject]@{
                "Folder Name"  = $FolderName
                "Movie Title"  = $Movie.title
                "Release Year" = $Year
                "TMDb ID"      = $Movie.id
                "Overview"     = $Movie.overview
            }

            do {
              $checkResponse = Read-Host "Is: $($Movie.title) ($($Year)) [tmdbid-$($Movie.id)] `n $($Movie.overview) `nthe correct response `nfor: $($FolderName)? `n Y/N"
            } until ($checkResponse -match '^[YyNn]$')

            if ($checkResponse -eq "Y") {
                #$Movie.result = "verified"
                $rawNewName = "$($Movie.title) ($($Year)) [tmdbid-$($Movie.id)]"
                $newName = $rawNewName -replace '[\\\/:*?"<>|]', ''
                Rename-Item -Path $Folder.FullName -NewName $newName
                Write-Host "Renamed $($Folder.Name) to $newName"
            }
<# 
            $Movie.result = "limbo"

            if ($Movie.result -eq "verified") {
                $movieName = "$($Movie.title) ($($Year))" -replace '[\\\/:*?"<>|]', ''
                $movieFullPath = -JoinPath $ParentFolder $newName
                $movieFiles  = Get-ChildItem -Path $movieFullPath -File
                
                $fileCount = 1
                foreach ($movieFile in $movieFiles) {
                    $extension = $movieFile.Extension
                    $newMovieName = "$movieName ($fileCount)$extension"

                    Rename-Item -Path $movieFile.FullName -NewName $newMovieName
                    $count++
                }
            }
 #>
        }
        else {
            Write-Warning "  - No match found for '$FolderName'"
        }
    }
    catch {
        Write-Error "  - Failed to query TMDb for '$FolderName'"
    }

    # Optional: Add a tiny delay to be polite to the API
    Start-Sleep -Milliseconds 100
}

# 5. Display the final results as a table
$Results | Sort-Object "Movie Title" | Out-GridView