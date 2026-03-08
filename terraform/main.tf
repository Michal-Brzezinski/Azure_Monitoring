# ==============================================================================
# Azure Infrastructure for Monitoring Stack — Terraform Configuration
# ==============================================================================
#
# Description  : Provisions a complete Azure infrastructure for a monitoring
#                server (e.g., Zabbix). Includes a Linux VM with a public IP,
#                isolated virtual network, and a security group with precisely
#                scoped inbound rules.
#
# Resources created:
#   - Resource Group
#   - Virtual Network + Subnet
#   - Public IP Address (Static)
#   - Network Security Group (SSH, HTTP, Zabbix)
#   - Network Interface (with NSG association)
#   - Linux Virtual Machine (Ubuntu 22.04 LTS)
#
# Requirements:
#   - Terraform >= 1.0
#   - AzureRM provider ~> 3.0
#   - SSH public key at ~/.ssh/id_rsa.pub
#   - Authenticated Azure CLI session (`az login`)
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
# ==============================================================================


# ==============================================================================
# Provider Configuration
# ==============================================================================
# Declares the required provider (hashicorp/azurerm) and its minimum version.
# The `~> 3.0` constraint allows any 3.x patch/minor release but prevents
# potentially breaking upgrades to 4.x.
# The `features {}` block is mandatory for the AzureRM provider even if left
# empty — it enables provider-level feature flags introduced in v2.x.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}


# ==============================================================================
# Resource Group
# ==============================================================================
# A Resource Group is a logical container for all Azure resources in this
# deployment. Deleting the resource group will destroy every resource within it,
# making it the cleanest teardown boundary. All resources below are co-located
# in the same region to minimise latency and egress costs.

resource "azurerm_resource_group" "rg" {
  name     = "rg-azure-monitoring"
  location = "North Europe"
}


# ==============================================================================
# Virtual Network (VNet)
# ==============================================================================
# A Virtual Network provides network-level isolation within your Azure
# subscription. The address space 10.0.0.0/16 (~65,536 addresses) leaves ample
# room to add subnets for future workloads (databases, App Services, etc.)
# without requiring a VNet redesign.

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-monitoring"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


# ==============================================================================
# Subnet
# ==============================================================================
# Carves out a /24 block (256 addresses, 251 usable after Azure reservations)
# from the VNet for the monitoring tier. Using a dedicated subnet allows
# fine-grained NSG policies and simplifies network segmentation if additional
# tiers (e.g., a database subnet) are added later.

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-monitoring"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


# ==============================================================================
# Public IP Address
# ==============================================================================
# Allocates a static public IP so the VM's address does not change across
# reboots or redeployments. "Basic" SKU is sufficient for single-VM scenarios;
# upgrade to "Standard" if you later introduce a Load Balancer or Availability
# Zones.
#
# Note: The actual IP is assigned by Azure after apply and exposed via the
# `public_ip` output at the bottom of this file.

resource "azurerm_public_ip" "pip" {
  name                = "pip-monitoring"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}


# ==============================================================================
# Network Security Group (NSG)
# ==============================================================================
# An NSG acts as a stateful, layer-4 firewall for the NIC. Rules are evaluated
# in ascending priority order (lower number = higher priority). Only the three
# ports required for this deployment are opened; all other inbound traffic is
# denied by the default "DenyAllInbound" rule built into every NSG.
#
# Security rules:
#   Priority 1001 — SSH   (TCP/22)    : Remote administration of the VM.
#                                       Restrict `source_address_prefix` to your
#                                       own IP range in production environments.
#   Priority 1002 — HTTP  (TCP/80)    : Zabbix web frontend served over HTTP.
#                                       Replace with HTTPS (TCP/443) once TLS is
#                                       configured on the server.
#   Priority 1003 — Zabbix (TCP/10051): Active agent communication port. Zabbix
#                                       agents push data to the server on this
#                                       port (active checks model).

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-monitoring"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"   # Restrict to a known IP range in production
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Zabbix"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10051"
    source_address_prefix      = "*"   # Restrict to agent IP ranges in production
    destination_address_prefix = "*"
  }
}


# ==============================================================================
# Network Interface (NIC)
# ==============================================================================
# The NIC connects the VM to the subnet and carries the public IP association.
# Dynamic private IP allocation lets Azure assign an address from the subnet
# pool automatically; switch to "Static" if a fixed private IP is required
# (e.g., for DNS A-record consistency inside the VNet).

resource "azurerm_network_interface" "nic" {
  name                = "nic-monitoring"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}


# ==============================================================================
# NIC ↔ NSG Association
# ==============================================================================
# Attaches the NSG to the NIC (NIC-level association). This enforces the
# security rules on all traffic flowing to and from this specific interface,
# regardless of any subnet-level NSG that may exist.

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# ==============================================================================
# Linux Virtual Machine
# ==============================================================================
# Provisions an Ubuntu 22.04 LTS VM sized for lightweight monitoring workloads.
#
# Key configuration decisions:
#   size           : Standard_B1s (1 vCPU, 1 GiB RAM) — burstable tier suitable
#                    for a Zabbix server monitoring a small environment. Upsize to
#                    Standard_B2s or Standard_D2s_v3 for heavier polling loads.
#   admin_username : "student" — change to a non-default value in production to
#                    reduce exposure to automated brute-force attempts.
#   authentication : SSH key-only; password authentication is explicitly disabled
#                    to comply with security best practices.
#   public_key     : Read from the local filesystem at apply time. Ensure the key
#                    exists before running `terraform apply`.
#   os_disk        : Standard HDD (Standard_LRS) with ReadWrite caching. Upgrade
#                    to Premium_LRS for better IOPS if the monitoring database
#                    generates significant disk I/O.
#   image          : Canonical Ubuntu Server 22.04 LTS ("Jammy Jellyfish") —
#                    LTS release with security support until April 2027.

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-monitoring"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "student"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "student"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  # =============================================================================
  # UNCOMMENT TO ENABLE TEACHER'S SSH KEY 
  # =============================================================================
  #
  # admin_ssh_key {
  # username   = "tligocki"
  # public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDoN9r1/6oyIFIn9o09Iv+jBqt0y15DIERwPgqzxWHPb7aKY0ll+oc1mlcW03xS9ib2fidfbx9uGuvYK5gP7dcY52I7/ZB6G6nw5Dg3C1WLkct3lqrQYWsTEl6m3a6farbER6hJR4LgESdSdwaVYnLRfNxBU+VHi3Bm01pr+g4n5tSGrgjz/VgNi6qWgMG5/Ef5fJ3INpkjtsRrJ+8P6j1Lp5iK+iQDjgn2yLyTex+adx9BGVzTw7xVpAXgIh9Mik5CwxxM9q8ymGTK9PpVuacCHndtVKiQOHYy5+uTpIRdp07pY9X39kggjT9EYLwhaNOkTkpYk3m3+qa5VqdtG23r tligocki@dell"
  # }

  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk-monitoring"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


# ==============================================================================
# Outputs
# ==============================================================================
# Exposes the VM's public IP after a successful `terraform apply`. Use this
# address to connect via SSH:
#
#   ssh student@<public_ip>
#
# and to access the Zabbix web interface:
#
#   http://<public_ip>/zabbix

output "public_ip" {
  description = "Public IP address of the monitoring VM"
  value       = azurerm_public_ip.pip.ip_address
}
