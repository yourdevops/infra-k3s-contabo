# Argo Rollouts Demo Cheatsheet

## Watch rollout status (real-time)

```bash
# Canary
kubectl argo rollouts get rollout rollouts-demo -n rollouts-demo -w
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
kubectl argo rollouts promote rollouts-demo -n rollouts-demo        # canary: next step
kubectl argo rollouts promote header-demo -n header-demo        # header-canary: next step
kubectl argo rollouts promote rollouts-demo -n rollouts-demo --full # skip all remaining steps
kubectl argo rollouts promote bg-demo -n bg-demo                # blue-green: switch active
kubectl argo rollouts abort rollouts-demo -n rollouts-demo          # abort
kubectl argo rollouts retry rollout rollouts-demo -n rollouts-demo  # retry
```

## Load testing (single-pod saturation)

Uses `argoproj/load-tester` image with [wrk](https://github.com/wg/wrk) built in.

```bash
# 1. Scale to a single replica (disable autoscaler before that!)
kubectl argo rollouts set replicas rollouts-demo 1 -n rollouts-demo

# 2. Run wrk — increase -c (10 → 25 → 50 → 100) to find saturation
kubectl run load-test --rm -it --restart=Never \
  --image=argoproj/load-tester:latest -n rollouts-demo -- \
  sh -c 'wrk -t4 -c150 -d300s -s /report.lua http://rollouts-demo-internal/color && cat /report.json'

# 3. Restore replica count
kubectl argo rollouts set replicas rollouts-demo 5 -n rollouts-demo
```

`report.json` fields: `requests_per_second`, `errors_ratio`, `latency_avg_ms`, `latency_max_ms`.
Set KEDA threshold to ~70% of the RPS where latency starts degrading.

## URLs

- https://rollouts-demo.yourdevops.me
- https://grafana.yourdevops.me
- https://bg-demo.yourdevops.me
- https://bg-demo-preview.yourdevops.me
