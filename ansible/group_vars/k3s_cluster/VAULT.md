# Vault cheatsheet

Secrets live in `vault.yml` (this directory), encrypted with `ansible-vault` (AES256).
The file is safe to commit — no plaintext is visible.

All commands below are run from the `ansible/` directory.

## Day-to-day

```bash
# Edit secrets (decrypts in $EDITOR, re-encrypts on save)
# export EDITOR=nano if you prefer nano over vim
ansible-vault edit group_vars/k3s_cluster/vault.yml

# View secrets without editing
ansible-vault view group_vars/k3s_cluster/vault.yml
```

## Rotate passphrase

```bash
ansible-vault rekey group_vars/k3s_cluster/vault.yml
# Prompts for old passphrase, then new one
# Update .vault-pass and GH Actions secret afterward
```

## Decrypt / re-encrypt (for debugging)

```bash
# Decrypt to plaintext — don't commit!
ansible-vault decrypt group_vars/k3s_cluster/vault.yml

# Re-encrypt after editing
ansible-vault encrypt group_vars/k3s_cluster/vault.yml
```

## Avoid passphrase prompts

Create a `.vault-pass` file in the `ansible/` directory:

```bash
echo 'your-passphrase' > .vault-pass
chmod 600 .vault-pass
```

This is already configured in `ansible.cfg` and gitignored. All commands
(`ansible-vault`, `ansible-playbook`) will pick it up automatically.

## GH Actions

Store the passphrase as a repository secret (`ANSIBLE_VAULT_PASSWORD`), then in the workflow:

```yaml
- run: echo "${{ secrets.ANSIBLE_VAULT_PASSWORD }}" > .vault-pass
- run: ansible-playbook playbook.yml
```
