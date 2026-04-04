# CLAUDE.md

This repo is publicly available and represents IaC for a single-node k3s cluster (experimental/test stand) on Contabo. See [README.md](README.md) for full architecture and setup docs.

## Repo layout

- **Ansible** (`ansible/`) — provisions VM, installs k3s, Helm, ArgoCD
- **Terraform** (`terraform/`) — three TFC workspaces: `tfc-workspace-management/`, `cloudflare/`, `contabo/`
- **ArgoCD** (`argocd/`) — GitOps-managed cluster workloads (recursive app-of-apps, prune enabled, selfHeal disabled)

## Commands

Terraform commands run from `terraform/<module>/`. State is in TFC (org: `yourdevops`). Ansible commands run from `ansible/` — see [README.md](README.md) for details.

## Conventions

- Target host: `s01.yourdevops.me`, user `admin`, sudo via `become: true`
- Local kubectl commands should use `k3s-yourdevops` context
- All k8s Ansible tasks use `kubeconfig: "{{ kubeconfig }}"` (`/etc/rancher/k3s/k3s.yaml` on remote host)
- Cloudflare API token secret (`cloudflare-api-token`) duplicated into `cert-manager` and `external-dns` namespaces by Ansible
- Versions for Ansible-managed software are pinned in `group_vars/k3s_cluster/versions.yml`
- Secrets encrypted via `ansible-vault` in `group_vars/k3s_cluster/vault.yml` (`.vault-pass` auto-loaded by `ansible.cfg`)

And remember, if something doesn't work from the first try, relax, we'll definitely find a working solution -- you are working with a compentent human here you can rely on. No need to cut corners, we'll do it, maybe a bit longer, but we'll do it right and explore things in the process =) Because DevOps is fun!
