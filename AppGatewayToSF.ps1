# script to add existing application gateway to azure service fabric in same resource group

param(
    $resourceGroupName = '',
    $nodeTypeName = '',
    $existingAppGatewayName = '',
    [switch]$force
)

$agw = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -Name $existingAppGatewayName
if(!$agw -or !$agw.BackendAddressPools) {
    Write-Warning "unable to enumerate existing ag or backend pool in resource group. returning"
    return
}

$vmss = Get-AzVmss -ResourceGroupName $resourceGroupName -VMScaleSetName $nodeTypeName
$vmssIpConfig = $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0]
Write-Host "old config:`r`n$($vmssIpConfig|ConvertTo-Json -depth 5)" -ForegroundColor Magenta

if(!$force -and $vmssIpConfig.ApplicationGatewayBackendAddressPools.Count -gt 0) {
    Write-Warning "vmss nic already configured for applicationgateway. returning"
    return
}

$vmssIpConfig.ApplicationGatewayBackendAddressPools = $agw.BackendAddressPools[0].Id
Write-Host "new config:`r`n$($vmssIpConfig|convertto-json -depth 5)" -ForegroundColor Cyan

Write-Host "adding configuration" -ForegroundColor Green
$vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0] = $vmssipConfig
Update-AzVmss -ResourceGroupName $resourceGroupName -VMScaleSetName $nodeTypeName -VirtualMachineScaleSet $vmss

$vmss = Get-AzVmss -ResourceGroupName $resourceGroupName -VMScaleSetName $nodeTypeName
$vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations
$vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations

write-host "finished"