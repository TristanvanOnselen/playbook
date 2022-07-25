#Parameters

$CustSn = "wc7" ##Shortname
$RG_Kvname = $CustSn + "-sentinel-weu-prd"
$AzAdGroupName = $CustSn + "-sentinel-deployment"
$resourceGroupName = (Get-AzResourceGroup -Name "*playbook*").ResourceGroupName
$location = "westeurope"
$vaultName = $RG_Kvname
$Appregname = "WC7-Sentinel-AI-LAW"

Write-Host "Prep environement for KeyVault Operations; Sentinel Playbook(s)"

$rgAzADGroup = Get-AzADGroup -DisplayName "$AzAdGroupName" -ErrorAction SilentlyContinue

if ($rgAzADGroup) {
    Write-Host "RG Azure Active Directory group; already exists"
} else {
    # Create new RG
    Write-Host "RG does not exist, attempting to create one"
    try {
        $rgAzADGroup = new-AzADGroup -DisplayName "$AzAdGroupName" -MailNickName "$AzAdGroupName" -Description "Assign permissions to members to deploy Playbooks" -ErrorAction Stop
    }
    catch {
        Write-Error $_.Exception.Message
        break
    }
}

$rg = Get-AzResourceGroup -Name "$resourceGroupName" -ErrorAction SilentlyContinue

if ($rg) {
    Write-Host "RG already exists"
} else {
    # Create new RG
    Write-Host "RG does not exist, attempting to create one"
    try {
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction Stop
    }
    catch {
        Write-Error $_.Exception.Message
        break
    }
}

$keyvaultResult = Get-AzKeyVault -ResourceGroupName $rg.ResourceGroupName -VaultName $vaultName -ErrorAction SilentlyContinue

if ($keyvaultResult) {
    Write-Host "Keyvault already exists"
} else {
    Write-Host "Keyvault does not exist, attempting to create one"
    try {
        New-AzKeyVault -Name $vaultName -ResourceGroupName $rg.ResourceGroupName -Location westeurope -EnabledForDeployment -EnabledForTemplateDeployment -ErrorAction Stop
    }
    catch {
        Write-Error $_.Exception.Message
        break
    }
}

write-host "Create App registration"

$SPN = get-AzADServicePrincipal -DisplayName $Appregname -ErrorAction SilentlyContinue

if ($SPN) {
    Write-Host "The service principle |  $AppregName already exists"
} else {
    try {
        #Create new SPN 
        New-AzADServicePrincipal -DisplayName "$AppRegName"
        $SPNID = Get-AzADServicePrincipal -DisplayName "$AppRegName"
        $Key = New-AzADSpCredential -ObjectId ($SPNID).id
        $SecretID = ConvertTo-SecureString -String ($Key).SecretText -AsPlainText -Force
        
        #Add to keyvault
        set-AzKeyVaultSecret -VaultName $vaultName -Name "SPN-API-LogAnalytics-sec" -SecretValue $SecretID
        $AppClientID = ConvertTo-SecureString -String $SPNID.AppId -AsPlainText -Force
        set-AzKeyVaultSecret -VaultName $vaultName -Name SPN-API-LogAnalytics-ID -SecretValue $AppClientID
        $TenantID = ConvertTo-SecureString -String (get-AzContext).Tenant.id -AsPlainText -Force
        set-AzKeyVaultSecret -VaultName $vaultName -Name "SPN-API-LogAnalytics-TenentID" -SecretValue $TenantID

        #Assign AZ permissions to SPN 
        $servicePrincipal = get-AzADServicePrincipal -DisplayName "WC7-Sentinel-AI-LAW"
        New-AzRoleAssignment -RoleDefinitionName "Log Analytics Reader" -ApplicationId $servicePrincipal.AppId
    }
    catch {
        Write-Error $_.Exception.Message
        break
    }
    
}

Write-Host "Setting vault access policies"
try {
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rg.ResourceGroupName -VaultName $vaultName -ObjectId $rgAzADGroup.ID  -PermissionsToSecrets All -PermissionsToKeys All -PermissionsToCertificates All -BypassObjectIdValidation
}
catch {
    Write-Error $_.Exception.Message
    break
}