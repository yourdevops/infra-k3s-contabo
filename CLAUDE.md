# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

IaC for a single-node k3s cluster on Contabo (yourdevops.me). Three tools manage infrastructure:

- **Ansible** (`ansible/`) — provisions the VM, installs k3s, Helm, and ArgoCD
- **Terraform** (`terraform/`) — three isolated root modules, each a TFC workspace:
  - `tfc-workspace-management/` — manages the TFC workspaces themselves (bootstrap)
  - `cloudflare/` — DNS zone, Zero Trust Tunnel (idle, for future WARP-only services), SSL settings
  - `contabo/` — Contabo VMs and resources
- **ArgoCD manifests** (`argocd/`) — GitOps-managed cluster workloads (recursive directory scan)
  - `argocd/infra/` — infrastructure ArgoCD Applications and raw manifests
  - `argocd/infra/configs/` — raw k8s manifests (ClusterIssuer, Certificate, GatewayClass, Gateway) applied directly by root app

After the Ansible playbook runs, ArgoCD takes over all workload management via the `argocd/` directory.

## Commands

All Ansible commands run from `ansible/`.

```bash
# Install Ansible collections (one-time)
ansible-galaxy collection install -r requirements.yml

# Run the full playbook
ansible-playbook playbook.yml

# Run a specific task file only (e.g., just ArgoCD)
ansible-playbook playbook.yml --tags argocd  # if tagged, otherwise use --start-at-task

# Vault operations
ansible-vault edit group_vars/k3s_cluster/vault.yml   # edit secrets
ansible-vault view group_vars/k3s_cluster/vault.yml   # view secrets
```

Terraform commands run from the relevant subdirectory (e.g., `terraform/cloudflare/`):

```bash
terraform init    # first time / after provider changes
terraform plan
terraform apply
```

State is managed by Terraform Cloud (org: `yourdevops`). The `tfc-workspace-management/` workspace is bootstrapped first manually; it then manages the other workspaces via VCS-driven runs.

## Architecture

### Networking path

External traffic flows through: **Client -> DNS (per-host A records managed by external-dns) -> Kong Gateway (LoadBalancer, ports 80/443 via k3s ServiceLB) -> services**. TLS is terminated at Kong using a wildcard Let's Encrypt certificate (`*.yourdevops.me`) obtained by cert-manager via DNS-01 challenge against Cloudflare. Internal traffic (Kong -> services) is plain HTTP.

Routing uses the Kubernetes Gateway API: a `GatewayClass` + `Gateway` resource in the `kong` namespace defines HTTP/HTTPS listeners, and `HTTPRoute` resources in service namespaces attach to it. external-dns watches HTTPRoute hostnames and auto-creates/deletes A records in Cloudflare. The Cloudflare Zero Trust Tunnel and cloudflared pods remain deployed but idle — reserved for future WARP-only private services.

### Ansible playbook order

`playbook.yml` runs four plays sequentially:
1. Python venv bootstrap (uses system python, creates `/opt/ansible-venv` with kubernetes/jsonpatch)
2. OS baseline (hostname, disable UFW, unattended-upgrades, fail2ban)
3. k3s install (delegates to `k3s.orchestration.site` collection — Traefik disabled, ServiceLB enabled)
4. Bootstrap ArgoCD play on `server[0]`: Helm install, root Application, Cloudflare secrets (tunnel token + API token for cert-manager and external-dns)

### Secrets

Encrypted via `ansible-vault` in `group_vars/k3s_cluster/vault.yml`. The vault password file is `.vault-pass` (gitignored), auto-loaded by `ansible.cfg`. Vault contains: k3s token, ArgoCD repo SSH key, cloudflared tunnel token, Cloudflare API token (DNS edit).

### Pinned versions

All Ansible-managed component versions are centralized in `group_vars/k3s_cluster/versions.yml` (k3s, Helm, ArgoCD chart).

### ArgoCD app-of-apps

The Ansible bootstrap creates a root `Application` that watches `argocd/` on `main` with `directory.recurse: true`. Any YAML added anywhere under `argocd/` is auto-synced (selfHeal + prune enabled). Current contents: Gateway API CRDs, Kong, cert-manager, external-dns (Helm Applications), cloudflared (raw Deployment), ArgoCD HTTPRoute, and configs (ClusterIssuer, wildcard Certificate, GatewayClass, Gateway).

### TLS and certificates

cert-manager obtains a wildcard certificate (`*.yourdevops.me` + `yourdevops.me`) from Let's Encrypt using DNS-01 challenge via Cloudflare API. The certificate Secret (`wildcard-yourdevops-me-tls`) lives in the `kong` namespace. The Gateway HTTPS listener references this secret for TLS termination. Cloudflare zone SSL is set to Full (Strict).

## Conventions

- Target host: `s01.yourdevops.me`, user `admin`, sudo via `become: true`
- All k8s Ansible tasks use `kubeconfig: "{{ kubeconfig }}"` (points to `/etc/rancher/k3s/k3s.yaml`)
- Python interpreter on remote: `/opt/ansible-venv/bin/python` (set in inventory vars)
- Ansible tasks use FQCNs (`ansible.builtin.*`, `kubernetes.core.*`)
- Kong uses `ServerSideApply=true` sync option (required for its CRDs)
- Cloudflare API token secret (`cloudflare-api-token`) is duplicated into `cert-manager` and `external-dns` namespaces by Ansible
