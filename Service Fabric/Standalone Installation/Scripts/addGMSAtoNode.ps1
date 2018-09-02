# Install this module if any error
# Install-WindowsFeature RSAT-AD-PowerShell

Import-module activedirectory

$gMSA_Name = 'gmSF'

Install-AdServiceAccount -Identity $gMSA_Name
Test-AdServiceAccount $gMSA_Name