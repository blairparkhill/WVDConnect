$uname = "blair"
$domainWINS = "WORKGROUP"
$pw = "LoginVSIlab!1"
$launcherURI = "https://github.com/blairparkhill/WVDConnect/raw/master/bpleva01_launcher_install484.zip"
$launcherZipPath = "C:\bpleva01_launcher_install484.zip"
$launcherZipExpandPath = "C:\bpleva01_launcher_install484"
$launcherMSIPath = "C:\bpleva01_launcher_install484\setup.msi"
$launcherInstallLogPath = "C:\bpleva01_launcher_install484\install.log"



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

# Check if launcher install bits exist, if not copy them from github
if (-not (Test-Path $launcherZipPath))
{
    Invoke-WebRequest -OutFile $launcherZipPath -Uri $launcherURI
    Expand-Archive -Path $launcherZipPath -DestinationPath $launcherZipExpandPath
}

# Check if launcher is installed, if not install it
# This may need to eventually change to a powershell install with -Wait
If (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe"))
{
    cmd /c msiexec /i $launcherMSIPath /qn /liewa $launcherInstallLogPath        
}

# Check if launcher is already autorunning, if it isn't set it to autorun
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

# Check if EdgeWebView2 bits exist, if not copy them from GitHub
if (-not (Test-Path "C:\Program Files (x86)\Microsoft\EdgeWebView\Application"))
{
    Invoke-WebRequest -OutFile "C:\MicrosoftEdgeWebview2Setup.exe" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/MicrosoftEdgeWebview2Setup.exe"
}

# Check if launcher Browser Connector bits exist, if not copy them from GitHub and unzip to Launcher program files directory
if (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\BrowserConnector"))
{
    Invoke-WebRequest -OutFile "C:\BrowserConnector.zip" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/BrowserConnector-v0.8r.zip"
    #Unblock the zip archive
    #Expand-Archive -Path "C:\BrowserConnector.zip" -DestinationPath "C:\Program Files\Login VSI\Login PI 3 Launcher\"
}

# Check if Launcher ScriptEditor bits exist, if not copy them from GitHub and unzip to Launcher program files directory
if (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\ScriptEditor"))
{
    Invoke-WebRequest -OutFile "C:\BrowserConnector-ScriptEditor.zip" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/BrowserConnector-ScriptEditor.zip"
    #Unblock the zip archive
    #Expand-Archive -Path "C:\BrowserConnector.zip" -DestinationPath "C:\Program Files\Login VSI\Login PI 3 Launcher\"
}

# Check if chrome exists, if not copy them from the virtual appliance and unzip to Launcher program files directory
<#if (-not (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"))
{
    Invoke-WebRequest -OutFile "C:\ChromeSetup.exe" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/ChromeSetup.exe"
	Start-Process -FilePath "C:\ChromeSetup.exe" -Verb runAs -ArgumentList '/silent','/install' -Wait
	#Other ways to start and exe install
	#Start-Process "c:\temp\UpdateVisualC++\vcredist_x86.exe" -ArgumentList "/q" -Wait
	#Start-Process .\installer.exe /S -NoNewWindow -Wait -PassThru
}
#>

# Run the MSFT VDI optimizer
<# if (-not (Test-Path "C:\VDIOptimizer"))
{
    Invoke-WebRequest -OutFile "C:\VDIOptimizer.zip" -Uri "https://github.com/blairparkhill/WVDConnect/raw/master/Virtual-Desktop-Optimization-Tool-master.zip"
	Expand-Archive -Path "C:\VDIOptimizer.zip" -DestinationPath "C:\VDIOptimizer\"
	Start-Process -FilePath C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe '-ExecutionPolicy RemoteSigned -File "C:\VDIOptimizer\Virtual-Desktop-Optimization-Tool-master\Win10_VirtualDesktop_Optimize.ps1" -WindowsVersion 2004 -Verbose' -Wait
}
#>

#Use this code to reboot the launcher after launcher bits are installed
#If (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe"))
#{
#    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "PILauncher_Install" -Value 'cmd /c msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log" && shutdown /r /t 0' -Force        
    
    #Start-Sleep -Seconds 120
    #msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log"
#}

#REBOOT THE MACHINE
shutdown /r /t 0 /f