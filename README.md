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
3. **k3s** — installs k3s with built-in Traefik disabled (managed via ArgoCD instead), ServiceLB enabled
4. **Helm** — installs via apt
5. **ArgoCD** — installs via Helm chart, applies root Application pointing to `argocd/` in this repo
6. **Cloudflare secrets** — creates Cloudflare API token secrets for cert-manager and external-dns

After the playbook runs, ArgoCD manages all cluster workloads via GitOps.

### Terraform

- **tfc-workspace-management/** — bootstraps and manages the TFC workspaces themselves
- **cloudflare/** — DNS zone, Zero Trust Tunnel (idle, reserved for future WARP-only services), SSL settings
- **contabo/** — Contabo VMs and resources

### Networking

External traffic flows through: **Client → Cloudflare proxy (SSL Full Strict) → DNS A record → Traefik (LoadBalancer, ports 80/443 via k3s ServiceLB) → services**.

DNS records are Cloudflare-proxied by default (managed by external-dns with `--cloudflare-proxied`). Cloudflare SSL mode is Full (Strict). TLS is terminated at Traefik using a wildcard Let's Encrypt certificate (`*.yourdevops.me`) obtained by cert-manager via DNS-01 challenge against Cloudflare. HTTP requests are redirected to HTTPS. Traefik trusts Cloudflare forwarded headers to preserve real client IPs.

Routing uses the Kubernetes Gateway API: Traefik deploys a `GatewayClass` + `Gateway` with HTTP/HTTPS listeners. `HTTPRoute` resources in service namespaces attach to the Gateway. external-dns watches HTTPRoute hostnames and auto-creates/deletes proxied A records in Cloudflare.

The Cloudflare Zero Trust Tunnel and cloudflared pods remain deployed but idle — reserved for future WARP-only private services.

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
    ├── cloudflare-secrets.yml # cloudflared tunnel token
    └── cloudflare-dns-token.yml # API token for cert-manager & external-dns
argocd/infra/                  # ArgoCD-managed manifests (GitOps)
├── traefik.yaml               # Traefik ingress controller (Gateway API)
├── cert-manager.yaml          # cert-manager (Let's Encrypt DNS-01)
├── external-dns.yaml          # external-dns (Cloudflare, proxied)
├── cloudflared.yaml           # cloudflared tunnel (idle)
├── argocd-route.yaml          # ArgoCD HTTPRoute
└── configs/
    └── cert-manager/
        ├── clusterissuer.yaml     # Let's Encrypt ClusterIssuer
        └── wildcard-certificate.yaml # *.yourdevops.me wildcard cert
terraform/
├── tfc-workspace-management/  # TFC workspace bootstrap
├── cloudflare/                # DNS + Zero Trust Tunnel + SSL
└── contabo/                   # Contabo VMs
```
