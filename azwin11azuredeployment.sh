#!/bin/bash

# Function to display messages with colors
display_message() {
    local message="$1"
    local color="$2"
    case $color in
        red) echo -e "\033[91m${message}\033[0m" ;;
        green) echo -e "\033[92m${message}\033[0m" ;;
        yellow) echo -e "\033[93m${message}\033[0m" ;;
        blue) echo -e "\033[94m${message}\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Function to check Azure authentication
check_azure_authentication() {
    az account show &> /dev/null
    if [ $? -ne 0 ]; then
        display_message "Please authenticate to your Azure account using 'az login --use-device-code'." "red"
        exit 1
    fi
}

# Function to delete old resource groups created by this script
delete_old_resource_groups() {
    az group list --query "[?starts_with(name, 'azwin11-')].name" -o tsv | while read -r group; do
        az group delete --name "$group" --yes --no-wait &> /dev/null
        if [ $? -eq 0 ]; then
            display_message "Successfully deleted resource group $group." "green"
        else
            display_message "Failed to delete resource group $group." "red"
        fi
    done
}

# Function to generate a random password
generate_random_password() {
    tr -dc 'A-Za-z0-9@' < /dev/urandom | head -c 22
}

# Function to generate a valid VM name
generate_vm_name() {
    echo "azwin11-$(date +%s | tail -c 6)"
}

# Function to configure NSG rules
configure_nsg_rules() {
    local nsg_name="$1"
    local resource_group="$2"
    local allowed_ip="$3"

    # Deny all inbound traffic by default
    az network nsg rule create \
        --resource-group "$resource_group" \
        --nsg-name "$nsg_name" \
        --name DenyInbound \
        --priority 1000 \
        --direction Inbound \
        --access Deny \
        --protocol '*' \
        --source-address-prefixes '*' \
        --source-port-ranges '*' \
        --destination-address-prefixes '*' \
        --destination-port-ranges '*' > /dev/null

    # Allow specific IP for RDP, SSH, WinRM
    az network nsg rule create \
        --resource-group "$resource_group" \
        --nsg-name "$nsg_name" \
        --name AllowInbound \
        --priority 200 \
        --direction Inbound \
        --access Allow \
        --protocol Tcp \
        --source-address-prefixes "$allowed_ip" \
        --source-port-ranges '*' \
        --destination-address-prefixes '*' \
        --destination-port-ranges 3389 22 5985 5986 > /dev/null
}

# Function to wait until VM is running
wait_for_vm_to_be_running() {
    local resource_group="$1"
    local vm_name="$2"

    while true; do
        vm_state=$(az vm get-instance-view --resource-group "$resource_group" --name "$vm_name" --query "instanceView.statuses[?code=='PowerState/running'].code" -o tsv)
        if [[ "$vm_state" == "PowerState/running" ]]; then
            display_message "VM is running. Waiting for 30 seconds to ensure services are ready..." "yellow"
            sleep 30
            break
        else
            display_message "Waiting for VM to be in 'running' state..." "yellow"
            sleep 10
        fi
    done
}

# Main script execution
main() {
    local allowed_ip=""

    # Parse arguments
    while getopts "r:" opt; do
        case $opt in
            r) allowed_ip="$OPTARG" ;;
            *)
                display_message "Invalid option provided. Use -r to specify the allowed IP range." "red"
                exit 1
                ;;
        esac
    done

    # Validate allowed IP range
    if [ -z "$allowed_ip" ]; then
        display_message "Allowed IP range must be provided using the -r flag." "red"
        exit 1
    fi

    # Check Azure authentication
    check_azure_authentication

    # Delete old resource groups
    delete_old_resource_groups

    # Generate VM details
    local vm_name=$(generate_vm_name)
    local admin_password=$(generate_random_password)
    local resource_group="$vm_name-rg"

    # Create resource group
    az group create --name "$resource_group" --location "southcentralus" > /dev/null
    if [ $? -ne 0 ]; then
        display_message "Failed to create resource group." "red"
        exit 1
    fi

    # Create NSG
    local nsg_name="${vm_name}-nsg"
    az network nsg create --resource-group "$resource_group" --name "$nsg_name" > /dev/null

    # Configure NSG rules
    configure_nsg_rules "$nsg_name" "$resource_group" "$allowed_ip"

    # Create the VM
    az vm create \
        --resource-group "$resource_group" \
        --name "$vm_name" \
        --nsg "$nsg_name" \
        --image "MicrosoftWindowsDesktop:windows-11:win11-24h2-ent:latest" \
        --admin-username "adminuser" \
        --admin-password "$admin_password" \
        --public-ip-sku Standard > /dev/null

    # Wait for the VM to be running
    wait_for_vm_to_be_running "$resource_group" "$vm_name"

    # Get the public IP of the VM
    local public_ip=$(az network public-ip list --resource-group "$resource_group" --query "[0].ipAddress" -o tsv)

    # Display the connection details
    display_message "Your Windows VM has been created successfully!" "green"
    echo "Connect to your VM using the following details:"
    echo "Public IP: $public_ip"
    echo "Username: adminuser"
    echo "Password: $admin_password"
    echo "Allowed IP range: $allowed_ip"
    echo "Ports open: RDP (3389), SSH (22), WinRM (5985/5986)"

    # Generate PowerShell and Linux commands for connection
    echo
    echo "To connect from Windows (PowerShell):"
    echo "cmdkey /generic:\"$public_ip\" /user:\"adminuser\" /pass:\"$admin_password\"; mstsc /v:$public_ip"
    echo
    echo "To connect from Linux (xfreerdp):"
    echo "xfreerdp /v:$public_ip /u:adminuser /p:\"$admin_password\" /cert:ignore "
    echo
    display_message "Successfully deployed Windows 11 VM connect to with RDP and you can setup OpenSSH if you want" "green"
    echo
    echo "Good-Bye"
}

main "$@"
