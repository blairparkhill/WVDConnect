$uname = "blair"
$domainWINS = "WORKGROUP"
$pw = "LoginVSIlab!1"
$DNSServer = "10.0.0.4"

#The following isn't used unless downloading launcher install from virtual appliance
#$applianceUrl = "https://bpleva01.eastus2.cloudapp.azure.com"

#The following variables are not used unless allowing the machine to domain join
#$Domain = "bp-scaletest.vsi"
#$OUPath = "OU=Launchers,OU=bp-scaletest,DC=scaletest,dc=vsi"
#$LocalAdminCred = New-Object pscredential("blair",(ConvertTo-SecureString -AsPlainText -Force -String "Password!123"))
#$DomainAdminCred = New-Object pscredential("scaletest\loginvsi",(ConvertTo-SecureString -AsPlainText -Force -String "LoginVSIlab!1"))

Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses $DNSServer

#The following is for domain joined launchers
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

#The following is for downloading the launcher install from the Login Enterprise Virtual Appliance 
#$Body = @{"grant_type"="client_credentials";"scope"="microservice";"client_id"="Engine";"client_secret"="6ZY59S36VICWA7FQNYDKOEC004VHAHT0PB5C2CP3"}
#$Req = Invoke-RestMethod -uri "$applianceUrl/identityServer/connect/token" -Body $Body -Headers @{"Content-Type"="application/x-www-form-urlencoded";"Authorization"="Token"} -Method Post	
#$Headers = @{"Authorization"="Bearer $($Req.access_token)";"Content-Type"="application/json"}

# Check if launcher install bits exist, if not copy them from the virtual appliance
#if (-not (Test-Path "C:\launcher_win10_x64"))
#{
#    Invoke-WebRequest -OutFile "C:\launcher_win10_x64.zip" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/launcher_win10_x64.zip"
#    Expand-Archive -Path "C:\launcher_win10_x64.zip" -DestinationPath "C:\launcher_win10_x64"
	#Start-Process -FilePath "C:\folder\setup.exe" -Verb runAs -ArgumentList '/s','/v"/qn"'
	#Start-Process .\installer.exe /S -NoNewWindow -Wait -PassThru
#}

# Check if launcher install bits exist, if not copy them from github
if (-not (Test-Path "C:\launcher_win10_x64"))
{
    Invoke-WebRequest -OutFile "C:\launcher_win10_x64.zip" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/launcher_win10_x64.zip"
    Expand-Archive -Path "C:\launcher_win10_x64.zip" -DestinationPath "C:\launcher_win10_x64"
}

# Check if launcher is installed, if not install it
If (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe"))
{
    cmd /c msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log"        
}

# Check if launcher is installed, if it is set it to autorun
If ($null -eq (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "PILauncher" -ea silent))
{
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "PILauncher" -Value "C:\Program Files\Login VSI\Login PI 3 Launcher\Console\LoginPI.Launcher.Console.exe" -Force
    #Restart-Computer -Force
}

# Set the launcher machine to autologon with admin account
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value 1 -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value $uname -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value $pw -Force		
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value $domainWINS -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoLogonCount" -Value 999 -Force
Remove-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoLogonSID" -Force -Erroraction silentlycontinue

# Check if launcher WVD Connector bits exist, if not copy them from the virtual appliance and unzip to Launcher program files directory
if (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\WVD Connector"))
{
    Invoke-WebRequest -OutFile "C:\WVDConnector.zip" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/WVD%20Connector.zip"
    Expand-Archive -Path "C:\WVDConnector.zip" -DestinationPath "C:\Program Files\Login VSI\Login PI 3 Launcher\"
}

# Check if chrome exists, if not copy them from the virtual appliance and unzip to Launcher program files directory
if (-not (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"))
{
    Invoke-WebRequest -OutFile "C:\ChromeSetup.exe" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/ChromeSetup.exe"
	Start-Process -FilePath "C:\ChromeSetup.exe" -Verb runAs -ArgumentList '/silent','/install'
	#Other ways to start and exe install
	#Start-Process "c:\temp\UpdateVisualC++\vcredist_x86.exe" -ArgumentList "/q" -Wait
	#Start-Process .\installer.exe /S -NoNewWindow -Wait -PassThru
}

# Run the MSFT VDI optimizer
if (-not (Test-Path "C:\VDIOptimizer"))
{
    Invoke-WebRequest -OutFile "C:\VDIOptimizer.zip" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/Virtual-Desktop-Optimization-Tool-master.zip"
	Expand-Archive -Path "C:\VDIOptimizer.zip" -DestinationPath "C:\VDIOptimizer\"
	Start-Process -FilePath C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe '-ExecutionPolicy RemoteSigned -File "C:\VDIOptimizer\Virtual-Desktop-Optimization-Tool-master\Win10_VirtualDesktop_Optimize.ps1" -WindowsVersion 2004 -Verbose' -Wait
}

#Use this code to reboot the launcher after launcher bits are installed
#If (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe"))
#{
#    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "PILauncher_Install" -Value 'cmd /c msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log" && shutdown /r /t 0' -Force        
    
    #Start-Sleep -Seconds 120
    #msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log"
#}

#REBOOT THE MACHINE
shutdown /r /t 0 /f