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

## Load testing

### hey (recommended for autoscaling tests)

Uses [hey](https://github.com/rakyll/hey) with `-disable-keepalive` so new connections
are distributed evenly across all pods, including ones added by KEDA mid-test.

```bash
# Sustained load — 200 concurrent, 5 minutes, no keep-alive
kubectl run load-test --rm -it --restart=Never \
  --image=williamyeh/hey:latest -n rollouts-demo -- \
  -c 200 -z 300s -disable-keepalive http://rollouts-demo-internal/color
```

### wrk (for single-pod saturation)

Uses `argoproj/load-tester` image with [wrk](https://github.com/wg/wrk) built in.
wrk uses persistent connections, so new pods added mid-test won't receive traffic
until wrk is restarted.

```bash
# 1. Scale to a single replica (disable autoscaler before that!)
kubectl argo rollouts set replicas rollouts-demo 1 -n rollouts-demo

# 2. Run wrk — increase -c (10 → 25 → 50 → 100) to find saturation
kubectl run load-test --rm -it --restart=Never \
  --image=argoproj/load-tester:latest -n rollouts-demo -- \
  sh -c 'wrk -t4 -c200 -d600s -s /report.lua http://rollouts-demo-internal/color && cat /report.json'

# 3. Restore replica count
kubectl argo rollouts set replicas rollouts-demo 5 -n rollouts-demo
```

`report.json` fields: `requests_per_second`, `errors_ratio`, `latency_avg_ms`, `latency_max_ms`.
Set KEDA threshold to ~70% of the RPS where latency starts degrading.

## URLs

- https://rollouts-demo.yourdevops.me
- https://grafana.yourdevops.me


## Kube-Proxy

```bash
kubectl port-forward -n victoria-metrics victoria-metrics-server-0 8428:8428 --context k3s-yourdevops
```