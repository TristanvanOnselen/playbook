# Deploy 

# Deployment order
Keep the following order to deploy the playbooks (dependencies are explained later.

1. Run the script .\prep\Deploy-prereq-Playbooks.ps1 
2. Deploy the ARM template sent-Watchlist.json


# High level design

![alt-text](./scr/HLD/HLD-Playbook.png "High level overview playbooks in Sentinel")


![alt-text](./scr/HLD/HLD-Playbook-detailed-API.png "Detailed overview playbooks")


# Notes

## How to deploy the watchlist

``` PowerShell
New-AzResourceGroupDeployment -Name testing -ResourceGroupName "nf-sentinel-weu-prd" -TemplateFile .\Prep\Sent-Watchlist.json -WorkspaceName "nf-Tristan-sent-weu-prd"
``` 