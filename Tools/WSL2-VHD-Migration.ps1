# Export existing WSL distros
Write-Host "Exporting existing WSL distros..."
wsl --export docker-desktop-data $env:USERPROFILE\docker-desktop-data.tar
wsl --export docker-desktop $env:USERPROFILE\docker-desktop.tar

# Unregister existing WSL distros
Write-Host "Unregistering existing WSL distros..."
wsl --unregister docker-desktop-data
wsl --unregister docker-desktop

# Change the default WSL folder
Write-Host "Changing the default WSL folder..."
$NewWSLFolderPath = "D:\Dev\WSL"
$configContent = @"
[wsl2]
kernelCommandLine = "virtio_mmio.device=4K@0xd00000:5"
userdata = "$NewWSLFolderPath\%UID%"
"@
$configContent | Set-Content -Path $env:UserProfile\.wslconfig

# Import WSL distros to the new location
Write-Host "Importing WSL distros to the new location..."
wsl --import docker-desktop-data $NewWSLFolderPath\docker-desktop-data $env:USERPROFILE\docker-desktop-data.tar
wsl --import docker-desktop $NewWSLFolderPath\docker-desktop $env:USERPROFILE\docker-desktop.tar

# Remove exported tar files
Write-Host "Removing exported tar files..."
Remove-Item -Path $env:USERPROFILE\docker-desktop-data.tar
Remove-Item -Path $env:USERPROFILE\docker-desktop.tar

# Notify user to restart the computer
Write-Host "Migration complete. Please restart your computer to apply the changes."
