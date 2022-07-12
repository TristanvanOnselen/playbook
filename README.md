# Deploy 

New-AzResourceGroupDeployment -Name testing -ResourceGroupName "nf-sentinel-weu-prd" -TemplateFile .\Prep\Watchlist.json -WorkspaceName "nf-Tristan-sent-weu-prd"