<#
.SYNOPSIS
Clones a Hyper-V virtual machine.

.DESCRIPTION
The Clone-HyperVM script duplicates a specified master Hyper-V virtual machine. It exports the master VM to a temporary folder, imports it to a new location, renames the cloned VM, and cleans up temporary files.

.PARAMETER MasterVmName
The name of the master VM to be cloned.

.PARAMETER TempFolderPath
(Optional) The temporary folder path to export the VM files to. Defaults to "C:\temp".

.PARAMETER NewVmFilesPath
(Optional) The new path where VM files need to be stored. Defaults to "D:\Dev\HyperV\$NewVmName\VM".

.PARAMETER NewVhdPath
(Optional) The new path where VM VHD needs to be stored. Defaults to "D:\Dev\HyperV\$NewVmName\Virtual Hard Disks".

.PARAMETER NewVmName
The name for the cloned VM.

.EXAMPLE
PS> .\Clone-HyperVM.ps1 -MasterVmName "dev-master" -NewVmName "dev-clone"
This example clones the VM named 'dev-master', exports it to "C:\temp", imports it to the auto-generated paths based on 'dev-clone', renames it to 'dev-clone', and cleans up the temporary files.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$MasterVmName,

    [string]$TempFolderPath = "C:\temp",

    [string]$NewVmFilesPath,

    [string]$NewVhdPath,

    [Parameter(Mandatory=$true)]
    [string]$NewVmName
)

# Set default paths if not provided
if (-not $NewVmFilesPath) {
    $NewVmFilesPath = "D:\Dev\HyperV\$NewVmName\VM"
}
if (-not $NewVhdPath) {
    $NewVhdPath = "D:\Dev\HyperV\$NewVmName\Virtual Hard Disks"
}

# Helper function to write verbose log
function Write-VerboseLog {
    Param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp : $message"
}

# Export VM
function Export-VMOperation {
    Param ([string]$vmName, [string]$exportPath)
    try {
        Export-VM -Name $vmName -Path $exportPath
        $vmExportPath = Join-Path -Path $exportPath -ChildPath $vmName
        Write-VerboseLog "Exported VM '$vmName' to '$vmExportPath'."
        return $vmExportPath
    }
    catch {
        Write-VerboseLog "Error exporting VM '$vmName': $_"
        throw
    }
}

# Import VM
function Import-VMOperation {
    Param ([string]$vmExportPath, [string]$vmFilesPath, [string]$vhdPath)
    try {
        $vmcxFilePath = Get-ChildItem -Path $vmExportPath -Filter "*.vmcx" -Recurse | Select-Object -ExpandProperty FullName
        if (-not $vmcxFilePath) {
            throw "VMCX file not found in path: $vmExportPath"
        }
        $importedVm = Import-VM -Path $vmcxFilePath -Copy -GenerateNewId -VirtualMachinePath $vmFilesPath -VhdDestinationPath $vhdPath
        Write-VerboseLog "Imported VM from '$vmcxFilePath'."
        return $importedVm
    }
    catch {
        Write-VerboseLog "Error importing VM from '$vmExportPath': $_"
        throw
    }
}

# Rename VM
function Rename-VMOperation {
    Param ([Microsoft.HyperV.PowerShell.VirtualMachine]$vm, [string]$newName)
    try {
        Rename-VM -VM $vm -NewName $newName
        Write-VerboseLog "Renamed VM to '$newName'."
    }
    catch {
        Write-VerboseLog "Error renaming VM to '$newName': $_"
        throw
    }
}

# Cleanup Temporary Files
function Cleanup-TemporaryFiles {
    Param ([string]$vmExportPath)
    try {
        if (Test-Path $vmExportPath) {
            Remove-Item -Path $vmExportPath -Recurse -Force
            Write-VerboseLog "Cleaned up temporary files in '$vmExportPath'."
        }
    }
    catch {
        Write-VerboseLog "Error cleaning up temporary files in '$vmExportPath': $_"
    }
}

# Main script execution
try {
    Write-VerboseLog "Starting Clone-HyperVM script."
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $vmExportPath = Export-VMOperation -vmName $MasterVmName -exportPath $TempFolderPath
    $importedVm = Import-VMOperation -vmExportPath $vmExportPath -vmFilesPath $NewVmFilesPath -vhdPath $NewVhdPath
    Rename-VMOperation -vm $importedVm -newName $NewVmName
    Cleanup-TemporaryFiles -vmExportPath $vmExportPath

    $stopwatch.Stop()
    Write-VerboseLog "Script completed in $($stopwatch.Elapsed.TotalSeconds) seconds."
}
catch {
    Write-Host "An error occurred in the Clone-HyperVM script: $_"
}
