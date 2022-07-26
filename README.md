# Introduction deployment Playbooks by code

The deployment of LogicApps (Sentinel Playbooks) can be implemented through code. It makes it easier for the Sentinel automation contributors to develop new SOAR capabilities in the platform without knowledge of Azure and M365 permission structures. LogicApps are object-oriented scripts executing multiple steps to escalate or close security incidents. Permissions are configured via API connectors. These use techniques such as Managed identities of service principles.

# Preperation

The Azure/M365 administrator must prepare the Cloud -environment before the Sentinel administrators can import the LogicApp templates. The preparation consists of a one-time creation of an Azure KeyVault and a Service Principle (including secretID). Keep in mind that the SecretID expires 1-year after creation (by default).


### Permissions - LogicApp API connections
Using a deployment template simplifies the configuration process; for example, forgetting to set the permissions correctly is no longer an issue. However, LogicApps use various systems, so permissions must be configured in Azure and M365. The following overview shows which rights (and groups) are used.

| Component                 | M365/Azure    |  Permissions during (one-time) deployment     | Template deployment                       |
| ---                       | ---           | ---                                           | ---                                       |
| Azure KeyVault            | Azure         | Key Vault Administrator                       | Azure Key Vault Secrets User (Get)        |
| Service principle (SPN)   | M365          | Cloud application administrator               | Not applicable                            |
| Microsoft Sentinel        | Azure         | Not applicable                                | Microsoft Sentinel Automation Contributor |
| Azure subscription        | Azure         | User Access Administrator                     | User Access Administrator                 |


DD.1 - A keyvault is used to securely store the sensitive tenant information. It also unlocks the capability to reuse the LogicApp templates in multiple tenant environments like test and production. 
DD.2 - The keyvault feature Azure Resource Manager for template deployment is enabled to support deployment by code.
R1 - We recommend using a group that has rights to all components, this group can be used in conjunction with PIM groups to acomplisch least priviled access model.
    DD.1 - The naming convention of this group is [tenantShortName]-Sentinel-deployment.

```PowerShell 
$AzAdGroupName = $CustSn + "-sentinel-deployment" ## change this to your preffered naming convention
$rgAzADGroup = Get-AzADGroup -DisplayName "$AzAdGroupName" -ErrorAction SilentlyContinue

if ($rgAzADGroup) {
    Write-Host "RG Azure Active Directory group; already exists"
} else {
    Write-Host "RG does not exist, attempting to create one"
    try {
        $rgAzADGroup = new-AzADGroup -DisplayName "$AzAdGroupName" -MailNickName "$AzAdGroupName" -Description "Assign permissions to members to deploy Playbooks" -ErrorAction Stop
    }
    catch {
        Write-Error $_.Exception.Message
        break
    }
}
```


### Permissions - Template support for API connections and permissions


| LogicApp Component    | Type of authentication    | Roles and permissions                 | Naming convention (API-Connection)    | 
| ---                   | ---                       | ---                                   | ---                                   |
| Microsoft Sentinel    | Managed System Identity   | Azure - Microsoft Sentinel responder  | MicrosoftSentinel-[playbookname]      |
| Azure Monitor Logs    | Service Principle Name    | Azure - Log Analytics Reader          | Azuremonitorlogs-[playbookname]       |

DD.2 - By using the LogicApp template, the API connections are automatically made and the permissions are distributed as described above. 
RM.1 - The permissions are set during the LogicApp deployment. Therefore user must have the Azure role User Access Administrator, Azure Contributor or Onwer. We recommend using a CI/CD pipeline, the user don't need to have the permissions assigned to his/her account but can run the code via a pipeline (Incl. auditlogging and code-validation). 

## Service principle settings
Name WC7-Sentinel-AI-LAW

## Keyvault setting





1. Run the script .\prep\Deploy-prereq-Playbooks.ps1
2. Deploy the ARM template sent-Watchlist.json

# High level design

![alt-text](./scr/HLD/HLD-Playbook.png "High level overview playbooks in Sentinel")

![alt-text](./scr/HLD/HLD-Playbook-detailed-API.png "Detailed overview playbooks")

# Notes

Link - https://github.com/Azure/Azure-Sentinel/tree/master/Tools/Playbook-ARM-Template-Generator
LInk - https://abriones.home.blog/2019/08/01/logicappserviceprincipalarm/

### How to; deploy the watchlist

```PowerShell
New-AzResourceGroupDeployment -Name testing -ResourceGroupName "nf-sentinel-weu-prd" -TemplateFile .\Prep\Sent-Watchlist.json -WorkspaceName "nf-Tristan-sent-weu-prd"
```

### How to; deploy the playbook

```PowerShell
New-AzResourceGroupDeployment -Name Deploy-Playbook -ResourceGroupName "nf-sentinel-weu-prd" -TemplateFile .\playbook\ai-sentinel-bypass-conditional-access-rule-in-Azure-AD\azuredeploy.json
```

### Issues

No known issues
