function Test-AvailabilityCommands {
    param (
        [string[]] $Commands
    )
    $CommandsStatus = foreach ($Command in $Commands) {
        [bool] $Exists = Get-Command -Name $Command -ErrorAction SilentlyContinue
        if ($Exists) {
            Write-Verbose "Test-AvailabilityCommands - Command $Command is available."
        } else {
            Write-Verbose "Test-AvailabilityCommands - Command $Command is not available."
        }
        $Exists
    }
    return $CommandsStatus
}