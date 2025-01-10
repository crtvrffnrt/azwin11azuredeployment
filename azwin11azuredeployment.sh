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
    tr -dc 'A-Za-z0-9@#$' < /dev/urandom | head -c 20
}

# Function to generate a valid VM name
generate_vm_name() {
    echo "azwin11-$(date +%s | tail -c 6)"
}

# Function to get the current public IP
get_current_ip() {
    curl -s https://ipinfo.io/ip
}

# Function to configure NSG rules
configure_nsg_rules() {
    local nsg_name="$1"
    local resource_group="$2"
    shift 2
    local allowed_ips=("$@")

    # Allow specific IPs for RDP, SSH, WinRM
    for ip in "${allowed_ips[@]}"; do
        az network nsg rule create \
            --resource-group "$resource_group" \
            --nsg-name "$nsg_name" \
            --name AllowInbound-${ip//\//_} \
            --priority $((100 + RANDOM % 900)) \
            --direction Inbound \
            --access Allow \
            --protocol Tcp \
            --source-address-prefixes "$ip" \
            --destination-port-ranges 3389 22 5985 5986 > /dev/null
    done
}

# Function to delete the default RDP rule (if exists)
delete_default_rdp_rule() {
    local nsg_name="$1"
    local resource_group="$2"

    az network nsg rule list \
        --resource-group "$resource_group" \
        --nsg-name "$nsg_name" \
        --query "[?name=='rdp']" -o tsv | while read -r rule; do
        az network nsg rule delete --resource-group "$resource_group" --nsg-name "$nsg_name" --name "rdp" > /dev/null
        display_message "Default NSG rule 'rdp' with priority 1000 deleted." "yellow"
    done
}

# Main script execution
main() {
    local additional_ip=""
    local current_ip=$(get_current_ip)/32
    local allowed_ips=("$current_ip")

    # Parse arguments
    while getopts "r:" opt; do
        case $opt in
            r) additional_ip="$OPTARG" ;;
            *)
                display_message "Invalid option provided." "red"
                exit 1
                ;;
        esac
    done

    # Add additional IP to allowed IPs if provided
    if [ -n "$additional_ip" ]; then
        allowed_ips+=("$additional_ip")
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

    # Create the VM
    az vm create \
        --resource-group "$resource_group" \
        --name "$vm_name" \
        --image "MicrosoftWindowsDesktop:windows11preview:win11-24h2-ent:latest" \
        --admin-username "adminuser" \
        --admin-password "$admin_password" \
        --public-ip-sku Standard > /dev/null

    # Get the NSG name
    local nsg_name=$(az network nsg list --resource-group "$resource_group" --query "[0].name" -o tsv)
    if [ -z "$nsg_name" ]; then
        display_message "Failed to retrieve NSG name. Ensure NSG is created with the VM." "red"
        exit 1
    fi

    # Delete the default RDP rule if it exists
    delete_default_rdp_rule "$nsg_name" "$resource_group"

    # Configure NSG rules
    configure_nsg_rules "$nsg_name" "$resource_group" "${allowed_ips[@]}"

    # Get the public IP of the VM
    local public_ip=$(az network public-ip list --resource-group "$resource_group" --query "[0].ipAddress" -o tsv)

    # Display the connection details
    display_message "Your Windows VM has been created successfully!" "green"
    echo "Connect to your VM using the following details:"
    echo "Public IP: $public_ip"
    echo "Username: adminuser"
    echo "Password: $admin_password"
    echo "Allowed IP ranges: ${allowed_ips[*]}"
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
