# infra-k3s-contabo

IaC for a single-node k3s cluster on Contabo (yourdevops.me).

## Prerequisites

1. Set up a VM (Ubuntu 24.04)
2. Ensure SSH access works: `ssh admin@s01.yourdevops.me`
3. Copy `.envrc.example` to `.envrc` and fill in secrets (used by direnv)

## Install dependencies

```bash
# Ansible (works on macOS and Linux via Homebrew)
brew install ansible

# Ansible collections
cd ansible
ansible-galaxy collection install -r requirements.yml
```

## Run

```bash
cd ansible
ansible-playbook playbook.yml
```

Terraform is managed via Terraform Cloud (org: `yourdevops`). Each subdirectory under `terraform/` is a separate TFC workspace with VCS-driven runs on `main`.

## Secrets

Encrypted with `ansible-vault` in `ansible/group_vars/k3s_cluster/vault.yml`.
See [VAULT.md](ansible/group_vars/k3s_cluster/VAULT.md) for usage cheatsheet.

## What it does

### Ansible playbook

1. **Python venv** — installs python3-venv, creates `/opt/ansible-venv` with `kubernetes` and `jsonpatch` packages (required by `kubernetes.core` Ansible collection)
2. **OS baseline** — sets hostname, disables UFW, enables unattended-upgrades and fail2ban
3. **k3s** — installs k3s with Traefik and ServiceLB disabled
4. **Helm** — installs via apt
5. **ArgoCD** — installs via Helm chart, applies root Application pointing to `argocd/` in this repo
6. **Cloudflare secrets** — creates the cloudflared tunnel token secret in the cluster

After the playbook runs, ArgoCD manages all cluster workloads via GitOps.

### Terraform

- **tfc-workspace-management/** — bootstraps and manages the TFC workspaces themselves
- **cloudflare/** — DNS zone, Zero Trust Tunnel, tunnel config, wildcard CNAME
- **contabo/** — Contabo VMs and resources

### Networking

All external traffic flows through: Cloudflare edge (TLS termination) -> Cloudflare Tunnel -> cloudflared pods -> Kong ingress (ClusterIP) -> services.

## Repo structure

```
ansible/
├── inventory.yml              # hosts + k3s config
├── requirements.yml           # Ansible collections
├── playbook.yml               # main orchestrator
├── group_vars/k3s_cluster/
│   ├── versions.yml           # pinned versions (k3s, Helm, ArgoCD)
│   └── vault.yml              # encrypted secrets
└── tasks/
    ├── python-venv.yml        # Python venv bootstrap
    ├── os-baseline.yml        # hostname, UFW, security
    ├── helm.yml               # Helm apt install
    ├── argocd.yml             # ArgoCD Helm chart
    ├── argocd-bootstrap.yml   # root Application
    └── cloudflare-secrets.yml # cloudflared tunnel token
argocd/                        # ArgoCD-managed manifests (GitOps)
├── kong.yaml                  # Kong ingress controller
├── cloudflared.yaml           # cloudflared tunnel deployment
└── argocd-ingress.yaml        # ArgoCD server ingress
terraform/
├── tfc-workspace-management/  # TFC workspace bootstrap
├── cloudflare/                # DNS + Zero Trust Tunnel
└── contabo/                   # Contabo VMs
```
