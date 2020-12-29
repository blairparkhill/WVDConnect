$uname = "blair"
$domainWINS = "WORKGROUP"
$pw = "LoginVSIlab!1"
$applianceUrl = "https://bpleva01.eastus2.cloudapp.azure.com"
$DNSServer = "10.0.0.4"
$Domain = "bp-scaletest.vsi"
$OUPath = "OU=Launchers,OU=bp-scaletest,DC=scaletest,dc=vsi"
$LocalAdminCred = New-Object pscredential("blair",(ConvertTo-SecureString -AsPlainText -Force -String "Password!123"))
$DomainAdminCred = New-Object pscredential("scaletest\loginvsi",(ConvertTo-SecureString -AsPlainText -Force -String "LoginVSIlab!1"))

Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses $DNSServer

#If ((Get-WmiObject Win32_ComputerSystem).Domain -ne $Domain)
#{
#    Add-Computer -LocalCredential $LocalAdminCred -Credential $DomainAdminCred -DomainName $Domain -OUPath $OUPath
#}


if (-not("SSLValidator" -as [type])) {
    add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class SSLValidator {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }

    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(SSLValidator.ReturnTrue);
    }
}
"@
}
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLValidator]::GetDelegate()

$Body = @{"grant_type"="client_credentials";"scope"="microservice";"client_id"="Engine";"client_secret"="6ZY59S36VICWA7FQNYDKOEC004VHAHT0PB5C2CP3"}
$Req = Invoke-RestMethod -uri "$applianceUrl/identityServer/connect/token" -Body $Body -Headers @{"Content-Type"="application/x-www-form-urlencoded";"Authorization"="Token"} -Method Post	
$Headers = @{"Authorization"="Bearer $($Req.access_token)";"Content-Type"="application/json"}

# Check if launcher install bits exist, if not copy them from the virtual appliance
if (-not (Test-Path "C:\launcher_win10_x64"))
{
    Invoke-WebRequest -OutFile "C:\launcher_win10_x64.zip" -Uri "$applianceUrl/contentDelivery/content/zip/launcher_win10_x64.zip" -Headers $Headers
    Expand-Archive -Path "C:\launcher_win10_x64.zip" -DestinationPath "C:\launcher_win10_x64"
}

# Set the launcher machine to autologon with admin account
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value 1 -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value $uname -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value $pw -Force		
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value $domainWINS -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoLogonCount" -Value 999 -Force
Remove-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoLogonSID" -Force -Erroraction silentlycontinue

# Check if launcher is installed, if not install it
If (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe"))
{
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "PILauncher_Install" -Value 'cmd /c msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log" && shutdown /r /t 0' -Force        
    
    #Start-Sleep -Seconds 120
    #msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log"
}

# Check if launcher is installed, if it is, autorun it
If ($null -eq (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "PILauncher" -ea silent))
{
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "PILauncher" -Value "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe" -Force
    Restart-Computer -Force
}

# Check if launcher WVD Connector bits exist, if not copy them from the virtual appliance and unzip to Launcher program files directory
if (-not (Test-Path "C:\WVDConnector"))
{
    Invoke-WebRequest -OutFile "C:\WVDConnector.zip" -Uri "https://bpscaleteststorage.blob.core.windows.net/bpscaleteststorage/WVDConnector.zip" -Headers $Headers
    Expand-Archive -Path "C:\WVDConnector.zip" -DestinationPath "C:\Program Files\Login VSI\Login PI 3 Launcher\WVD Connector"
}
