
# The folder of pfx files. all files in the folder will be imported.
$certLocation = ".\*.pfx"

#Specify the password of the pfx files.
$certPass = "SF";

# Specfiy the Service account that the cert will be granted to
$serviceAccount= "NETWORK SERVICE";

# The store of certs. Default is Cert:\LocalMachine\My
$CertStoreLocation = "Cert:\LocalMachine\My";

$pfxFiles = Get-Item -Path $certLocation;
write-host "Found $pfxFiles";

# DONOT changes the below commands.
$securePassword = ConvertTo-SecureString -String $certPass -Force -AsPlainText;

foreach($i in $pfxFiles){

    write-host "Import $i";
    $cert = Import-PfxCertificate -Exportable -CertStoreLocation $CertStoreLocation -FilePath $i -Password $securePassword;

    write-host "Grant permission on $i to $serviceAccount";

    # Specify the user, the permissions, and the permission type
    $permission = "$($serviceAccount)","FullControl","Allow"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission

    # Location of the machine-related keys
    $keyPath = Join-Path -Path $env:ProgramData -ChildPath "\Microsoft\Crypto\RSA\MachineKeys"
    $keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $keyFullPath = Join-Path -Path $keyPath -ChildPath $keyName

    # Get the current ACL of the private key
    $acl = (Get-Item $keyFullPath).GetAccessControl('Access')

    # Add the new ACE to the ACL of the private key
    $acl.SetAccessRule($accessRule)

    # Write back the new ACL
    Set-Acl -Path $keyFullPath -AclObject $acl -ErrorAction Stop

    # Observe the access rights currently assigned to this certificate
    get-acl $keyFullPath| fl
}
