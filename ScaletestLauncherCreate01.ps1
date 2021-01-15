$resourcegroup = "bp-scaletest"
$ImageName = "MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.685.2012032305"
#MachineSize = "Standard_D8ds_v4"
$MachineSize = "Standard_D8as_v4"
$Location = "eastus2"
$VnetName = "BP-EastUS2-ST-VNET"
$cred = New-Object PSCredential("blair", (ConvertTo-SecureString -AsPlainText -Force -String "LoginVSIlab!1"))
 
# $launchers = @()
# for ($i = 1; $i -le 10; $i++) {
#     $launchers += "BP-Launch{0:D3}" -f $i
# }

# let's start from 20 since 19 are already built
 $launchers = @()
 for ($i = 1; $i -le 25; $i++) {
     $launchers += "BP-Launch{0:D3}" -f $i
 }

# Changed throttle limit from 10 to 5 because some launchers didn't get installed
# due to what I believe are race conditions
# Can't use Vnet setting due to peering configuration
$launchers | foreach-object -ThrottleLimit 3 -Parallel {
    # local Admin credentials to be set on the VM
    #New-AzVM -Name BP-Launch001 -ResourceGroupName "bp-scaletest" -Image "MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.685.2012032305" -Size Standard_D8as_v4 -Location "eastus2" -Credential $cred
    #New-AzVM -Name $_ -ResourceGroupName $using:resourcegroup -Image $using:ImageName -Size $using:MachineSize -Location $using:Location -VirtualNetworkName $using:VnetName -Credential $using:cred
    New-AzVM -Name $_ -ResourceGroupName $using:resourcegroup -Image $using:ImageName -Size $using:MachineSize -Location $using:Location -Credential $using:cred
    Set-AzVMCustomScriptExtension -ResourceGroupName $using:resourcegroup `
        -VMName $_ `
        -Location $using:Location `
        -FileUri https://raw.githubusercontent.com/blairparkhill/WVDConnect/master/ScaletestLauncherBuild01.ps1 `
        -Run ScaletestLauncherBuild01.ps1 `
        -Name Launcher
}