# Azure Infrastructure as Code with Bicep

## Project Overview

In this project, I used Bicep to deploy a small Azure infrastructure environment.

This was my first complete Bicep project. My main goal was to move beyond learning what Infrastructure as Code (IaC) is and get practical experience writing, deploying, verifying, and troubleshooting Bicep.

I created the infrastructure in a single `main.bicep` file and deployed it to Azure using Azure CLI.

## What I Built

I deployed the following resources in the `Switzerland North` region:

- Virtual network: `vnet-project4`
- Web subnet: `10.40.10.0/24`
- Management subnet: `10.40.20.0/24`
- Network security group: `nsg-web-project4`
- Public IP address
- Network interface
- Ubuntu Linux virtual machine
- Storage account

I used the address space `10.40.0.0/16` for the virtual network.

I associated the NSG with the web subnet and created two inbound security rules:

- HTTP — TCP port 80
- SSH — TCP port 22

I connected the Linux VM to the web subnet through its network interface. I also attached a public IP address to the NIC so I could connect to the VM through SSH.

For authentication, I used an SSH public key instead of a password.

## Bicep Template

I defined the infrastructure in `main.bicep`.

While building the template, I worked with Bicep concepts including:

- Parameters
- Resources and symbolic names
- Resource types and API versions
- Resource properties
- Objects and arrays
- Resource references using `.id`
- `resourceId()`
- String interpolation
- Outputs
- VM hardware, network, storage, and OS profiles
- SSH public key configuration

One useful thing I learned was the difference between a Bicep resource reference and a resource that is only defined inside another resource.

For example, I could reference the NSG with:

```bicep
webNsg.id
```

However, I defined `web-subnet` as an object inside the VNet's `subnets` array rather than as its own symbolic Bicep resource. Because of this, I used `resourceId()` when connecting the NIC to the subnet.

The complete code for the project is available in the `main.bicep` file in this repository.

## Deployment and Verification

I first used Bicep build to check the template:

```powershell
az bicep build --file main.bicep
```

I then deployed the template to my resource group using Azure CLI:

```powershell
az deployment group create --resource-group rg-project4 --template-file main.bicep --parameters sshPublicKey="$sshKey"
```

I did not store my SSH public key directly in the Bicep file. I loaded it into a PowerShell variable from my local public key file:

```powershell
$sshKey = Get-Content ~/.ssh/id_ed25519.pub -Raw
```

After deployment, I used both Azure CLI and the Azure Portal to verify the resources.

For example, I listed the resources in the resource group with:

```powershell
az resource list --resource-group rg-project4 --query "[].{Name:name,Type:type,Location:location}" --output table
```

I also checked the VM configuration:

```powershell
az vm show --resource-group rg-project4 --name vm-web-project4 --query "{Name:name,Size:hardwareProfile.vmSize,Zone:zones[0],ProvisioningState:provisioningState}" --output table
```

I verified that the VM was running as `Standard_B2s_v2` in availability zone 1.

I also verified that the NIC was connected to `web-subnet`, received a dynamic private IP address, and referenced the public IP resource.

## SSH Verification

After the VM was running, I connected to it using its public IP address:

```powershell
ssh azureuser@<public-ip>
```

After connecting, I used:

```bash
hostname
```

and:

```bash
ip addr show eth0
```

I confirmed that the hostname was `webserver` and that the VM had received the private IP address `10.40.10.4` from `web-subnet`.

This helped me verify that the public IP, NIC, subnet, NSG, VM, and SSH configuration were working together.

## Storage Account

I also created a StorageV2 storage account using Bicep.

I configured it with:

- Standard LRS
- HTTPS-only traffic
- Minimum TLS version 1.2
- Public blob access disabled

After deployment, I verified these settings using Azure CLI and the Azure Portal.

## Testing the Bicep Deployment

### Redeployment

I deployed the same Bicep template again without deleting the existing resources first.

The deployment succeeded and did not create duplicate resources.

I then listed the resources in the resource group and confirmed that the same VNet, NSG, public IP, NIC, VM, disk, and storage account were still present.

This gave me practical experience with the idea that the Bicep template describes the desired state of the infrastructure.

### What-If

I also used Azure deployment `what-if` to preview changes before deployment:

```powershell
az deployment group what-if --resource-group rg-project4 --template-file main.bicep --parameters sshPublicKey="$sshKey"
```

To test it, I temporarily changed the HTTP NSG rule priority from `100` to `105`.

The what-if result detected:

```text
properties.priority: 100 => 105
```

I did not deploy this test change. I changed the priority back to `100` and saved the final Bicep template.

I also noticed that `what-if` displayed some additional changes for Azure-managed or default properties. This helped me learn that I need to look at the individual properties in the output instead of assuming every reported modification is a change I intentionally made.

## Troubleshooting

I encountered several problems while working on the project.

### VM Size Not Available

I originally configured the VM to use `Standard_B1s`.

When I tried to deploy it, Azure returned a `SkuNotAvailable` error because that VM size was not available for my subscription in Switzerland North.

I used Azure CLI to investigate VM SKU availability. I then changed the VM size to `Standard_B2s_v2` and used availability zone 1.

After making the change, I was able to deploy the VM successfully.

### Invalid SSH Public Key

One of my VM deployments failed with an error saying that `linuxConfiguration.ssh.publicKeys.keyData` was invalid.

I checked the `$sshKey` PowerShell variable and found that it was empty.

I loaded my public key again with:

```powershell
$sshKey = Get-Content ~/.ssh/id_ed25519.pub -Raw
```

I checked the variable to make sure it contained the `ssh-ed25519` public key and then redeployed the template.

The deployment succeeded and I was able to connect to the VM through SSH.

### Storage Account Verification

When I first tried to verify the storage account, Azure CLI returned a `ResourceNotFound` error.

I had used the wrong storage account name in the verification command.

I listed the storage accounts in `rg-project4`, found the actual deployed name, and then ran the verification command again successfully.

This was a useful reminder to verify the actual deployed resource names when troubleshooting Azure CLI commands.



## What I Learned

This project gave me my first practical experience building a complete Azure environment with Bicep.

I learned how Bicep resources are structured and how I can connect resources using symbolic references such as `.id`. I also learned how to use `resourceId()` when I do not have a separate symbolic resource to reference.

I became more comfortable working with objects, arrays, parameters, resource properties, string interpolation, and nested configuration.

I also learned that working with Infrastructure as Code is not only about writing the template. I still needed to deploy the infrastructure, read Azure deployment errors, troubleshoot problems, verify the resources, and test that the infrastructure actually worked.

Using Azure CLI alongside Bicep helped me understand the difference between:

- Building and validating the Bicep template
- Previewing changes with `what-if`
- Deploying the infrastructure
- Verifying the deployed resources
- Troubleshooting deployment problems

I do not expect to remember every Bicep property or API version. The most important thing I learned is how to read and understand a Bicep template, make changes to it, use documentation when I need help, deploy it to Azure, and fix problems if something goes wrong.

## Personal Reflection

When I first learned about Infrastructure as Code, I wasn't sure if I liked it. I thought writing code to create resources would take away some of the creativity. After learning Bicep and building this project, I changed my mind. I realized that writing the templates actually helped me understand Azure better. Before I could write the template, I had to understand what each resource does, how it connects to other resources, and what it needs to work correctly. This project showed me that Infrastructure as Code is not just about saving time. It also helps you learn how cloud infrastructure works.