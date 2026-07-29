param location string = 'switzerlandnorth'
param sshPublicKey string
param adminUsername string = 'azureuser'
resource vnet 'Microsoft.Network/virtualNetworks@2025-07-01' = {
    name: 'vnet-project4'
    location: location
     properties: {
         addressSpace: {
             addressPrefixes: [
                '10.40.0.0/16'
             ]
         } 
          subnets: [
             {
                 name: 'web-subnet'
                 properties: {
                     addressPrefix: '10.40.10.0/24'
                      networkSecurityGroup: {
                         id: webNsg.id
                      }
                 }
             } 
              {
                 name: 'management-subnet'
                  properties: {
                     addressPrefix: '10.40.20.0/24'
                  }
              }
          ] 
     }
}
output vnetID string = vnet.id
resource webNsg 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
    name: 'nsg-web-project4'
    location: location
     properties: {
         securityRules: [
             {
                 name: 'allow-http'
                  properties: {
                    access: 'Allow'
                    direction: 'Inbound'
                    priority: 100
                    protocol: 'Tcp' 
                     sourceAddressPrefix: '*'
                    destinationAddressPrefix: '*'
                     sourcePortRange: '*'
                     destinationPortRange: '80'
                  } 
                                             
             } 
           {
        name: 'allow-ssh'
         properties: {
            access:  'Allow'
            direction:  'Inbound'
            priority: 110  
            protocol: 'Tcp'
             sourceAddressPrefix: '*'
              sourcePortRange: '*'  
              destinationAddressPrefix: '*'
             destinationPortRange: '22'
         }
           }     
              
         ]
     }
}
resource publicIp 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
    name: 'pip-web-project4'
    location: location
     sku: {
         name: 'Standard' 
     }
     properties: {
         publicIPAllocationMethod: 'Static'
     }
    } 
     resource webNic 'Microsoft.Network/networkInterfaces@2025-07-01' = {
        name: 'nic-web-project4'
        location: location
        properties: {
             ipConfigurations: [
                 {
                     name: 'ipconfig1'
                     properties: {
                         subnet: {
                             id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'web-subnet')
                         }
                          publicIPAddress: {
                             id: publicIp.id
                          }
                          privateIPAllocationMethod: 'Dynamic'
  }                         
                     }
                 
             ]
        }
     }
resource vm 'Microsoft.Compute/virtualMachines@2026-03-01' = {
    name: 'vm-web-project4'
    location:  location
     properties: {
         hardwareProfile: {
             vmSize: 'Standard_B2s_v2'
         }
         networkProfile: {
             networkInterfaces: [
                 {
                     id: webNic.id
                 }
             ]
         }
          storageProfile: {
             imageReference: {
                  publisher: 'Canonical'
                   offer: 'ubuntu-24_04-lts'
                    sku: 'server'
                     version: 'latest'
             }
             osDisk: {
                createOption: 'FromImage'
                 managedDisk: {
                     storageAccountType: 'Standard_LRS'
                 }
             }
          }
           osProfile: {
             computerName: 'webserver'
             adminUsername: adminUsername
             linuxConfiguration: {
                 disablePasswordAuthentication: true
                 ssh: {
                     publicKeys: [
                         {
                             path: '/home/${adminUsername}/.ssh/authorized_keys'
                              keyData: sshPublicKey 
                         }
                     ]
                 }
             }
           }
     }
      zones: [
        '1'
      ]
}
resource storage 'Microsoft.Storage/storageAccounts@2026-04-01' = {
    name:  'ssttoorraaggee280289'
    location:  location
    sku: { 
        name: 'Standard_LRS' 
    }
    kind:  'StorageV2'
    properties: {
         supportsHttpsTrafficOnly: true 
         minimumTlsVersion: 'TLS1_2'
         allowBlobPublicAccess: false
    }
    
}
