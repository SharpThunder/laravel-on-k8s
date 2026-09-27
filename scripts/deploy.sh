#!/usr/bin/env bash
# Deploy the dev dependencies and both apps into the current kubectl context.
# Used by `make up` (k3d) and by CI (kind). Images must already be in the cluster.
set -euo pipefail

NS=${NS:-laravel}
HELM_ARGS=${HELM_ARGS:-}
cd "$(dirname "$0")/.."

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Generate credentials once; re-runs keep the existing ones
if ! kubectl -n "$NS" get secret mariadb-auth >/dev/null 2>&1; then
  DB_PASS=$(openssl rand -hex 16)
  kubectl -n "$NS" create secret generic mariadb-auth \
    --from-literal=password="$DB_PASS" --from-literal=root-password="$(openssl rand -hex 16)"
  for app in api web; do
    kubectl -n "$NS" create secret generic "$app-env" \
      --from-literal=APP_KEY="base64:$(openssl rand -base64 32)" \
      --from-literal=DB_DATABASE="app_$app" \
      --from-literal=DB_USERNAME=app \
      --from-literal=DB_PASSWORD="$DB_PASS"
  done
fi

kubectl -n "$NS" apply -f deploy/dev/
kubectl -n "$NS" rollout status statefulset/mariadb --timeout=180s

for app in api web; do
  # shellcheck disable=SC2086
  helm upgrade --install "$app" charts/laravel-app -n "$NS" \
    -f "values/$app.yaml" --wait --timeout 5m $HELM_ARGS
done
