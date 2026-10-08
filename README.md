# Production-Grade Multi-Cloud VPN: Azure to GCP HA Interconnect

[![Terraform CI](https://github.com/org/repo/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/org/repo/actions/workflows/terraform-ci.yml)
[![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.5.0-623CE4.svg)](https://www.terraform.io)
[![Azure Provider](https://img.shields.io/badge/provider-azurerm%20~%3E3.100-0078D4.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![GCP Provider](https://img.shields.io/badge/provider-google%20~%3E5.30-4285F4.svg)](https://registry.terraform.io/providers/hashicorp/google/latest)

Enterprise-grade, automated Terraform configuration to establish a resilient, **Active-Active High Availability (HA) IPsec VPN interconnect** with **dynamic BGP routing** between **Microsoft Azure** (Virtual Network Gateway) and **Google Cloud Platform** (Cloud HA VPN + Cloud Router).

---

## Architecture Overview

This architecture implements a dual-tunnel Active-Active VPN topology conforming to Microsoft Azure Well-Architected Framework and Google Cloud Architecture Center standards:

```mermaid
flowchart TD
    subgraph Azure["Microsoft Azure (East US)"]
        subgraph VNet["Virtual Network (10.100.0.0/16)"]
            WorkloadSubnet["Workload Subnet (10.100.1.0/24)"]
            GatewaySubnet["GatewaySubnet (10.100.255.0/24)"]
            subgraph VNG["Azure VPN Gateway (Active-Active / BGP ASN 65515)"]
                AzInst0["Instance 0 (Public IP 1)<br/>BGP APIPA: 169.254.21.2"]
                AzInst1["Instance 1 (Public IP 2)<br/>BGP APIPA: 169.254.22.2"]
            end
        end
    end

    subgraph Internet["Public Internet (IPsec IKEv2 / AES-256 / SHA-256)"]
        Tunnel1["IPsec Tunnel 1<br/>BGP Peering: 169.254.21.1 <--> 169.254.21.2"]
        Tunnel2["IPsec Tunnel 2<br/>BGP Peering: 169.254.22.1 <--> 169.254.22.2"]
    end

    subgraph GCP["Google Cloud Platform (us-east1)"]
        subgraph VPC["Custom VPC Network (10.200.0.0/16)"]
            GcpSubnet["Workload Subnet (10.200.1.0/24)"]
            subgraph HAVPN["GCP Cloud HA VPN Gateway"]
                GcpInt0["Interface 0 (Public IP 1)"]
                GcpInt1["Interface 1 (Public IP 2)"]
            end
            subgraph CloudRouter["Cloud Router (BGP ASN 65001)"]
                CR_If0["CR Interface 0<br/>BGP APIPA: 169.254.21.1/30"]
                CR_If1["CR Interface 1<br/>BGP APIPA: 169.254.22.1/30"]
            end
        end
    end

    AzInst0 === Tunnel1 === GcpInt0
    AzInst1 === Tunnel2 === GcpInt1
    GcpInt0 --- CR_If0
    GcpInt1 --- CR_If1
    WorkloadSubnet -.- GatewaySubnet
    GatewaySubnet --- AzInst0
    GatewaySubnet --- AzInst1
    GcpSubnet -.- CloudRouter
```

---

## Network & BGP Addressing Matrix

| Parameter | Azure | Google Cloud Platform |
| :--- | :--- | :--- |
| **VNet / VPC CIDR** | `10.100.0.0/16` | `10.200.0.0/16` (Global Routing) |
| **Workload Subnet** | `10.100.1.0/24` | `10.200.1.0/24` |
| **Gateway Subnet** | `10.100.255.0/24` | N/A (Managed by HA VPN Gateway) |
| **BGP ASN** | `65515` (Azure Standard) | `65001` (Private ASN) |
| **Tunnel 1 Gateway IP** | Azure Public IP 1 | GCP HA VPN Interface 0 IP |
| **Tunnel 1 BGP APIPA** | `169.254.21.2` | `169.254.21.1/30` |
| **Tunnel 2 Gateway IP** | Azure Public IP 2 | GCP HA VPN Interface 1 IP |
| **Tunnel 2 BGP APIPA** | `169.254.22.2` | `169.254.22.1/30` |

---

## Cryptographic & IPsec Security Standards

Both ends are configured with matching, high-assurance cryptographic parameters:

- **Protocol**: IKEv2
- **Phase 1 (IKE SA)**:
  - Encryption: `AES-256`
  - Integrity: `SHA-256`
  - Diffie-Hellman Group: `DHGroup14` (2048-bit MODP)
  - SA Lifetime: `28800s`
- **Phase 2 (Child SA)**:
  - Encryption: `AES-256`
  - Integrity: `SHA-256`
  - Perfect Forward Secrecy: `PFS2048` (PFS Group 14)
  - SA Lifetime: `27000s` / `102400000 KB`
- **Pre-Shared Keys**: High-entropy 32-character random strings generated dynamically using cryptographic pseudo-random generators (`random_password`).
- **Dead Peer Detection (DPD)**: Enabled (45 seconds timeout).

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform-ci.yml        # CI pipeline for terraform fmt & validate
├── modules/
│   ├── azure_vnet/                 # Azure RG, VNet, Subnets, NSG & associations
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── azure_vpn_gateway/          # Azure Active-Active VNG, Public IPs, LNGs & Connections
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── gcp_vpc/                    # GCP Custom VPC, Subnetwork, Flow Logs & Firewall Rules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── gcp_ha_vpn/                 # GCP HA VPN Gateway, Cloud Router, External Gateway, Tunnels & BGP Peers
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── shared_secrets/             # Dynamic cryptographic Pre-Shared Key generation
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── test_workloads/             # Optional lightweight Linux test VMs for verification
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                         # Root module wiring Azure and GCP resources
├── variables.tf                    # Root input variables with validation & production defaults
├── outputs.tf                      # Root outputs & CLI verification commands
├── versions.tf                     # Provider constraints & backend definitions
├── terraform.tfvars.example        # Production variable values template
├── Makefile                        # Automation shortcuts (fmt, validate, plan, apply)
└── README.md                       # Architecture, operations, runbook & troubleshooting
```

---

## Prerequisites

1. **Terraform**: Version `>= 1.5.0` installed.
2. **Azure Account & CLI**:
   - Azure Subscription with `Network Contributor` and `Reader` permissions.
   - Authenticated via `az login` or Azure Service Principal environment variables:
     ```bash
     export ARM_CLIENT_ID="<client-id>"
     export ARM_CLIENT_SECRET="<client-secret>"
     export ARM_SUBSCRIPTION_ID="<subscription-id>"
     export ARM_TENANT_ID="<tenant-id>"
     ```
3. **Google Cloud Account & SDK**:
   - GCP Project with Compute Engine API enabled (`compute.googleapis.com`).
   - Authenticated via `gcloud auth application-default login` or GCP Service Account key:
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
     ```

---

## Deployment Guide

### 1. Clone & Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific GCP Project ID and Azure details:

```hcl
gcp_project_id = "your-gcp-project-id"
azure_location = "eastus"
gcp_region     = "us-east1"
```

### 2. Initialize Terraform

```bash
make init
# or: terraform init
```

### 3. Review Plan

```bash
make plan
# or: terraform plan -var-file="terraform.tfvars"
```

### 4. Apply Infrastructure

> [!NOTE]
> Azure Virtual Network Gateway creation typically takes **25 to 45 minutes** to provision on Azure infrastructure.

```bash
make apply
# or: terraform apply -var-file="terraform.tfvars"
```

---

## Verification & Operational Runbook

Once `terraform apply` finishes, dynamic BGP routes converge within 60-90 seconds.

### 1. Verify Azure BGP Peering Status

Run the command from Terraform outputs:

```bash
az network vnet-gateway list-bgp-peer-status \
  --resource-group rg-hybrid-connectivity-prod \
  --name vgw-azure-hybrid-prod \
  -o table
```

**Expected Status**: `Connected` on both `169.254.21.1` and `169.254.22.1`.

### 2. Verify Learned Routes in Azure

```bash
az network vnet-gateway list-learned-routes \
  --resource-group rg-hybrid-connectivity-prod \
  --name vgw-azure-hybrid-prod \
  -o table
```

**Expected Output**: The GCP workload CIDR (`10.200.1.0/24`) is listed with `NextHop` pointing to the GCP BGP peering addresses.

### 3. Verify GCP HA VPN Tunnels

```bash
gcloud compute vpn-tunnels list \
  --project=your-gcp-project-id \
  --filter="region:(us-east1)"
```

**Expected Status**: Detailed status `Tunnel is up and running.`

### 4. Verify GCP Cloud Router BGP Session

```bash
gcloud compute routers get-status cr-gcp-hybrid-prod \
  --region=us-east1 \
  --project=your-gcp-project-id
```

**Expected Status**: `BgpPeerStatus` shows `ESTABLISHED` for both peers `cr-gcp-hybrid-prod-peer-0` and `cr-gcp-hybrid-prod-peer-1`.

---

## End-to-End Traffic Verification (Test VMs)

To provision lightweight test instances without exposing public IPs:

1. Set `enable_test_vms = true` in `terraform.tfvars`.
2. Apply changes: `terraform apply -var-file="terraform.tfvars"`.
3. Connect to GCP instance via Identity-Aware Proxy:
   ```bash
   gcloud compute ssh vm-gcp-test --zone=us-east1-b --tunnel-through-iap
   ```
4. Ping the Azure test VM's private IP (`10.100.1.4`):
   ```bash
   ping -c 5 10.100.1.4
   traceroute -n 10.100.1.4
   ```

---

## Failover & Resilience Testing

To test automated active-active failover:

1. Initiate continuous ping from GCP to Azure test VM:
   ```bash
   ping 10.100.1.4
   ```
2. In Azure Portal or CLI, reset / disable Connection 1:
   ```bash
   az network vpn-connection update \
     --resource-group rg-hybrid-connectivity-prod \
     --name vgw-azure-hybrid-prod-to-gcp-conn-1 \
     --set connectionMode=Responder
   ```
3. Observe ping output: BGP immediately fails over to Tunnel 2 with 0 to 1 packet drop.

---

## Troubleshooting Guide

| Issue | Potential Root Cause | Remediation |
| :--- | :--- | :--- |
| **BGP Status Stuck in `Connecting` or `Active`** | Mismatched APIPA IP addresses or missing `/30` on GCP interface. | Verify GCP router interface has `/30` mask (`169.254.21.1/30`) and Azure APIPA address is exact host (`169.254.21.2`). |
| **IKE Phase 1 / Phase 2 SA Fails** | Mismatched PSKs or encryption algorithms. | Ensure `ipsec_policy` parameters on Azure match GCP default IKEv2 profiles (AES256, SHA256, DHGroup14). |
| **Packet Loss on Large Packets (MTU)** | IPsec encapsulation overhead exceeds path MTU. | Clamp TCP MSS on workloads to `1350` bytes or set interface MTU to `1440` (Azure) / `1460` (GCP). |
| **Asymmetric Routing / High Latency** | Unequal MED or route priority between tunnels. | Ensure both GCP BGP peers have identical `advertised_route_priority` (default `100`). |
| **Traffic Dropped at Workload** | NSG or GCP Firewall rule blocking cross-cloud CIDR. | Ensure Azure NSG allows `10.200.0.0/16` and GCP Firewall allows `10.100.0.0/16`. |

---

## Security & Production Best Practices

- **Zero Hardcoded Secrets**: Pre-shared keys are generated via crypto-random provider and never committed to source control.
- **Dedicated Subnets**: `GatewaySubnet` has a dedicated `/24` space and no NSG attached (as mandated by Azure).
- **VPC Flow Logs**: Enabled on GCP subnets for continuous audit and network forensics.
- **Zone Redundancy**: Azure Public IPs and Gateway use `VpnGw2AZ` with Availability Zones `1, 2, 3` for data center level fault tolerance.
- **State File Encryption**: Store remote backend state in Azure Blob Storage with customer-managed keys (CMK) or Google Cloud Storage with KMS encryption.

