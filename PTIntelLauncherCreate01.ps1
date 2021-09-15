$resourcegroup = "Intel_East"
$ImageName = "MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.1110.2107101719"
#to get latest image run this Get-AzVMImage -Location EastUS -PublisherName "MicrosoftWindowsDesktop" -Offer "Windows-10"-Skus "20h1-pro"
#Get-AzVMImage -Location EastUS -PublisherName "MicrosoftWindowsDesktop" -Offer "Windows-10"-Skus "20h1-pro"
#$MachineSize = "Standard_D8ds_v4"
$MachineSize = "Standard_D8s_v4"
$Location = "eastus"
$VnetName = "Intel_vnet"
$cred = New-Object PSCredential("igadmin", (ConvertTo-SecureString -AsPlainText -Force -String "PTVSIIntel@1"))
 
# $launchers = @()
# for ($i = 1; $i -le 8; $i++) {
#     $launchers += "BP-Launch{0:D3}" -f $i
# }

# tell the script how many launchers you want
 $launchers = @()
 for ($i = 1; $i -le 4; $i++) {
     $launchers += "PTIntel-Launch{0:D3}" -f $i
 }

# Changed throttle limit from 10 to 5 because some launchers didn't get installed
# due to what I believe are race conditions
# Can't use Vnet setting due to peering configuration
$launchers | foreach-object -ThrottleLimit 4 -Parallel {
    # local Admin credentials to be set on the VM
    #New-AzVM -Name BP-Launch001 -ResourceGroupName "bp-scaletest" -Image "MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.685.2012032305" -Size Standard_D8as_v4 -Location "eastus2" -Credential $cred
    #New-AzVM -Name $_ -ResourceGroupName $using:resourcegroup -Image $using:ImageName -Size $using:MachineSize -Location $using:Location -VirtualNetworkName $using:VnetName -Credential $using:cred
    New-AzVM -Name $_ -ResourceGroupName $using:resourcegroup -Image $using:ImageName -Size $using:MachineSize -Location $using:Location -Credential $using:cred
    Set-AzVMCustomScriptExtension -ResourceGroupName $using:resourcegroup `
        -VMName $_ `
        -Location $using:Location `
        -FileUri https://raw.githubusercontent.com/blairparkhill/WVDConnect/master/PTIntelLauncherBuild01.ps1 `
        -Run PTIntelLauncherBuild01.ps1 `
        -Name Launcher
}