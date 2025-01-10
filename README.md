# Azure Windows 11 Deployment Script

## Overview
This repository contains the `azwin11azuredeployment.sh` script, which simplifies the deployment of a Windows 11 Azure virtual machine. The script ensures that only specific IP addresses can access the VM via RDP and SSH.

---

## Features
- Automatically detects your current public IP and grants access for RDP and SSH.
- Requried to specify Allowed IP ranges using the `-r` flag.
- Automatically deletes old resource groups created by the script to maintain a clean Azure environment.

---

## Usage
### Basic Usage
## How to Use
### Bash
```
az login --use-device-code && git clone https://github.com/crtvrffnrt/azwin11azuredeployment.git && chmod +x ./azsshconnect/azsshconnect.sh && ./azwin11azuredeployment/azwin11azuredeployment.sh -r "$yourPublicip/32"
```
Run the script to create a new Windows VM accessible only from your current public IP:

### Alternative from Azure Portal
1. Login to Azure
2. Open Azure CLI & switch to bash
```
git clone https://github.com/crtvrffnrt/azwin11azuredeployment.git && chmod +x ./azwin11azuredeployment/azwin11azuredeployment.sh && ./azwin11azuredeployment/azwin11azuredeployment.sh -r "$yourPublicip/32"
```
3. Change your Public ip in $yourPublicip/32
4. wait until vm is created and commands to copy will be presented
5. run on your host PC powershell with provided command


# Options
### Specify Additional IP Ranges
You can allow access for both your current public IP and an additional range using the `-r` flag:

```bash
./azwin11azuredeployment.sh -r "198.51.100.10/32"
```

In this example, RDP and SSH will be accessible from:
- Your current public IP (e.g., `203.0.113.45/32`)
- The specified IP range `198.51.100.10/32`



## Note on SSH Access
By default, Windows virtual machines do not have SSH enabled. To access the VM via SSH:
1. Enable the SSH feature on the Windows VM after deployment.
2. Configure the Windows Firewall to allow SSH traffic.



## Connection

Windows
```Powershell
cmdkey /generic:"$PublicIp" /user:"adminuser" /pass:"$pass"; mstsc /v:$publicip
```

Linux
```bash
xfreerdp /v:13.84.245.178 /u:adminuser /p:"brf.5c2U)yQH33_-)*D=9ZQB" /cert:ignore
```

## Cleanup
Old resource groups created by this script are automatically deleted to keep your Azure environment organized. If you wish to disable this behavior, modify the script accordingly.

---
![image](https://github.com/user-attachments/assets/46273c07-e789-4e9e-8c1a-6156c173b98c)

