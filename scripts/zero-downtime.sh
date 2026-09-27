#!/usr/bin/env bash
# Prove a rolling upgrade drops no requests: an in-cluster pod calls the API
# every 100 ms while `helm upgrade` replaces every pod, then reports failures.
set -euo pipefail
NS=${NS:-laravel}
DURATION=${DURATION:-120}

kubectl -n "$NS" delete pod probe --ignore-not-found
kubectl -n "$NS" run probe --image=curlimages/curl:8.10.1 --restart=Never --command -- sh -c "
  ok=0; fail=0; end=\$(( \$(date +%s) + $DURATION ))
  while [ \$(date +%s) -lt \$end ]; do
    if curl -fs -o /dev/null --max-time 2 http://api-laravel-app/up; then ok=\$((ok+1)); else fail=\$((fail+1)); fi
    sleep 0.1
  done
  echo \"requests ok=\$ok failed=\$fail\"
  [ \$fail -eq 0 ]"
kubectl -n "$NS" wait --for=condition=Ready pod/probe --timeout=60s

# Force new pods: same images, new annotation
HELM_ARGS="${HELM_ARGS:-} --set-string podAnnotations.rollout=$(date +%s)" ./scripts/deploy.sh

while phase=$(kubectl -n "$NS" get pod probe -o jsonpath='{.status.phase}'); [ "$phase" = Running ]; do sleep 5; done
kubectl -n "$NS" logs probe
[ "$phase" = Succeeded ]
