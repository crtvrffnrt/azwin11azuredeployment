# azwin11azuredeployment

# RDP Azure Deployment Script  

## Introduction  
This script is a powerful automation written in **Bash** that handles a quick and secure deployment of a new **Windows 11 virtual machine (VM)** on Azure and establishes an connection to the VM. 


---

## Prerequisites  
Before using this script, ensure the following:  
1. **Azure CLI** is installed and configured with appropriate permissions.
2. Azure Azure Cloud Shell (bash) from Azure Portal instead is possible
3. A **Windows Remote Desktop (RDP)** client is installed on your local machine.  

---

## How to Use  

### **PowerShell**  
Run the following commands in your terminal to deploy and connect to the Windows 11 VM:  

```powershell
az login --use-device-code
git clone https://github.com/crtvrffnrt/azwin11azuredeployment.git
cd azrdpconnect
.\azrdpconnect.ps1
```
