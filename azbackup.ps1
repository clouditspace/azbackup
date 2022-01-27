#Variables
$RG = 'TF' #Resource Group Name
$Location = 'eastus'
$RSVault = 'Vault4'
$Redundancy = 'LocallyRedundant' #Storage Redundancy settings - LocallyRedundant/GeoRedundant
$Time = '5:00' #Preferred Time to start Backup
$Duration = '365' #Duration of Backup
$PolicyName = 'NewPolicy'
$VMName = 'test2'
$BackupName = 'test-Backup'
$WorkLoadType = "AzureVM"

#PowerShell Code
Write-Host "Registering the Azure Recovery Service provider in the subscription" 
try {
    Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices" -ErrorAction SilentlyContinue
	}
catch {
    $message = $_
    Write-Warning "An error occured! $message"
}
Write-Host "Creating Azure Recovery Service Vault and setting Vault context, Redundancy settings"
Get-AzRecoveryServicesVault -ResourceGroupName $RG -Name $RSVault -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
    {
    New-AzRecoveryServicesVault -ResourceGroupName $RG -Name $RSVault -Location $Location
    Get-AzRecoveryServicesVault -Name $RSVault | Set-AzRecoveryServicesVaultContext
    }
else
    {
   Write-Host "Azure Recovery Service Vault $RSVault already exists. Skipping the Vault creation.."
    }
$vault = Get-AzRecoveryServicesVault -ResourceGroupName $RG -Name $RSVault
Get-AzRecoveryServicesVault -Name $RSVault | Set-AzRecoveryServicesBackupProperty -BackupStorageRedundancy $Redundancy
Write-Host "Checking for a valid Backup Policy"
Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
    {
    $SchPol = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType $WorkLoadType 
    $SchPol.ScheduleRunTimes.Clear()
    [DATETIME]$Time = $Time
    $Time=$Time.ToUniversalTime()
    $SchPol.ScheduleRunTimes.Add($Time)
    $RetPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType $WorkLoadType 
    $RetPol.DailySchedule.DurationCountInDays = $Duration
	New-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName -WorkloadType $WorkLoadType -RetentionPolicy $RetPol -SchedulePolicy $SchPol
    }

Write-Host "Applying the BackupProtection policy to the VM"
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
try {
	Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $RG -Name $VMName -Policy $policy -ErrorAction SilentlyContinue
	}
catch {
    $message = $_
    Write-Warning "An error occured! $message"
}
$backupcontainer = Get-AzRecoveryServicesBackupContainer -ContainerType  $WorkLoadType -FriendlyName $VMName
$item = Get-AzRecoveryServicesBackupItem -container $backupcontainer -WorkloadType $WorkLoadType
Write-Host "Starting the Backing up of VM in $RSVault"
try {
	Backup-AzRecoveryServicesBackupItem -Item $item -ErrorAction SilentlyContinue
	}
catch {
    $message = $_
    Write-Warning "An error occured! $message"
}
