# -----------------------------------------------------------------------------
# 
#  Go Application Installer for Windows
#
#  Description:
#  This script detects the Windows OS architecture (AMD64 or ARM64) and 
#  downloads the corresponding pre-built Go application binary. It then 
#  installs the application to a directory in "Program Files" and adds that
#  directory to the system's PATH for easy access from any terminal.
#
#  Usage:
#  1. Save this script as 'install.ps1'.
#  2. Open a PowerShell terminal.
#  3. You may need to change the execution policy to run the script.
#     Run: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#  4. Navigate to the directory where you saved the script.
#  5. Execute the script: .\install.ps1
#
# -----------------------------------------------------------------------------

# --- Configuration ---
# TODO: Replace these placeholder values with your actual application details.
$AppName = "MyGoApp"
$Amd64Url = "https://example.com/releases/mygoapp-1.0-windows-amd64.exe"
$Arm64Url = "https://example.com/releases/mygoapp-1.0-windows-arm64.exe"

# The final installation directory
$InstallDir = "$env:ProgramFiles\$AppName"

# --- Script Body ---

# 1. Ensure the script is running with Administrator privileges
Write-Host "Checking for administrator privileges..."
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges are required to install this application."
    Write-Warning "Attempting to re-launch the script as an Administrator..."
    
    # Relaunch the script with elevated permissions
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
Write-Host "Success: Running with administrator privileges." -ForegroundColor Green

try {
    # 2. Detect OS Architecture
    Write-Host "Detecting OS architecture..."
    $architecture = (Get-ComputerInfo).OsArchitecture

    $DownloadUrl = $null
    $FileName = $null

    if ($architecture -eq 'X86-64') {
        Write-Host "AMD64 (x64) architecture detected."
        $DownloadUrl = $Amd64Url
        $FileName = "mygoapp-amd64.exe"
    }
    elseif ($architecture -eq 'ARM64') {
        Write-Host "ARM64 architecture detected."
        $DownloadUrl = $Arm64Url
        $FileName = "mygoapp-arm64.exe"
    }
    else {
        throw "Unsupported OS architecture: $architecture. This script only supports AMD64 and ARM64."
    }

    # Define the path for the downloaded file in the temp directory
    $TempFilePath = Join-Path $env:TEMP $FileName

    # 3. Download the appropriate binary
    Write-Host "Downloading $AppName for your architecture from $DownloadUrl..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFilePath -UseBasicParsing
    Write-Host "Download complete." -ForegroundColor Green

    # 4. Create installation directory
    if (-NOT (Test-Path -Path $InstallDir)) {
        Write-Host "Creating installation directory at $InstallDir..."
        New-Item -Path $InstallDir -ItemType Directory | Out-Null
    } else {
        Write-Host "Installation directory already exists at $InstallDir."
    }
    
    # 5. Move the binary to the installation directory
    $FinalExePath = Join-Path $InstallDir "$AppName.exe"
    Write-Host "Installing application to $FinalExePath..."
    Move-Item -Path $TempFilePath -Destination $FinalExePath -Force
    
    # 6. Add the installation directory to the system's PATH
    Write-Host "Adding installation directory to the system PATH..."
    
    # Get the current system PATH
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    
    # Check if the install directory is already in the PATH
    if ($CurrentPath -split ';' -notcontains $InstallDir) {
        $NewPath = "$CurrentPath;$InstallDir"
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "Machine")
        Write-Host "Successfully added $AppName to the system PATH." -ForegroundColor Green
        # Inform the user that a new terminal session is needed
        Write-Host "Please open a new terminal or restart your current one for the PATH changes to take effect." -ForegroundColor Yellow
    } else {
        Write-Host "$AppName is already in the system PATH."
    }

    Write-Host "`nInstallation complete! You can now run '$AppName' from any terminal." -ForegroundColor Cyan

}
catch {
    Write-Error "An error occurred during installation: $($_.Exception.Message)"
    exit 1
}
# irm <RAW_GIST_URL> | iex