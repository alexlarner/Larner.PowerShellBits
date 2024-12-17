#Requires -Modules PSFramework

[CmdletBinding(SupportsShouldProcess)]
param (
    [string]
    $LogFolder = "$env:ProgramData\$($env:USERDNSDOMAIN.split('.')[0])\Logs"
)

trap {
    if ($ExitCode) {
        # This is needed because you cannot exit the script from the ErrorEvent section of Invoke-PSFProtectedCommand
        Exit-Cleanly $ExitCode
    } else {
        Write-PSFMessage -Level Warning -Message "Unhandled error occured" -ErrorRecord $_
        Write-PSFMessage "Exiting with exit code 666"
        Wait-PSFMessage
        Exit 666
    }
}

Set-PSFConfig -FullName PSFramework.Logging.LogFile.UTC -Value $true

$UTCTimeStamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ssZ')
$ScriptName = (Split-Path $PSCommandPath -Leaf).Split('.')[0]
$LogPath = Join-Path $LogFolder "$ScriptName`_$UTCTimeStamp.csv"

$paramSetPSFLoggingProvider = @{
    Name         = 'logfile'
    InstanceName = $ScriptName
    FilePath     = $LogPath
    Enabled      = $true
    Wait         = $true
    UTC          = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider

function Exit-Cleanly {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]
        $ExitCode
    )
    Write-PSFMessage "Exiting with exit code [$ExitCode]"
    Wait-PSFMessage
    Exit $ExitCode
}

Invoke-PSFProtectedCommand -Action '' -ScriptBlock {

} -ErrorEvent {
    $ExitCode = 2
} -EnableException:$true
