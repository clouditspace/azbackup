Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices" -ErrorAction SilentlyContinue
New-AzRecoveryServicesVault -ResourceGroupName $(ResourceGroupName) -Name "azBackupVault" -Location $(location) -ErrorAction SilentlyContinue
Get-AzRecoveryServicesVault -Name "azBackupVault" | Set-AzRecoveryServicesVaultContext -ErrorAction SilentlyContinue
Get-AzRecoveryServicesVault -Name "azBackupVault" | Set-AzRecoveryServicesBackupProperty -BackupStorageRedundancy LocallyRedundant/GeoRedundant -ErrorAction SilentlyContinue
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy" -ErrorAction SilentlyContinue
Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $(ResourceGroupName) -Name "test" -Policy $policy -ErrorAction SilentlyContinue
$backupcontainer = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -FriendlyName "testVM" -ErrorAction SilentlyContinue
$item = Get-AzRecoveryServicesBackupItem -Container $backupcontainer -WorkloadType "AzureVM" -ErrorAction SilentlyContinue
Backup-AzRecoveryServicesBackupItem -Item $item -ErrorAction SilentlyContinue
