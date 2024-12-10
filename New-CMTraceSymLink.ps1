Param (
    [string]$LogPath = "C:\Windows\Temp\CreateSymLink.Log",
    [string]$FileName = "CMTrace.exe",
    [string]$DestDir = "$($env:windir)\system32",
    [string]$URL = "https://github.com/wclc-mis/cmtrace/raw/refs/heads/main/CMTrace.exe"
)

Start-Transcript -Path $LogPath -Force -ErrorAction SilentlyContinue

try {
    $DestPath = Join-Path -Path $DestDir -ChildPath $FileName
    $FileExists = Test-Path -Path $DestPath

    if (-not $FileExists) {
        Write-Host "CMTrace not found in System32. Attempting download..."
        
        # Download to temp first
        $OutFile = Join-Path $env:TEMP $FileName
        # Ensure the destination directory exists
        New-Item -Path $DestDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

        $Result = Invoke-WebRequest -Uri $URL -OutFile $OutFile -UseBasicParsing -ErrorAction SilentlyContinue

        if (-not (Test-Path $OutFile)) {
            Write-Host "Failed to download CMTrace.exe from $URL"
            Exit 1
        }
        else {
            Copy-Item -Path $OutFile -Destination $DestPath -Force -Verbose
            Write-Host "CMTrace successfully copied to System32."
        }
    }
    else {
        Write-Host "CMTrace already exists in System32."
    }

    # Now, make CMTrace the default application for .log files
    Write-Host "Setting CMTrace as the default handler for .log files..."
    # Define a custom file association name
    $AssocName = "CMTraceFile"

    # The assoc and ftype commands need to be run in cmd context, so we call them through PowerShell
    cmd /c "assoc .log=$AssocName"
    cmd /c "ftype $AssocName=""$DestPath"" ""%%1"""

    Write-Host "CMTrace is now the default .log file viewer."

    Stop-Transcript -ErrorAction SilentlyContinue
    Write-Host "Completed."
    return 0
    exit 0
}
catch {
    Stop-Transcript -ErrorAction SilentlyContinue
    Write-Host "An error occurred: $($_.Exception.Message)"
    throw $_
}
