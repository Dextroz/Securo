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
        Run a GnuPG related task.
    
    .PARAMETER SigningKeyFilePath
        The path to the signing key to add to the GnuPG key ring.

    .PARAMETER SignatureFilePath
        The path to the .sig (signature) file. Used in the verification process.
    
    .PARAMETER FileToValidatePath
        The path to the file to verify the integirty of.

    .PARAMETER Hash
        Run a hash related task.

    .PARAMETER FileDirHashPath
        The path to the file or directory to validate the integrity of.

    .PARAMETER Algorithm
        The hashing algorithm to use during the integrity checking process.

    .EXAMPLE
        .\Securo.ps1 -Gpg -SigningKeyFilePath "path/to/key/tails-signing.key" -SignatureFilePath "path/to/sig/tails-amd64-4.1.1.img.sig" -FileToValidatePath "path/to/file/tails-amd64.img" -Verbose

    .EXAMPLE
        .\Securo.ps1 -Hash -FileToHashPath ".\Securo.ps1" -Algorithm "SHA256"
#>
[CmdletBinding()]
param (
    # Parameters for GnuPG.
    [Parameter(Mandatory = $false)]
    [Switch]
    $Gpg,

    [Parameter(Mandatory = $false)]
    [String]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path -Path $_ })]
    $SigningKeyFilePath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path -Path $_ })]
    [String]
    $SignatureFilePath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path -Path $_ })]
    [String]
    $FileToValidatePath,

    # Parameters for hashing.
    [Parameter(Mandatory = $false)]
    [Switch]
    $Hash,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path -Path $_ })]
    [String]
    $FileDirHashPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { ($_ -in @("SHA1", "SHA256", "SHA384", "SHA512", "MD5")) })] 
    [String]
    $Algorithm
)

$Version = "0.0.2"

# Check that a switch is supplied.
if (-not $Gpg -and -not $Hash) {
    Write-Error -Message "Provide the Gpg or Hash switch to Securo."
    break
}

# GnuPG related tasks.
if ($Gpg) {
    $GpgInstallLocation = "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
    # Check GnuPG is installed, if not, install it.
    Write-Verbose -Message "Checking GnuPG is installed."
    if (-not (Test-Path -Path $GpgInstallLocation)) {
        try {
            Write-Verbose -Message "GnuPG is not installed, attempting to download and install it."
            $GpgDownloadUri = "https://gnupg.org/ftp/gcrypt/binary/gnupg-w32-2.2.19_20191207.exe"
            $ExeFilePath = "$($env:UserProfile)\Downloads\$($GpgDownloadUri.Split('/')[6])"
            Write-Verbose -Message "Attempting to download GnuPG..."
            Invoke-WebRequest -Uri $GpgDownloadUri -OutFile $ExeFilePath -Verbose:($PSBoundParameters["Verbose"] -eq $true)
        }
        catch {
            Write-Error -Message "Failed to download GnuPG with the following error: $($_.Exception.Message)"
            break
        }
        # Install GnuPG from exe file.
        Write-Verbose -Message "GnuPG downloaded successfully. Attempting to install GnuPG..."
        Start-Process -FilePath $ExeFilePath -ArgumentList '/S' -NoNewWindow -Wait -Verbose:($PSBoundParameters["Verbose"] -eq $true) | Out-Null
        Write-Verbose -Message "GnuPG installed successfully."
    }
    else {
        Write-Verbose -Message "GnuPG is already installed."
    }
    # Begin GnuPG operations.
    # Current GnuPG operation supported is checking a file using a signing key, signure file and the file to check the integrity of.
    # Add signing key to GnuPG key ring.
    Write-Verbose -Message "Adding signing key: $($SigningKeyFilePath) to GnuPG key ring..."
    try {
        $Command = Start-Process -FilePath $GpgInstallLocation -ArgumentList "--import $($SigningKeyFilePath)" -NoNewWindow -Wait -Verbose:($PSBoundParameters["Verbose"] -eq $true)
        Write-Output -InputObject $Command
        Write-Verbose -Message "Signing key: $($SigningKeyFilePath) successfully added to GnuPG key ring."
    }
    catch {
        Write-Error -Message "Failed to add signing key: $($SigningKeyFilePath) to GnuPG key ring with the following error: $($_.Exception.Message)"
        break
    }
    # Check the signature of the file.
    try {
        Write-Verbose -Message "Verifying file: $($FileToValidatePath)..."
        $Command = Start-Process -FilePath $GpgInstallLocation -ArgumentList "--verify $($SignatureFilePath) $($FileToValidatePath)" -NoNewWindow -Wait -Verbose:($PSBoundParameters["Verbose"] -eq $true)
        # Check output contains "good signature".
        if (-not ($Command -like "*Good signature*")) {
            Write-Error -Message "The file: $($FileToValidatePath) failed verification.`nFull output: $($Command)"
            break
        }
        else {
            Write-Output -InputObject "The file: $($FileToValidatePath) passed verification.`nFull output: $($Command)"
        }
    }
    catch {
        Write-Error -Message "GnuPG verify process failed with the following error: $($_.Exception.Message)"
        break
    }
}

# Hashing related tasks.
if ($Hash) {
    # Check if path supplied is a file or directory.
    if ((Get-Item -Path $FileDirHashPath) -is [System.IO.DirectoryInfo]) {
        Write-Verbose -Message "Attempting to hash all files in the directory: $($FileDirHashPath) using the algorithm: $($Algorithm)"
        # Get all files recursively in directory and hash them.
        try {
            $FileHashes = Get-ChildItem -Path $FileDirHashPath -Recurse | Get-FileHash -Algorithm $Algorithm -Verbose:($PSBoundParameters["Verbose"] -eq $true)
            Write-Output -InputObject "File hashes for directory: $($FileDirHashPath) using algorithm: $($Algorithm)"
            Write-Output -InputObject ($FileHashes | Format-Table -Property "Hash", "Path")
        }
        catch {
            Write-Error -Message "Failed to hash the directory: $($FileDirHashPath) with the following error: $($_.Exception.Message)"
            break
        }
    }
    # Path is to a single file. Hash it.
    else {
        Write-Verbose -Message "Attempting to generate hash for the file: $($FileDirHashPath) using the algorithm: $($Algorithm)"
        try {
            $Command = Get-FileHash -Path $FileDirHashPath -Algorithm $Algorithm -Verbose:($PSBoundParameters["Verbose"] -eq $true)
            Write-Output -InputObject "File hash: $($Command.Hash) for file: $($FileDirHashPath) using the algorithm: $($Algorithm)"
        }
        catch {
            Write-Error -Message "Failed to hash the file: $($FileDirHashPath) with the following error: $($_.Exception.Message)"
            break
        }
    }
}
