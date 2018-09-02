# Allow to Retreiving Password from gMSA
Import-module activedirectory

$gMSA_HostNames = 'sf1', 'sf2', 'sf3'

$accounts = $gMSA_HostNames.ForEach{return (Get-ADComputer $_)}

Write-Host "Set-ADServiceAccount to $accounts"

Set-ADServiceAccount -Identity gmSF -PrincipalsAllowedToRetrieveManagedPassword $accounts