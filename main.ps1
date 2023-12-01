# Created by Frostiye (6202)

Write-Host "Installer for windows server using XML files, tested on Windows Server 2022 Standard Edition.`n`n`n`n`n"

# Here we specify that RebootRequired is False(0) as no modules have required a reboot yet.
$RebootRequired = 0

foreach ($item in Get-ChildItem -Path ".\XML" -Force) {
    # we remove the first four characters from the string (.xml)
    $item = $item -replace ".{4}$"

    # And then we search for the feature.
    $module = Get-WindowsFeature -Name "$item" -ErrorAction SilentlyContinue | Select-Object -Property Name, InstallState
   
    # Since $module comes back as a hashlist we can't just do $module['Name'] but rather call the property we want
    $ModuleName = $module.Name
    $ModuleInstallState = $module.InstallState
    
    # Check if RebootRequired is False
    If (-NOT $RebootRequired) {

        # And if ModuleInstallState is equal to InstallPending
        If ($module.InstallState -eq "InstallPending") {

            # If the above is true, that means a module has requested that the system is to reboot,
            # and therefore we change RebootRequired to True(1)
            $RebootRequired = 1
        }
    }

    Write-Host "`n`nChecking if $ModuleName is installed"

    # Here we ask if (the program is installed currently) or (has been installed, and is awaitng a system reboot), if either of those are True(1), then we wont install that package.
    If ($ModuleInstallState -eq 'Installed' -or $ModuleInstallState -eq 'InstallPending') {
        If ($ModuleInstallState -eq 'InstallPending') {
            $ModuleInstallState = [string]$ModuleInstallState
            $ModuleInstallState = $ModuleInstallState.replace('InstallPending', 'installed, reboot required')
        }

        Write-Host "Service ($ModuleName) is $ModuleInstallState.`n"
    }
    
    Else {
        Write-Host "$ModuleName wasn't installed."
        Write-Host "Now installing: .\XML\$ModuleName`n"

        # If the module isn't installed we install it with provided XML files.
        $installer = Install-WindowsFeature -ConfigurationFilePath ".\XML\$item.xml"
        $InstallerExitCode = $installer.ExitCode

        Write-Host "($item) exit code: $InstallerExitCode"

        # Here we check if RebootRequired is False(0)
        If (-NOT $RebootRequired) {

            # And that InstallerExitCode is equal to SuccessRestartRequired.
            If ($InstallerExitCode -eq 'SuccessRestartRequired') {

                # If the above is true, it means that this module has requested that the system reboots, and therefore we change RebootRequired to True(1)
                $RebootRequired = 1
            }
        }
    }
}

# If RebootRequired is True(1)
If ($RebootRequired) {
    
    # Then we ask the user if they'd like to reboot.
    $qReboot = Read-Host "`nOne or more features require you to reboot the system, would you like to reboot? (yes/no)"

    # If the user responds with 'yes', the system will reboot.
    if ([string]$qReboot.ToLower() -eq "yes") {
        Restart-Computer    
    }

    # Otherwise we confirm that the user has requested no reboot.
    Else {
        Write-Host "User requested no reboot."
    }
}

# Here we tell the user that everything has ran without problems, and they can safely close the program by pressing enter or just closing the application.
Read-Host "`n`nProgram finished, press ENTER to leave"
