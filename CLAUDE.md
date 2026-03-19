# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

IaC for a single-node k3s cluster on Contabo (yourdevops.me). Three tools manage infrastructure:

- **Ansible** (`ansible/`) — provisions the VM, installs k3s, Helm, and ArgoCD
- **Terraform** (`terraform/`) — three isolated root modules, each a TFC workspace:
  - `tfc-workspace-management/` — manages the TFC workspaces themselves (bootstrap)
  - `cloudflare/` — DNS, Zero Trust Tunnel, tunnel config
  - `contabo/` — Contabo VMs and resources
- **ArgoCD manifests** (`argocd/`) — GitOps-managed cluster workloads (Kong ingress, cloudflared, ArgoCD server ingress)

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

All external traffic flows through: **Cloudflare edge (TLS termination) -> Cloudflare Tunnel -> cloudflared pods in cluster -> Kong ingress (ClusterIP) -> services**. TLS is terminated at the Cloudflare edge; internal traffic is plain HTTP. Terraform manages the wildcard CNAME (`*.yourdevops.me`) pointing to the tunnel.

### Ansible playbook order

`playbook.yml` runs four plays sequentially:
1. Python venv bootstrap (uses system python, creates `/opt/ansible-venv` with kubernetes/jsonpatch)
2. OS baseline (hostname, disable UFW, unattended-upgrades, fail2ban)
3. k3s install (delegates to `k3s.orchestration.site` collection — Traefik and ServiceLB disabled)
4. Bootstrap ArgoCD play on `server[0]`: Helm install, root Application, Cloudflare secrets

### Secrets

Encrypted via `ansible-vault` in `group_vars/k3s_cluster/vault.yml`. The vault password file is `.vault-pass` (gitignored), auto-loaded by `ansible.cfg`. Vault contains: k3s token, ArgoCD repo SSH key, cloudflared tunnel token.

### Pinned versions

All Ansible-managed component versions are centralized in `group_vars/k3s_cluster/versions.yml` (k3s, Helm, ArgoCD chart).

### ArgoCD app-of-apps

The Ansible bootstrap creates a root `Application` that watches `argocd/` on `main`. Any YAML added to `argocd/` is auto-synced (selfHeal + prune enabled). Current apps: Kong ingress controller, cloudflared deployment, ArgoCD server ingress.

## Conventions

- Target host: `s01.yourdevops.me`, user `admin`, sudo via `become: true`
- All k8s Ansible tasks use `kubeconfig: "{{ kubeconfig }}"` (points to `/etc/rancher/k3s/k3s.yaml`)
- Python interpreter on remote: `/opt/ansible-venv/bin/python` (set in inventory vars)
- Ansible tasks use FQCNs (`ansible.builtin.*`, `kubernetes.core.*`)
- Kong uses `ServerSideApply=true` sync option (required for its CRDs)
