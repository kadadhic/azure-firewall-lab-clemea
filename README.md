# LTRSEC-2683 — Deploying Resilient and Secure Networks in Azure with Cisco Secure Firewall

> **Cisco Live EMEA 2026**
> Authors: Gautam Bhagwandas (Customer Success Specialist) · Karmanya Dadhich (Technical Marketing Engineer)
> Lab Guide: [https://cl-ltr.ciscolabs.com/85b196d23a/overview/](https://cl-ltr.ciscolabs.com/85b196d23a/overview/)

This repository contains the **Terraform (IaC) templates** used to automate the provisioning of the full hub-and-spoke lab environment for LTRSEC-2683. The templates deploy all Azure networking, Cisco FTDv firewalls, test VMs, and RBAC assignments required for the lab exercises.

---

## Table of Contents

- [Overview](#overview)
- [Lab Objectives](#lab-objectives)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
  - [Network Topology](#network-topology)
  - [IP Addressing](#ip-addressing)
  - [Deployed Resources](#deployed-resources)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [1. Configure Variables](#1-configure-variables)
  - [2. Initialize Terraform](#2-initialize-terraform)
  - [3. Deploy the Infrastructure](#3-deploy-the-infrastructure)
  - [4. Destroy the Infrastructure](#4-destroy-the-infrastructure)
- [Lab Exercises Summary](#lab-exercises-summary)
- [Connecting to Devices](#connecting-to-devices)
- [Additional Resources](#additional-resources)

---

## Overview

As deployments in the public cloud accelerate, it is essential to understand how to deploy Cisco products in those environments. This lab is a foundational introduction to deploying the **Cisco Secure Firewall Threat Defense Virtual (FTDv)** in **Microsoft Azure**.

The Terraform templates in this repo pre-build the underlying Azure infrastructure (VNets, subnets, NSGs, VMs, RBAC) so lab attendees can focus on the firewall configuration exercises rather than manually creating every Azure resource.

---

## Lab Objectives

- Deploy Cisco Secure Firewall Threat Defense (FTDv) in Azure
  - Stand-alone deployment
  - Load-balanced firewall pair (scale + resilience)
  - Protect north-south, east-west, and outbound traffic
- Protect a hub-and-spoke topology with FTDvs in the hub VNet
- Utilize the Azure Portal and Azure CLI for configuration tasks
- **(Optional)** Use Terraform templates as your IaC solution
- **(Optional)** Utilize Azure Traffic Manager with RAVPN for load-balancing and redundancy
- **(Optional)** Use Azure Route Server with FTDv for Active/Standby redundancy
- **(Optional)** Utilize the Azure Gateway Load Balancer for north-south traffic inspection
- **(Optional)** Connect the Azure data center to a branch office using IPsec VPN

---

## Prerequisites

- Basic ability to configure Cisco Secure Firewall Threat Defense (FTD) with Firewall Management Center (FMC)
- General understanding of IPv4 networking and network security
- An Azure subscription with sufficient quota for `Standard_D3_v2` (FTDv) and `Standard_B1s` (test VMs) in your chosen region
- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5 installed locally **or** use the Azure Cloud Shell
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) authenticated (`az login`)

> **Note:** This lab assumes no prior experience with the Azure environment.

---

## Architecture

### Network Topology

The lab uses a **hub-and-spoke** topology with a dedicated Security VNet hosting the Cisco FTDv firewalls. All inter-spoke and north-south traffic is routed through the firewalls for centralized inspection.

> 🔵 Blue circled numbers = **Core** exercises · 🟠 Orange circled numbers = **Optional** exercises

![Lab Topology — Exercise 1–4](https://cl-ltr.ciscolabs.com/85b196d23a/assets/introduction/Exercise%201-4.png)

The diagram above covers exercises 1–4:
- **①** VNet Peering between the Security VNet and Spoke1 (`podX-spoke1-vnet`)
- **②** Standalone FTDv (`podX-ftd76-1`) deployed in the Security VNet
- **③** Load-balanced FTDv pair (`podX-ftd76-1` + `podX-ftd76-2`) behind `podX-plb` (Public Load Balancer) and `podX-ilb` (Internal Load Balancer)
- **④** Second spoke (`podX-spoke2-vnet`) added with inter-VNet traffic routing through the FTDvs

### IP Addressing

| Network | CIDR | Purpose |
|---|---|---|
| Security VNet | `10.100.0.0/16` | Hub — FTDv firewalls + Jumpbox |
| ↳ Management Subnet | `10.100.250.0/24` | FTDv mgmt interfaces + Jumpbox |
| ↳ Inside Subnet | `10.100.100.0/24` | FTDv inside/trust interfaces |
| ↳ Outside Subnet | `10.100.200.0/24` | FTDv outside/untrust interfaces |
| Spoke1 VNet | `10.101.0.0/16` | Three-tier data center workloads |
| ↳ Web Subnet | `10.101.101.0/24` | Web tier VM |
| ↳ App Subnet | `10.101.102.0/24` | App tier VM |
| ↳ DB Subnet | `10.101.103.0/24` | Database tier VM |
| Spoke2 VNet | `10.102.0.0/16` | Second spoke workloads (Exercise 4) |
| ↳ App Subnet | `10.102.102.0/24` | Two app VMs (app2a, app2b) |
| Branch VNet | `192.168.0.0/16` | Mock branch office (Exercise 7–8) |
| ↳ Branch Management | `192.168.250.0/24` | Branch FTDv mgmt |
| ↳ Branch Inside | `192.168.100.0/24` | Branch FTDv inside |
| ↳ Branch Outside | `192.168.200.0/24` | Branch FTDv outside |
| ↳ Branch App | `192.168.102.0/24` | Branch app VM |

**FTDv Fixed IPs**

| Device | Management (nic0) | Outside (nic1) | Inside (nic2) | AZ |
|---|---|---|---|---|
| `podX-ftd76-1` | `10.100.250.81` | `10.100.200.81` | `10.100.100.81` | Zone 1 |
| `podX-ftd76-2` | `10.100.250.82` | `10.100.200.82` | `10.100.100.82` | Zone 2 |
| `podX-branch-ftdv` | `192.168.250.4` | `192.168.200.4` | `192.168.100.4` | — |

**Test VMs**

| VM Name | Private IP | Subnet |
|---|---|---|
| `podX-spoke1-web` | `10.101.101.100` | Spoke1 Web |
| `podX-spoke1-app` | `10.101.102.100` | Spoke1 App |
| `podX-spoke1-db` | `10.101.103.100` | Spoke1 DB |
| `podX-spoke2-app2a` | `10.102.102.101` | Spoke2 App |
| `podX-spoke2-app2b` | `10.102.102.102` | Spoke2 App |
| `podX-branch-app` | `192.168.102.100` | Branch App |
| `podX-jumpbox` | Dynamic | Security Management |

### Deployed Resources

| Resource Type | Count | Details |
|---|---|---|
| Resource Groups | 2 | `podX`, `podX-branch` |
| Virtual Networks | 4 | Security, Spoke1, Spoke2, Branch |
| Cisco FTDv Firewalls | 3 | FTDv 7.6.2 BYOL · `Standard_D3_v2` |
| Test Linux VMs | 6 | Ubuntu 22.04 LTS · `Standard_B1s` |
| Management Jumpbox | 1 | Ubuntu 22.04 LTS with Azure CLI, Ansible, etc. |
| Public IPs | 8 | FTDv mgmt (×3), FTDv outside (×3), branch app, jumpbox |
| NSGs | 7 | Per-subnet access controls |
| RBAC Assignments | 5 | Contributor + VM Contributor on all RGs |

---

## Repository Structure

```
azure-firewall-lab-clemea/
└── podX/
    ├── provider.tf          # Terraform provider config (azurerm ~> 4.0, azuread ~> 3.0)
    ├── variables.tf         # All input variable declarations with defaults
    ├── terraform.tfvars     # Lab-specific variable values (edit before deploying)
    ├── resource_groups.tf   # Main + Branch resource groups; boot diagnostics data source
    ├── security_vnet.tf     # Security VNet, subnets, NSGs, Management Jumpbox VM
    ├── spoke_vnets.tf       # Spoke1 + Spoke2 VNets, subnets, NSGs, test VMs, VNet peering
    ├── branch_vnet.tf       # Branch VNet, subnets, NSGs, Branch FTDv + app VM
    ├── ftdv_firewalls.tf    # FTDv1, FTDv2 NICs, public IPs, and VM resources
    ├── rbac.tf              # RBAC role assignments for the demo/lab user
    ├── outputs.tf           # Key outputs: IPs, VNet IDs, deployment summary
    └── userdata/
        └── ftd_userdata.tftpl  # FTDv Day-0 bootstrap configuration template
```

---

## Getting Started

### 1. Configure Variables

Edit [podX/terraform.tfvars](podX/terraform.tfvars) with your environment-specific values:

```hcl
# Required — replace with your Azure Subscription ID
azure_subscription_id = "<ENTER_YOUR_SUBSCRIPTION_ID>"

# Required — replace with the lab user's Azure AD UPN
user_principal_name = "PodX@ciscodemo.onmicrosoft.com"

# Required — set a strong password for FTDv admin
ftdv_admin_password = "<YOUR_FTDV_PASSWORD>"

# Required — set a password for the test/jumpbox VMs
admin_password = "<YOUR_VM_PASSWORD>"

# Adjust if you want a different Azure region (default: West Europe)
azure_region = "West Europe"

# Optionally restrict management access to specific source IP ranges
trusted_networks = ["10.0.0.0/8"]
```

> **Important:** `podX` in all resource names is the pod identifier. For multi-pod deployments, set `resource_prefix` to your assigned pod name (e.g., `pod1`, `pod2`).

### 2. Initialize Terraform

```bash
cd podX
terraform init
```

### 3. Deploy the Infrastructure

```bash
# Review the plan first
terraform plan

# Apply — this will take ~10–15 minutes
terraform apply
```

After a successful apply, Terraform prints key outputs including all public IPs for the FTDv management interfaces, outside interfaces, and test VMs.

### 4. Destroy the Infrastructure

```bash
terraform destroy
```

---

## Lab Exercises Summary

The lab is structured into three core exercises (must be done in order) and five optional exercises.

| # | Exercise | Type | Description |
|---|---|---|---|
| 1 | Examine the Data Center | Core | Explore the three-tier hub-and-spoke topology without any firewalls |
| 2 | Standalone FTDv | Core | Deploy a single FTDv to inspect north-south, east-west, and outbound traffic |
| 3 | Load-Balanced FTDv Pair | Core | Migrate to two FTDvs behind a Public Load Balancer (PLB) and Internal Load Balancer (ILB) |
| 4 | Second Spoke + Inter-Spoke | Optional | Add Spoke2 and route inter-VNet / intra-subnet traffic through the FTDvs |
| 5 | Traffic Manager + RAVPN | Optional | DNS-based load-balancing using Azure Traffic Manager and Route Server with RAVPN |
| 6 | Gateway Load Balancer | Optional | Redirect north-south traffic to the web server via Azure Gateway Load Balancer |
| 7 | Mock Branch Office | Optional | Deploy a branch FTDv in a separate resource group simulating a branch site |
| 8 | Branch IPsec VPN | Optional | Connect the mock branch to the Azure data center over an IPsec VPN tunnel |

> **Dependency note:** Exercises 1–3 must be completed first. Exercises 4–7 can then be done in any order. Exercise 8 requires both Exercise 5 and Exercise 7 to be completed.

---

## Connecting to Devices

A Management Jumpbox VM (`podX-jumpbox`) is deployed in the Security VNet management subnet. It has the Azure CLI, Ansible, `sshpass`, `nmap`, `tcpdump`, and other tools pre-installed.

Once connected to the jumpbox, use the built-in helper script to reach any device in the lab:

```bash
./connect.sh
```

The script prompts you to select from all available devices:

| # | Device | IP |
|---|---|---|
| 1 | `podX-ftd76-1` | `10.100.250.81` |
| 2 | `podX-ftd76-2` | `10.100.250.82` |
| 3 | `podX-spoke1-app` | `10.101.102.100` |
| 4 | `podX-spoke1-db` | `10.101.103.100` |
| 5 | `podX-spoke1-web` | `10.101.101.100` |
| 6 | `podX-spoke2-app2a` | `10.102.102.101` |
| 7 | `podX-spoke2-app2b` | `10.102.102.102` |

---

## Additional Resources

- 📖 [Lab Guide — LTRSEC-2683](https://cl-ltr.ciscolabs.com/85b196d23a/overview/)
- 📥 [Lab Templates & Scripts](https://ciscozone.com/Azure/) (`resources.zip`)
- 📚 [Cisco Secure Firewall FTDv on Azure Documentation](https://www.cisco.com/c/en/us/td/docs/security/firepower/quick_start/azure/ftdv-azure-gsg.html)
- 🔧 [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- 🌍 [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
