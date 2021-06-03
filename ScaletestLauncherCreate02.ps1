$resourcegroup = "BP-WVD-LoginVSI"
$ImageName = "MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.928.2104091205"
$MachineSize = "Standard_D8s_v4"
#$MachineSize = "Standard_D8as_v4"
$Location = "westus2"
$VnetName = "BP-WVD-LoginVSI-vnet"
$cred = New-Object PSCredential("blair", (ConvertTo-SecureString -AsPlainText -Force -String "LoginVSIlab!1"))
 
# tell the script how many launchers you want
 $launchers = @()
 for ($i = 1; $i -le 4; $i++) {
     $launchers += "BP-WVDLaunch{0:D3}" -f $i
 }

# Changed throttle limit from 10 to 5 because some launchers didn't get installed
# due to what I believe are race conditions
# Can't use Vnet setting due to peering configuration
$launchers | foreach-object -ThrottleLimit 4 -Parallel {
    # local Admin credentials to be set on the VM
    New-AzVM -Name $_ -ResourceGroupName $using:resourcegroup -Image $using:ImageName -Size $using:MachineSize -Location $using:Location -Credential $using:cred
    Set-AzVMCustomScriptExtension -ResourceGroupName $using:resourcegroup `
        -VMName $_ `
        -Location $using:Location `
        -FileUri https://raw.githubusercontent.com/blairparkhill/WVDConnect/master/ScaletestLauncherBuild02.ps1 `
        -Run ScaletestLauncherBuild02.ps1 `
        -Name Launcher
}