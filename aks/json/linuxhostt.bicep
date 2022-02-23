{
  "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "metadata": {
    "_generator": {
      "name": "bicep",
      "version": "0.3.255.40792",
      "templateHash": "11638631632085695904"
    }
  },
  "parameters": {
    "adUserId": {
      "type": "string",
      "defaultValue": "",
      "metadata": {
        "description": "Used to set the Keyvault access policy - run this command using az cli to get your ObjectID : az ad signed-in-user show --query objectId -o tsv"
      },
      "maxLength": 36,
      "minLength": 36
    },
    "ResourceGroupName": {
      "type": "string",
      "defaultValue": "linuxhost",
      "maxLength": 10,
      "minLength": 3,
      "metadata": {
        "description": "Set the resource group name, this will be created automatically"
      }
    },
    "HostVmSize": {
      "type": "string",
      "defaultValue": "Standard_D2_v3",
      "minLength": 6,
      "metadata": {
        "description": "Set the size for the VM"
      }
    }
  },
  "functions": [],
  "variables": {
    "VmAdminUsername": "localadmin",
    "VmHostnamePrefix": "linux-host-",
    "numberOfHosts": 2,
    "location": "[deployment().location]",
    "vnets": [
      {
        "vnetName": "hubVnet",
        "vnetAddressPrefix": "172.16.0.0/16",
        "subnets": [
          {
            "name": "main",
            "prefix": "172.16.24.0/24",
            "customNsg": true
          },
          {
            "name": "AzureBastionSubnet",
            "prefix": "172.16.254.0/24",
            "customNsg": true
          }
        ]
      }
    ]
  },
  "resources": [
    {
      "type": "Microsoft.Resources/resourceGroups",
      "apiVersion": "2021-04-01",
      "name": "[parameters('ResourceGroupName')]",
      "location": "[variables('location')]"
    },
    {
      "copy": {
        "name": "virtualnetwork",
        "count": "[length(variables('vnets'))]"
      },
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "[variables('vnets')[copyIndex()].vnetName]",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "vnetName": {
            "value": "[variables('vnets')[copyIndex()].vnetName]"
          },
          "vnetAddressPrefix": {
            "value": "[variables('vnets')[copyIndex()].vnetAddressPrefix]"
          },
          "location": {
            "value": "[variables('location')]"
          },
          "subnets": {
            "value": "[variables('vnets')[copyIndex()].subnets]"
          },
          "nsgDefaultId": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'default-nsg'), '2019-10-01').outputs.nsgId.value]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "7876870634813934177"
            }
          },
          "parameters": {
            "subnets": {
              "type": "array"
            },
            "vnetName": {
              "type": "string"
            },
            "vnetAddressPrefix": {
              "type": "string"
            },
            "location": {
              "type": "string"
            },
            "nsgDefaultId": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.Network/virtualNetworks",
              "apiVersion": "2021-02-01",
              "name": "[parameters('vnetName')]",
              "location": "[parameters('location')]",
              "properties": {
                "copy": [
                  {
                    "name": "subnets",
                    "count": "[length(parameters('subnets'))]",
                    "input": {
                      "name": "[parameters('subnets')[copyIndex('subnets')].name]",
                      "properties": {
                        "addressPrefix": "[parameters('subnets')[copyIndex('subnets')].prefix]",
                        "networkSecurityGroup": "[if(parameters('subnets')[copyIndex('subnets')].customNsg, null(), createObject('id', parameters('nsgDefaultId'), 'location', parameters('location'), 'properties', createObject()))]"
                      }
                    }
                  }
                ],
                "addressSpace": {
                  "addressPrefixes": [
                    "[parameters('vnetAddressPrefix')]"
                  ]
                }
              }
            }
          ],
          "outputs": {
            "vnid": {
              "type": "string",
              "value": "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetName'))]"
            },
            "vnName": {
              "type": "string",
              "value": "[parameters('vnetName')]"
            },
            "subnets": {
              "type": "array",
              "value": "[reference(resourceId('Microsoft.Network/virtualNetworks', parameters('vnetName'))).subnets]"
            }
          }
        }
      },
      "dependsOn": [
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'default-nsg')]",
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]"
      ]
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "kv",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "location": {
            "value": "[variables('location')]"
          },
          "adUserId": {
            "value": "[parameters('adUserId')]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "220683448064609268"
            }
          },
          "parameters": {
            "location": {
              "type": "string",
              "defaultValue": "[resourceGroup().location]"
            },
            "tenantId": {
              "type": "string",
              "defaultValue": "[subscription().tenantId]"
            },
            "keyvaultname": {
              "type": "string",
              "defaultValue": "[format('{0}-{1}', resourceGroup().name, uniqueString(resourceGroup().id))]"
            },
            "adUserId": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.KeyVault/vaults",
              "apiVersion": "2019-09-01",
              "name": "[parameters('keyvaultname')]",
              "location": "[parameters('location')]",
              "properties": {
                "enabledForDeployment": false,
                "enabledForTemplateDeployment": true,
                "enabledForDiskEncryption": false,
                "enableSoftDelete": false,
                "accessPolicies": [
                  {
                    "objectId": "[parameters('adUserId')]",
                    "tenantId": "[parameters('tenantId')]",
                    "permissions": {
                      "keys": [
                        "get",
                        "list",
                        "update",
                        "create",
                        "import",
                        "delete",
                        "recover",
                        "backup",
                        "restore"
                      ],
                      "secrets": [
                        "get",
                        "list",
                        "set",
                        "delete",
                        "recover",
                        "backup",
                        "restore"
                      ],
                      "certificates": [
                        "get",
                        "list",
                        "update",
                        "create",
                        "import",
                        "delete",
                        "recover",
                        "backup",
                        "restore",
                        "managecontacts",
                        "manageissuers",
                        "getissuers",
                        "listissuers",
                        "setissuers",
                        "deleteissuers"
                      ]
                    }
                  }
                ],
                "tenantId": "[parameters('tenantId')]",
                "sku": {
                  "name": "standard",
                  "family": "A"
                }
              }
            }
          ],
          "outputs": {
            "keyvaultid": {
              "type": "string",
              "value": "[resourceId('Microsoft.KeyVault/vaults', parameters('keyvaultname'))]"
            },
            "keyvaultname": {
              "type": "string",
              "value": "[parameters('keyvaultname')]"
            }
          }
        }
      },
      "dependsOn": [
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]"
      ]
    },
    {
      "copy": {
        "name": "linuxhost",
        "count": "[length(range(1, variables('numberOfHosts')))]"
      },
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "[format('{0}{1}', variables('VmHostnamePrefix'), range(1, variables('numberOfHosts'))[copyIndex()])]",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "location": {
            "value": "[variables('location')]"
          },
          "deployPIP": {
            "value": true
          },
          "windowsVM": {
            "value": false
          },
          "deployDC": {
            "value": false
          },
          "adminusername": {
            "value": "[variables('VmAdminUsername')]"
          },
          "keyvault_name": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'kv'), '2019-10-01').outputs.keyvaultname.value]"
          },
          "vmname": {
            "value": "[format('{0}{1}', variables('VmHostnamePrefix'), range(1, variables('numberOfHosts'))[copyIndex()])]"
          },
          "subnet1ref": {
            "value": "[format('{0}/subnets/{1}', reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.vnid.value, reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.subnets.value[0].name)]"
          },
          "vmSize": {
            "value": "[parameters('HostVmSize')]"
          },
          "adUserId": {
            "value": "[parameters('adUserId')]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "3875822902609976758"
            }
          },
          "parameters": {
            "adminusername": {
              "type": "string"
            },
            "keyvault_name": {
              "type": "string"
            },
            "vmname": {
              "type": "string"
            },
            "subnet1ref": {
              "type": "string"
            },
            "adUserId": {
              "type": "string"
            },
            "adminPassword": {
              "type": "secureString",
              "defaultValue": "[format('{0}aA1!{1}', uniqueString(resourceGroup().id, parameters('vmname')), uniqueString(parameters('adUserId')))]"
            },
            "windowsVM": {
              "type": "bool"
            },
            "vmSize": {
              "type": "string",
              "metadata": {
                "description": "Size of the virtual machine."
              }
            },
            "location": {
              "type": "string",
              "defaultValue": "[resourceGroup().location]",
              "metadata": {
                "description": "location for all resources"
              }
            },
            "publicIPAddressNameSuffix": {
              "type": "string",
              "defaultValue": "pip"
            },
            "deployPIP": {
              "type": "bool",
              "defaultValue": false
            },
            "deployVpn": {
              "type": "bool",
              "defaultValue": false
            },
            "deployDC": {
              "type": "bool",
              "defaultValue": false
            }
          },
          "functions": [],
          "variables": {
            "dcdisk": [
              {
                "diskSizeGB": 20,
                "lun": 0,
                "createOption": "Empty"
              }
            ],
            "storageAccountName": "[uniqueString(resourceGroup().id, parameters('vmname'))]",
            "nicName": "[format('{0}nic', parameters('vmname'))]",
            "dnsLabelPrefix": "[format('dns-{0}-{1}', uniqueString(resourceGroup().id, parameters('vmname')), parameters('publicIPAddressNameSuffix'))]"
          },
          "resources": [
            {
              "condition": "[parameters('deployPIP')]",
              "type": "Microsoft.Network/publicIPAddresses",
              "apiVersion": "2020-06-01",
              "name": "[format('{0}-{1}', variables('nicName'), parameters('publicIPAddressNameSuffix'))]",
              "location": "[parameters('location')]",
              "properties": {
                "publicIPAllocationMethod": "Static",
                "dnsSettings": {
                  "domainNameLabel": "[variables('dnsLabelPrefix')]"
                }
              }
            },
            {
              "type": "Microsoft.Storage/storageAccounts",
              "apiVersion": "2019-06-01",
              "name": "[variables('storageAccountName')]",
              "location": "[parameters('location')]",
              "sku": {
                "name": "Standard_LRS"
              },
              "kind": "Storage"
            },
            {
              "condition": "[parameters('deployPIP')]",
              "type": "Microsoft.Network/networkInterfaces",
              "apiVersion": "2020-06-01",
              "name": "[format('{0}pip', variables('nicName'))]",
              "location": "[parameters('location')]",
              "properties": {
                "enableIPForwarding": "[if(parameters('deployVpn'), true(), false())]",
                "ipConfigurations": [
                  {
                    "name": "ipconfig1",
                    "properties": {
                      "privateIPAllocationMethod": "Dynamic",
                      "publicIPAddress": {
                        "id": "[resourceId('Microsoft.Network/publicIPAddresses', format('{0}-{1}', variables('nicName'), parameters('publicIPAddressNameSuffix')))]"
                      },
                      "subnet": {
                        "id": "[parameters('subnet1ref')]"
                      }
                    }
                  }
                ]
              },
              "dependsOn": [
                "[resourceId('Microsoft.Network/publicIPAddresses', format('{0}-{1}', variables('nicName'), parameters('publicIPAddressNameSuffix')))]"
              ]
            },
            {
              "condition": "[not(parameters('deployPIP'))]",
              "type": "Microsoft.Network/networkInterfaces",
              "apiVersion": "2020-06-01",
              "name": "[variables('nicName')]",
              "location": "[parameters('location')]",
              "properties": {
                "enableIPForwarding": "[if(parameters('deployVpn'), true(), false())]",
                "ipConfigurations": [
                  {
                    "name": "ipconfig1",
                    "properties": {
                      "privateIPAllocationMethod": "Dynamic",
                      "subnet": {
                        "id": "[parameters('subnet1ref')]"
                      }
                    }
                  }
                ]
              }
            },
            {
              "type": "Microsoft.Compute/virtualMachines",
              "apiVersion": "2020-06-01",
              "name": "[parameters('vmname')]",
              "location": "[parameters('location')]",
              "properties": {
                "hardwareProfile": {
                  "vmSize": "[parameters('vmSize')]"
                },
                "osProfile": {
                  "computerName": "[parameters('vmname')]",
                  "adminUsername": "[parameters('adminusername')]",
                  "adminPassword": "[parameters('adminPassword')]"
                },
                "storageProfile": {
                  "imageReference": {
                    "publisher": "[if(parameters('windowsVM'), 'MicrosoftWindowsServer', 'canonical')]",
                    "offer": "[if(parameters('windowsVM'), 'WindowsServer', '0001-com-ubuntu-server-focal')]",
                    "sku": "[if(parameters('windowsVM'), '2019-Datacenter', '20_04-lts')]",
                    "version": "[if(parameters('windowsVM'), 'latest', 'latest')]"
                  },
                  "osDisk": {
                    "createOption": "FromImage"
                  },
                  "dataDisks": "[if(parameters('deployDC'), variables('dcdisk'), null())]"
                },
                "networkProfile": {
                  "networkInterfaces": [
                    {
                      "id": "[if(parameters('deployPIP'), resourceId('Microsoft.Network/networkInterfaces', format('{0}pip', variables('nicName'))), resourceId('Microsoft.Network/networkInterfaces', variables('nicName')))]"
                    }
                  ]
                },
                "diagnosticsProfile": {
                  "bootDiagnostics": {
                    "enabled": true,
                    "storageUri": "[reference(resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))).primaryEndpoints.blob]"
                  }
                }
              },
              "dependsOn": [
                "[resourceId('Microsoft.Network/networkInterfaces', format('{0}pip', variables('nicName')))]",
                "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]",
                "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
              ]
            },
            {
              "type": "Microsoft.KeyVault/vaults/secrets",
              "apiVersion": "2019-09-01",
              "name": "[format('{0}/{1}-admin-password', parameters('keyvault_name'), parameters('vmname'))]",
              "properties": {
                "contentType": "securestring",
                "value": "[parameters('adminPassword')]",
                "attributes": {
                  "enabled": true
                }
              }
            },
            {
              "type": "Microsoft.KeyVault/vaults/secrets",
              "apiVersion": "2019-09-01",
              "name": "[format('{0}/{1}-admin-username', parameters('keyvault_name'), parameters('vmname'))]",
              "properties": {
                "contentType": "string",
                "value": "[parameters('adminusername')]",
                "attributes": {
                  "enabled": true
                }
              }
            }
          ],
          "outputs": {
            "vmPip": {
              "type": "string",
              "value": "[if(parameters('deployPIP'), reference(resourceId('Microsoft.Network/publicIPAddresses', format('{0}-{1}', variables('nicName'), parameters('publicIPAddressNameSuffix')))).dnsSettings.fqdn, '')]"
            },
            "vmIp": {
              "type": "string",
              "value": "[if(parameters('deployPIP'), reference(resourceId('Microsoft.Network/publicIPAddresses', format('{0}-{1}', variables('nicName'), parameters('publicIPAddressNameSuffix')))).ipAddress, '')]"
            },
            "vmPrivIp": {
              "type": "string",
              "value": "[if(parameters('deployPIP'), reference(resourceId('Microsoft.Network/networkInterfaces', format('{0}pip', variables('nicName')))).ipConfigurations[0].properties.privateIPAddress, '')]"
            }
          }
        }
      },
      "dependsOn": [
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'kv')]",
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]"
      ]
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "hubBastion",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "bastionHostName": {
            "value": "hubBastion"
          },
          "location": {
            "value": "[variables('location')]"
          },
          "subnetRef": {
            "value": "[format('{0}/subnets/{1}', reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.vnid.value, reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.subnets.value[1].name)]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "2412912973001245325"
            }
          },
          "parameters": {
            "subnetRef": {
              "type": "string"
            },
            "bastionHostName": {
              "type": "string"
            },
            "location": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.Network/publicIPAddresses",
              "apiVersion": "2020-06-01",
              "name": "[format('{0}-pip', parameters('bastionHostName'))]",
              "location": "[parameters('location')]",
              "sku": {
                "name": "Standard"
              },
              "properties": {
                "publicIPAllocationMethod": "Static"
              }
            },
            {
              "type": "Microsoft.Network/bastionHosts",
              "apiVersion": "2020-06-01",
              "name": "[parameters('bastionHostName')]",
              "location": "[parameters('location')]",
              "properties": {
                "ipConfigurations": [
                  {
                    "name": "IpConf",
                    "properties": {
                      "subnet": {
                        "id": "[parameters('subnetRef')]"
                      },
                      "publicIPAddress": {
                        "id": "[resourceId('Microsoft.Network/publicIPAddresses', format('{0}-pip', parameters('bastionHostName')))]"
                      }
                    }
                  }
                ]
              },
              "dependsOn": [
                "[resourceId('Microsoft.Network/publicIPAddresses', format('{0}-pip', parameters('bastionHostName')))]"
              ]
            }
          ]
        }
      },
      "dependsOn": [
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]"
      ]
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "hubNSG",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "location": {
            "value": "[variables('location')]"
          },
          "destinationAddressPrefix": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.subnets.value[0].properties.addressPrefix]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "779060282370331211"
            }
          },
          "parameters": {
            "location": {
              "type": "string"
            },
            "destinationAddressPrefix": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.Network/networkSecurityGroups",
              "apiVersion": "2020-06-01",
              "name": "Allow-tunnel-traffic",
              "location": "[parameters('location')]",
              "properties": {
                "securityRules": [
                  {
                    "name": "allow-ssh-inbound",
                    "properties": {
                      "priority": 1000,
                      "access": "Deny",
                      "direction": "Inbound",
                      "destinationPortRange": "22",
                      "protocol": "Tcp",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "127.0.0.1",
                      "destinationAddressPrefix": "[parameters('destinationAddressPrefix')]"
                    }
                  }
                ]
              }
            }
          ],
          "outputs": {
            "nsgId": {
              "type": "string",
              "value": "[resourceId('Microsoft.Network/networkSecurityGroups', 'Allow-tunnel-traffic')]"
            }
          }
        }
      },
      "dependsOn": [
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]"
      ]
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "bastionNSG",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "location": {
            "value": "[variables('location')]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "8737959745079293917"
            }
          },
          "parameters": {
            "location": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.Network/networkSecurityGroups",
              "apiVersion": "2020-06-01",
              "name": "azure-bastion-nsg",
              "location": "[parameters('location')]",
              "properties": {
                "securityRules": [
                  {
                    "name": "AllowHttpsInbound",
                    "properties": {
                      "priority": 120,
                      "access": "Allow",
                      "direction": "Inbound",
                      "destinationPortRange": "443",
                      "protocol": "Tcp",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "Internet",
                      "destinationAddressPrefix": "*"
                    }
                  },
                  {
                    "name": "AllowGatewayManagerInbound",
                    "properties": {
                      "priority": 130,
                      "access": "Allow",
                      "direction": "Inbound",
                      "destinationPortRange": "443",
                      "protocol": "Tcp",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "GatewayManager",
                      "destinationAddressPrefix": "*"
                    }
                  },
                  {
                    "name": "AllowAzureLoadBalancerInbound",
                    "properties": {
                      "priority": 140,
                      "access": "Allow",
                      "direction": "Inbound",
                      "destinationPortRange": "443",
                      "protocol": "Tcp",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "AzureLoadBalancer",
                      "destinationAddressPrefix": "*"
                    }
                  },
                  {
                    "name": "AllowBastionHostCommunication",
                    "properties": {
                      "priority": 150,
                      "access": "Allow",
                      "direction": "Inbound",
                      "destinationPortRanges": [
                        "8080",
                        "5701"
                      ],
                      "protocol": "*",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "VirtualNetwork",
                      "destinationAddressPrefix": "VirtualNetwork"
                    }
                  },
                  {
                    "name": "AllowSshRdpOutbound",
                    "properties": {
                      "priority": 100,
                      "access": "Allow",
                      "direction": "Outbound",
                      "destinationPortRanges": [
                        "22",
                        "3389"
                      ],
                      "protocol": "*",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "*",
                      "destinationAddressPrefix": "VirtualNetwork"
                    }
                  },
                  {
                    "name": "AllowAzureCloudOutbound",
                    "properties": {
                      "priority": 110,
                      "access": "Allow",
                      "direction": "Outbound",
                      "destinationPortRange": "443",
                      "protocol": "Tcp",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "*",
                      "destinationAddressPrefix": "AzureCloud"
                    }
                  },
                  {
                    "name": "AllowBastionCommunication",
                    "properties": {
                      "priority": 120,
                      "access": "Allow",
                      "direction": "Outbound",
                      "destinationPortRanges": [
                        "8080",
                        "5701"
                      ],
                      "protocol": "*",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "VirtualNetwork",
                      "destinationAddressPrefix": "VirtualNetwork"
                    }
                  },
                  {
                    "name": "AllowGetSessionInformation",
                    "properties": {
                      "priority": 130,
                      "access": "Allow",
                      "direction": "Outbound",
                      "destinationPortRange": "80",
                      "protocol": "*",
                      "sourcePortRange": "*",
                      "sourceAddressPrefix": "*",
                      "destinationAddressPrefix": "Internet"
                    }
                  }
                ]
              }
            }
          ],
          "outputs": {
            "nsgId": {
              "type": "string",
              "value": "[resourceId('Microsoft.Network/networkSecurityGroups', 'azure-bastion-nsg')]"
            }
          }
        }
      },
      "dependsOn": [
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]"
      ]
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "default-nsg",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "location": {
            "value": "[variables('location')]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "13819023913916015331"
            }
          },
          "parameters": {
            "location": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.Network/networkSecurityGroups",
              "apiVersion": "2020-06-01",
              "name": "default-nsg",
              "location": "[parameters('location')]",
              "properties": {}
            }
          ],
          "outputs": {
            "nsgId": {
              "type": "string",
              "value": "[resourceId('Microsoft.Network/networkSecurityGroups', 'default-nsg')]"
            }
          }
        }
      },
      "dependsOn": [
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]"
      ]
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "mainNsgAttachment",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "nsgId": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'hubNSG'), '2019-10-01').outputs.nsgId.value]"
          },
          "subnetAddressPrefix": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.subnets.value[0].properties.addressPrefix]"
          },
          "subnetName": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.subnets.value[0].name]"
          },
          "vnetName": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.vnName.value]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "16856926705061277472"
            }
          },
          "parameters": {
            "vnetName": {
              "type": "string"
            },
            "subnetName": {
              "type": "string"
            },
            "subnetAddressPrefix": {
              "type": "string"
            },
            "nsgId": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.Network/virtualNetworks/subnets",
              "apiVersion": "2020-07-01",
              "name": "[format('{0}/{1}', parameters('vnetName'), parameters('subnetName'))]",
              "properties": {
                "addressPrefix": "[parameters('subnetAddressPrefix')]",
                "networkSecurityGroup": {
                  "id": "[parameters('nsgId')]"
                }
              }
            }
          ]
        }
      },
      "dependsOn": [
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'hubNSG')]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]"
      ]
    },
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2019-10-01",
      "name": "bastionNsgAttachment",
      "resourceGroup": "[parameters('ResourceGroupName')]",
      "properties": {
        "expressionEvaluationOptions": {
          "scope": "inner"
        },
        "mode": "Incremental",
        "parameters": {
          "nsgId": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'bastionNSG'), '2019-10-01').outputs.nsgId.value]"
          },
          "subnetAddressPrefix": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.subnets.value[1].properties.addressPrefix]"
          },
          "subnetName": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.subnets.value[1].name]"
          },
          "vnetName": {
            "value": "[reference(extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName), '2019-10-01').outputs.vnName.value]"
          }
        },
        "template": {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "metadata": {
            "_generator": {
              "name": "bicep",
              "version": "0.3.255.40792",
              "templateHash": "16856926705061277472"
            }
          },
          "parameters": {
            "vnetName": {
              "type": "string"
            },
            "subnetName": {
              "type": "string"
            },
            "subnetAddressPrefix": {
              "type": "string"
            },
            "nsgId": {
              "type": "string"
            }
          },
          "functions": [],
          "resources": [
            {
              "type": "Microsoft.Network/virtualNetworks/subnets",
              "apiVersion": "2020-07-01",
              "name": "[format('{0}/{1}', parameters('vnetName'), parameters('subnetName'))]",
              "properties": {
                "addressPrefix": "[parameters('subnetAddressPrefix')]",
                "networkSecurityGroup": {
                  "id": "[parameters('nsgId')]"
                }
              }
            }
          ]
        }
      },
      "dependsOn": [
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', 'bastionNSG')]",
        "[subscriptionResourceId('Microsoft.Resources/resourceGroups', parameters('ResourceGroupName'))]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]",
        "[extensionResourceId(format('/subscriptions/{0}/resourceGroups/{1}', subscription().subscriptionId, parameters('ResourceGroupName')), 'Microsoft.Resources/deployments', variables('vnets')[0].vnetName)]"
      ]
    }
  ]
}