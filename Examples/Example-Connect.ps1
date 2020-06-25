#Import-Module .\Connectimo.psd1 -Force

#Connect-WinConnectivity -MultiFactorAuthentication -Service AzureAD,MSOnline,ExchangeOnline

#$Permission = Get-MailboxPermission -Identity 'spes@spes.org.pl'
$Permission | Format-Table -AutoSize *
$Permission | Where-Object { $_.AccessRights -eq "FullAccess" -and $_.IsInherited -eq $false }



#$FixAutoMapping = Get-MailboxPermission -Identity sharedmailbox | Where-Object { $_.AccessRights -eq "FullAccess" -and $_.IsInherited -eq $false }
#$FixAutoMapping | Remove-MailboxPermission
#$FixAutoMapping | ForEach-Object {
#    Add-MailboxPermission -Identity $_.Identity -User $_.User -AccessRights:FullAccess -AutoMapping $false
#}

Get-Help -