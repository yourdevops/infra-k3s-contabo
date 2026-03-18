# infra-k3s-contabo

IaC for yourdevops.me cluster on Contabo.

## Prerequisites

1. Set up a VM (Ubuntu 24.04)
2. Ensure SSH access works: `ssh admin@s01.yourdevops.me`

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

## Secrets

Encrypted with `ansible-vault` in `ansible/group_vars/k3s_cluster/vault.yml`.
See [VAULT.md](ansible/group_vars/k3s_cluster/VAULT.md) for usage cheatsheet.

## What it does

1. **Python venv** — installs python3-venv, creates `/opt/ansible-venv` with `kubernetes` and `jsonpatch` packages (required by `kubernetes.core` Ansible collection). All subsequent steps execute in this venv.
2. **OS baseline** — sets hostname, disables UFW, enables unattended-upgrades and fail2ban
3. **k3s** — installs k3s with Traefik and ServiceLB disabled
4. **Helm** — installs via apt
5. **ArgoCD** — installs via Helm chart, applies root Application pointing to `argocd/` in this repo

After the playbook runs, ArgoCD manages all cluster workloads via GitOps.

## Repo structure

```
ansible/
├── inventory.yml          # hosts + k3s config
├── requirements.yml       # Ansible collections
├── playbook.yml           # main orchestrator
├── group_vars/k3s_cluster/
│   ├── versions.yml       # pinned versions (k3s, Helm, ArgoCD)
│   └── vault.yml          # encrypted secrets
└── tasks/
    ├── python-venv.yml    # Python venv bootstrap
    ├── os-baseline.yml    # hostname, UFW, security
    ├── helm.yml           # Helm apt install
    ├── argocd.yml         # ArgoCD Helm chart
    └── argocd-bootstrap.yml  # root Application
argocd/                    # ArgoCD Application manifests (GitOps)
```
