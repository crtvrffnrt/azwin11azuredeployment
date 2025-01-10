# Azure Windows 11 Deployment Script

## Overview
This repository contains the `azwin11azuredeployment.sh` script, which simplifies the deployment of a Windows 11 Azure virtual machine. The script ensures that only specific IP addresses can access the VM via RDP and SSH. By default, your current public IP is used for access, and additional ranges can be specified as needed.

---

## Features
- Automatically detects your current public IP and grants access for RDP and SSH.
- Option to specify additional IP ranges using the `-r` flag.
- Automatically deletes old resource groups created by the script to maintain a clean Azure environment.

---

## Usage
### Basic Usage
Run the script to create a new Windows VM accessible only from your current public IP:

```bash
./azwin11azuredeployment.sh
```

This will allow RDP and SSH access for your current public IP only (e.g., `203.0.113.45/32`).

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

---

## Prerequisites
- Azure CLI installed and authenticated (`az login`).
- Necessary permissions to create resource groups, virtual machines, and network security groups in Azure.

---

## Outputs
After deployment, the script will display the following details:
- **Public IP Address**: The public IP of the VM.
- **Username**: `adminuser`
- **Password**: A randomly generated password.
- **Allowed IP Ranges**: IP ranges permitted to access RDP and SSH.
![image](https://github.com/user-attachments/assets/284ccf76-ca02-4c75-85c0-6ecc77cf6485)


---

## Connection

Windows
```Powershell
cmdkey /generic:"$PublicIp" /user:"adminuser" /pass:"$pass"; mstsc /v:$publicip
```

Linux
```bash
xfreerdp /v:13.84.245.178 /u:adminuser /p:brf.5c2U)yQH33_-)*D=9ZQB /cert:ignore
```

## Cleanup
Old resource groups created by this script are automatically deleted to keep your Azure environment organized. If you wish to disable this behavior, modify the script accordingly.

---

## Disclaimer
This script is provided "as-is" without warranty of any kind. Use at your own risk. Ensure proper security measures are in place when allowing access to your VM.
