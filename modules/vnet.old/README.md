# VNET Module (`modules/vnet`)

A reusable Azure VNET module with the following capabilities:
- Creates a **Virtual Network** with one or more **subnets**.
- Optionally creates per-subnet **Network Security Groups (NSGs)** and associates them.
- Supports **service endpoints** and **delegations** on subnets.
- Optionally enables **DDoS Standard** if a plan is provided.
- Exposes well-scoped **outputs** (vnet ID/name, subnet IDs map, nsg IDs map).

## Why this shape?
- Inputs are provided as **maps/objects** to avoid copy-paste and keep the module extensible.
- Defaults are secure; explicit flags are required for public exposure or DDoS features.
- Tags are required and validated for good governance.

## Module reference
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
