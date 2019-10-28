function Connect-WinConnectivity {
    [CmdletBinding()]
    param(
        [string] $UserName,
        [string] $Password,
        [string] $FilePath,
        [switch] $AsSecure,
        [switch] $MultiFactorAuthentication,
        [Parameter(Mandatory = $true)][ValidateSet('All', 'AzureAD', 'ExchangeOnline', 'MSOnline', 'SecurityCompliance', 'SharePointOnline', 'SkypeOnline', 'Teams')][string[]] $Service,
        [string] $Tenant
    )

    if ($FilePath) {
        $PasswordFromFile = $true
        if (Test-Path -LiteralPath $FilePath) {
            $Password = $FilePath
        } else {
            #Write-Color "[-]", " File with password doesn't exists. Path doesn't exists: $FilePath" -Color Red, Yellow
            Write-Verbose "File with password doesn't exists. Path doesn't exists: $FilePath"
            return
        }
    } else {
        $PasswordFromFile = $false
    }

    $Configuration = @{
        Options    = @{
            LogsPath = 'C:\Support\Logs\Automated.log'
        }
        Office365  = [ordered] @{
            Credentials        = [ordered] @{
                Username                  = $UserName
                Password                  = $Password
                PasswordAsSecure          = $AsSecure.IsPresent
                PasswordFromFile          = $PasswordFromFile
                MultiFactorAuthentication = $MultiFactorAuthentication.IsPresent
            }
            MSOnline           = [ordered] @{
                Use         = $false
                SessionName = 'O365 Azure MSOL' # MSOL
            }
            AzureAD            = [ordered] @{
                Use         = $false
                SessionName = 'O365 Azure AD' # Azure
                Prefix      = ''
            }
            ExchangeOnline     = [ordered] @{
                Use            = $false
                Authentication = 'Basic'
                ConnectionURI  = 'https://outlook.office365.com/powershell-liveid/'
                Prefix         = 'O365'
                SessionName    = 'O365 Exchange'
            }
            SecurityCompliance = [ordered] @{
                Use            = $false
                Authentication = 'Basic'
                ConnectionURI  = 'https://ps.compliance.protection.outlook.com/PowerShell-LiveId'
                Prefix         = 'O365'
                SessionName    = 'O365 Security And Compliance'
            }
            SharePointOnline   = [ordered] @{
                Use           = $false
                ConnectionURI = "https://$($Tenant)-admin.sharepoint.com"
            }
            SkypeOnline        = [ordered] @{
                Use         = $false
                SessionName = 'O365 Skype'
            }
            Teams              = [ordered] @{
                Use         = $false
                Prefix      = ''
                SessionName = 'O365 Teams'
            }
        }
        OnPremises = @{
            Credentials = [ordered] @{
                Username         = 'przemyslaw.klys@evotec.pl'
                Password         = 'C:\Support\Important\Password-O365-Evotec.txt'
                PasswordAsSecure = $true
                PasswordFromFile = $true
            }
            Exchange    = [ordered] @{
                Use            = $false
                Authentication = 'Kerberos'
                ConnectionURI  = 'http://PLKATO365Exch.evotec.pl/PowerShell'
                Prefix         = ''
                SessionName    = 'Exchange'
            }
        }
    }

    if ($Service -eq 'All') {
        foreach ($_ in $Configuration.Office365.Keys | Where-Object { $_ -ne 'Credentials' }) {
            if ($_ -eq 'SharePointOnline') {
                if (-not $Tenant) {
                    #Write-Color "[-]", " Tenant parameter not provided. Skipping connection to SharePoint Online." -Color Red, Yellow
                    Write-Verbose "Tenant parameter not provided. Skipping connection to SharePoint Online."
                    continue
                }
            }
            $Configuration.Office365.($_).Use = $true
        }
    } else {
        foreach ($_ in $Service) {
            $Configuration.Office365.($_).Use = $true
        }
    }

    $BundleCredentials = $Configuration.Office365.Credentials
    $BundleCredentialsOnPremises = $Configuration.OnPremises.Credentials

    $Connected = @(
        if ($Configuration.Office365.MSOnline.Use) {
            Connect-WinAzure @BundleCredentials -Output -SessionName $Configuration.Office365.MSOnline.SessionName -Verbose
        }
        if ($Configuration.Office365.AzureAD.Use) {
            Connect-WinAzureAD @BundleCredentials -Output -SessionName $Configuration.Office365.AzureAD.SessionName -Verbose
        }
        if ($Configuration.Office365.ExchangeOnline.Use) {
            Connect-WinExchange @BundleCredentials -Output -SessionName $Configuration.Office365.ExchangeOnline.SessionName -ConnectionURI $Configuration.Office365.ExchangeOnline.ConnectionURI -Authentication $Configuration.Office365.ExchangeOnline.Authentication -Verbose
        }
        if ($Configuration.Office365.SecurityCompliance.Use) {
            Connect-WinSecurityCompliance @BundleCredentials -Output -SessionName $Configuration.Office365.SecurityCompliance.SessionName -ConnectionURI $Configuration.Office365.SecurityCompliance.ConnectionURI -Authentication $Configuration.Office365.SecurityCompliance.Authentication -Verbose
        }
        if ($Configuration.Office365.SkypeOnline.Use) {
            Connect-WinSkype @BundleCredentials -Output -SessionName $Configuration.Office365.SkypeOnline.SessionName -Verbose
        }
        if ($Configuration.Office365.SharePointOnline.Use) {
            Connect-WinSharePoint @BundleCredentials -Output -SessionName $Configuration.Office365.SharePointOnline.SessionName -ConnectionURI $Configuration.Office365.SharePointOnline.ConnectionURI -Verbose
        }
        if ($Configuration.Office365.Teams.Use) {
            Connect-WinTeams @BundleCredentials -Output -SessionName $Configuration.Office365.Teams.SessionName -Verbose
        }
        if ($Configuration.OnPremises.Exchange.Use) {
            Connect-WinExchange @BundleCredentialsOnPremises -Output -SessionName $Configuration.OnPremises.Exchange.SessionName -ConnectionURI $Configuration.OnPremises.Exchange.ConnectionURI -Authentication $Configuration.OnPremises.Exchange.Authentication -Verbose
        }
    )
    if ($Connected.Status -contains $false) {
        foreach ($C in $Connected | Where-Object { $_.Status -eq $false }) {
            #Write-Color -Text 'Connecting to tenant failed for ', $C.Output, ' with error ', $Connected.Extended -Color White, Red, White, Red -LogFile $Configuration.Options.LogsPath
            Write-Verbose "Connecting to tenant failed for $($C.Output) with error $($Connected.Extended)"
        }
        return
    }
}