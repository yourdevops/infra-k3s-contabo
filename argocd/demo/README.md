# Argo Rollouts Demo Cheatsheet

## Watch rollout status (real-time)

```bash
# Canary
kubectl argo rollouts get rollout canary-demo -n canary-demo -w
# Header-canary
kubectl argo rollouts get rollout header-demo -n header-demo -w
# Blue-green
kubectl argo rollouts get rollout bg-demo -n bg-demo -w
```

## Trigger a rollout

Change the image tag in the ArgoCD Application manifest and push to Git.

Available tags: `blue`, `green`, `yellow`, `orange`, `red`, `purple`
Error injection: `bad-red`, `bad-green`, `bad-yellow`, etc. (HTTP 500s)
Latency injection: `slow-red`, `slow-green`, etc. (2s delay per request)

## Promote

```bash
kubectl argo rollouts promote canary-demo -n canary-demo        # canary: next step
kubectl argo rollouts promote header-demo -n header-demo        # header-canary: next step
kubectl argo rollouts promote canary-demo -n canary-demo --full # skip all remaining steps
kubectl argo rollouts promote bg-demo -n bg-demo                # blue-green: switch active
kubectl argo rollouts abort canary-demo -n canary-demo          # abort
kubectl argo rollouts retry rollout canary-demo -n canary-demo  # retry
```

## URLs

- https://canary-demo.yourdevops.me
- https://header-demo.yourdevops.me
- https://bg-demo.yourdevops.me
- https://bg-demo-preview.yourdevops.me
