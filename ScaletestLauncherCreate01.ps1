$resourcegroup = "bp-scaletest"
$location = "eastus2"
$ImageName = "MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.685.2012032305"
 
$launchers = @()
for ($i = 1; $i -le 2; $i++) {
    $launchers += "BP-Launch{0:D3}" -f $i
}
$launchers | foreach-object -ThrottleLimit 10 -Parallel {
    # local Admin credentials to be set on the VM
    $cred = New-Object PSCredential("blair", (ConvertTo-SecureString -AsPlainText -Force -String "LoginVSIlab!1"))
    #New-AzVM -Name BP-Launch001 -ResourceGroupName "bp-scaletest" -Image "MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.685.2012032305" -Size Standard_D8as_v4 -Location "eastus2" -Credential $cred
    New-AzVM -Name $_ -ResourceGroupName $resourcegroup -Image $ImageName -Size Standard_D8as_v4 -Location $location -Credential $cred
    Set-AzVMCustomScriptExtension -ResourceGroupName $resourcegroup `
        -VMName $_ `
        -Location $location `
        -FileUri https://raw.githubusercontent.com/blairparkhill/WVDConnect/master/ScaletestLauncherBuild01.ps1 `
        -Run ScaletestLauncherBuild01.ps1 `
        -Name Launcher
}