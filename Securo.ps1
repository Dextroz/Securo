<#
MIT License

Copyright (c) 2019 Dextroz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>
<#
    .SYNOPSIS
        Security related tasks script.
    
    .DESCRIPTION
        A script for running a variety of security related tasks such as gpg, hashing and more.
    
    .PARAMETER Gpg
        The path to the directory which PIA is installed. Defaults to: "C:\Program Files\Private Internet Access".
    
    .PARAMETER Timeout
        The time to wait for the command to execute before failing. Measured in seconds.

    .EXAMPLE
        Connect-PIA -PIAInstallationPath "D:\Private Internet Access" -Timeout 10 -Verbose

    .EXAMPLE
        Connect-PIA
#>
[CmdletBinding()]
param (
    # Parameters for Gpg.
    [Parameter(Mandatory = $false)]
    [Switch]
    $Gpg,

    [Parameter(Mandatory = $false)]
    [String]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    $SigningKeyFilePath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $SignatureFilePath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $FileToValidatePath,

    # Parameters for hashing.
    [Parameter(Mandatory = $false)]
    [Switch]
    $Hash,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $FileToHashPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Algorithm
)

# Check that a switch is supplied.
if (-not $Gpg -and -not $Hash) {
    Write-Error -Message "Provide the Gpg or Hash switch to Securo."
    break
}

# Gpg related tasks.
if ($Gpg) {
    # Check Gpg is installed, if not, install it.
    if (-not (Test-Path -Path "C:\Program Files (x86)\gnupg\bin\gpg.exe")) {
        try {
            $GpgDownloadUri = "https://gnupg.org/ftp/gcrypt/binary/gnupg-w32-2.2.19_20191207.exe"
            $ExeFilePath = "$($env:UserProfile)\Downloads\$($GpgDownloadUri.Split('/')[6])"
            Write-Verbose -Message "Attempting to download Gnupg..."
            Invoke-WebRequest -Uri $GpgDownloadUri -OutFile $ExeFilePath -Verbose:($PSBoundParameters["Verbose"] -eq $true)
        }
        catch {
            Write-Error -Message "Failed to download Gnupg with the following error: $($_.Exception.Message)"
            break
        }
        # Install Gpg from exe file.
        Write-Verbose -Message "Attempting to install Gnupg..."
        Start-Process -FilePath $ExeFilePath -ArgumentList '/S' -NoNewWindow -Wait -PassThru
        Write-Verbose -Message "Gnupg successfully installed."
    }
    # Begin Gpg operations.

}