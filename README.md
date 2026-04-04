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

Terraform is managed via Terraform Cloud (org: `yourdevops`). Each subdirectory under `terraform/` is a separate TFC workspace with VCS-driven runs on `main`. The `tfc-workspace-management/` workspace is bootstrapped first manually; it then manages the other workspaces.

## Architecture

### Ansible playbook

`playbook.yml` runs four plays sequentially:

1. **Python venv** — installs python3-venv, creates `/opt/ansible-venv` with `kubernetes` and `jsonpatch` packages (required by `kubernetes.core` Ansible collection)
2. **OS baseline** — sets hostname, disables UFW, enables unattended-upgrades and fail2ban
3. **k3s** — installs k3s via `k3s.orchestration.site` collection with built-in Traefik disabled (Envoy Gateway managed via ArgoCD instead), ServiceLB enabled
4. **ArgoCD bootstrap** on `server[0]` — Helm install, root Application pointing to `argocd/` in this repo, Cloudflare secrets (tunnel token + API token for cert-manager and external-dns)

After the playbook runs, ArgoCD manages all cluster workloads via GitOps.

### Terraform

- **tfc-workspace-management/** — bootstraps and manages the TFC workspaces themselves
- **cloudflare/** — DNS zone, Zero Trust Tunnel (idle, reserved for future WARP-only services), SSL settings, Authenticated Origin Pulls (mTLS certs + zone-level AOP)
- **contabo/** — Contabo VMs and resources

### Networking

External traffic flows through: **Client → DNS (per-host A records managed by external-dns) → Envoy Gateway (LoadBalancer, ports 80/443 via k3s ServiceLB) → services**. TLS is terminated at Envoy Gateway using a wildcard Let's Encrypt certificate (`*.yourdevops.me`) obtained by cert-manager via DNS-01 challenge against Cloudflare. Internal traffic (Envoy Gateway → services) is plain HTTP.

Routing uses the Kubernetes Gateway API: Envoy Gateway (v1.7.1) provides the `GatewayClass` controller. Raw manifests in `argocd/infra/configs/envoy-gateway/` define the GatewayClass, Gateway (HTTP + HTTPS listeners), EnvoyProxy (data plane config, access logs, security), ClientTrafficPolicy (Cloudflare trusted proxy), and an HTTP-to-HTTPS redirect HTTPRoute. The Envoy Gateway controller automatically provisions data plane Envoy Proxy pods and a LoadBalancer Service when the Gateway resource is created. `HTTPRoute` resources in service namespaces attach to the Gateway. external-dns watches HTTPRoute hostnames and auto-creates/deletes A records in Cloudflare.

The Cloudflare Zero Trust Tunnel and cloudflared pods remain deployed but idle — reserved for future WARP-only private services.

### TLS and certificates

cert-manager obtains a wildcard certificate (`*.yourdevops.me` + `yourdevops.me`) from Let's Encrypt using DNS-01 challenge via Cloudflare API. The certificate Secret (`wildcard-yourdevops-me-tls`) lives in the `envoy-gateway-system` namespace (same namespace as the Gateway). The Gateway HTTPS listener references this secret for TLS termination. Cloudflare zone SSL is set to Full (Strict).

### mTLS — Cloudflare Authenticated Origin Pulls

Envoy Gateway requires a valid client certificate on every HTTPS connection, proving traffic originates from our Cloudflare zone. This uses zone-level Authenticated Origin Pulls (AOP) with custom PKI (not Cloudflare's shared CA).

**Trust chain**: Terraform (`terraform/cloudflare/aop.tf`) generates a private CA and leaf cert via the `tls` provider. The leaf cert is uploaded to Cloudflare (zone-level AOP). The CA cert (public, not sensitive) is stored in a ConfigMap (`cloudflare-origin-ca` in `envoy-gateway-system`), referenced by the `ClientTrafficPolicy` for client certificate validation.

**Responsibility split**:
- Terraform: CA + leaf generation, Cloudflare AOP cert upload + enablement (`aop.tf`)
- ArgoCD: CA Secret (`cloudflare-origin-ca-secret.yaml`), ClientTrafficPolicy with `tls.clientValidation`

**Cert rotation**:
1. Leaf only: `terraform -chdir=terraform/cloudflare taint tls_private_key.aop_leaf` → `apply`
2. Full CA: `terraform -chdir=terraform/cloudflare taint tls_private_key.aop_ca` → `apply`
3. After either: update `ca.crt` in `cloudflare-origin-ca.yaml` from `terraform output -raw aop_ca_cert_pem` → push → ArgoCD syncs

### ArgoCD app-of-apps

The Ansible bootstrap creates a root `Application` that watches `argocd/` on `main` with `directory.recurse: true`. Any YAML added anywhere under `argocd/` is auto-synced (prune enabled, selfHeal disabled). Current contents: Envoy Gateway (Helm Application + raw config manifests for GatewayClass, Gateway, EnvoyProxy, ClientTrafficPolicy, TLS redirect), cert-manager, external-dns, Argo Rollouts (Helm Applications), cloudflared (raw Deployment), ArgoCD HTTPRoute, pathfinder HTTPRoute, and configs (ClusterIssuer, wildcard Certificate).

## Secrets

Encrypted with `ansible-vault` in `ansible/group_vars/k3s_cluster/vault.yml`. The vault password file is `.vault-pass` (gitignored), auto-loaded by `ansible.cfg`. Vault contains: k3s token, ArgoCD repo SSH key, cloudflared tunnel token, Cloudflare API token (DNS edit).

See [VAULT.md](ansible/group_vars/k3s_cluster/VAULT.md) for usage cheatsheet.

### Pinned versions

All Ansible-managed component versions are centralized in `group_vars/k3s_cluster/versions.yml` (k3s, Helm, ArgoCD chart).

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
├── envoy-gateway.yaml         # Envoy Gateway ingress controller (Gateway API)
├── cert-manager.yaml          # cert-manager (Let's Encrypt DNS-01)
├── external-dns.yaml          # external-dns (Cloudflare)
├── argo-rollouts.yaml         # Argo Rollouts
├── cloudflared.yaml           # cloudflared tunnel (idle)
├── argocd-route.yaml          # ArgoCD HTTPRoute
└── configs/
    ├── cert-manager/
    │   ├── clusterissuer.yaml     # Let's Encrypt ClusterIssuer
    │   └── wildcard-certificate.yaml # *.yourdevops.me wildcard cert
    └── envoy-gateway/
        ├── gateway-class.yaml     # GatewayClass
        ├── gateway.yaml           # Gateway (HTTP + HTTPS listeners)
        ├── envoy-proxy.yaml       # EnvoyProxy data plane config
        ├── client-traffic-policy.yaml # Cloudflare trusted proxy + mTLS
        └── redirect-http.yaml     # HTTP-to-HTTPS redirect
terraform/
├── tfc-workspace-management/  # TFC workspace bootstrap
├── cloudflare/                # DNS + Zero Trust Tunnel + SSL + AOP
└── contabo/                   # Contabo VMs
```
