#!/usr/bin/env bash
# Hit both apps through their Services and check the database answers.
set -euo pipefail
NS=${NS:-laravel}
port=8081
for app in api web; do
  kubectl -n "$NS" port-forward "svc/$app-laravel-app" "$port:80" >/dev/null 2>&1 &
  pf=$!
  trap 'kill $pf 2>/dev/null || true' EXIT
  for _ in $(seq 20); do curl -fsS "localhost:$port/up" >/dev/null 2>&1 && break; sleep 1; done
  body=$(curl -fsS "localhost:$port/")
  echo "$app: $body"
  grep -q '"database":"ok"' <<<"$body" || { echo "$app: database check failed"; exit 1; }
  kill $pf; port=$((port + 1))
done
echo "smoke test passed"
