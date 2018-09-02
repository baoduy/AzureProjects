#https://blogs.technet.microsoft.com/pstips/2017/08/24/install-and-configure-group-managed-service-account/

$gMSA_Name = 'gmSF'
$gMSA_FQDN = 'sf.hbd.net'
$gMSA_SPNs = 'http/sf.hbd.net'
$gMSA_HostNames = 'sf1', 'sf2', 'sf3'

# run this manually as just 1 time create/Domain 
# Add-KDSRootKey -EffectiveTime (Get-Date).AddHours(-10);
# a5d0a4a2-098d-9f14-8989-656edd9da867

# $gMSA_HostsGroup = $gMSA_HostNames | ForEach-Object { Get-ADComputer -Identity $_ };

# Create Group
$gMSA_HostsGroupName = "$($gMSA_Name)_HostsGroup"
$gMSA_HostsGroup = New-ADGroup -Name $gMSA_HostsGroupName -GroupScope Global -PassThru
$gMSA_HostNames | ForEach-Object { Get-ADComputer -Identity $_ } | ForEach-Object { Add-ADGroupMember -Identity $gMSA_HostsGroupName -Members $_ }

# Config gMSA
New-ADServiceAccount -Name $gMSA_Name -DNSHostName $gMSA_FQDN -PrincipalsAllowedToRetrieveManagedPassword $gMSA_HostsGroup -ServicePrincipalNames $gMSA_SPNs

# Other option to create gMSA
# $myBackendSPNs = 'http/sf', 'http/sf.hbd.net'
# New-ADServiceAccount -Name $gMSA_Name -DNSHostName $gMSA_FQDN -PrincipalsAllowedToRetrieveManagedPassword $gMSA_HostsGroup -ServicePrincipalNames $gMSA_SPNs -OtherAttributes @{'msDS-AllowedToDelegateTo'=$myBackendSPNs}

# If delegation is required:Enable 'Trust this user for delegation to any service' (a.k.a. "Unconstrained Delegation")
# Set-ADServiceAccount -Identity $gMSA_Name -TrustedForDelegation $true