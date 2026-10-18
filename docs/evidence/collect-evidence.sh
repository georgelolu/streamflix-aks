#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

OUTPUT="docs/evidence/deployment-verification.txt"
mkdir -p "$(dirname "$OUTPUT")"

{
  echo "=================================================="
  echo "StreamFlix AKS Deployment Verification"
  echo "=================================================="
  echo "Collected (UTC): $(date -u '+%Y-%m-%d %H:%M:%S')"
  echo "Repository: $(git remote get-url origin 2>/dev/null || echo unknown)"
  echo "Commit: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
  echo

  echo "===== Git working tree ====="
  git status -sb || true
  echo

  echo "===== Kubernetes context ====="
  kubectl config current-context 2>&1 || true
  echo

  echo "===== Namespace ====="
  kubectl get namespace streamflix 2>&1 || true
  echo

  echo "===== Deployment ====="
  kubectl get deployment streamflix -n streamflix -o wide 2>&1 || true
  echo

  echo "===== Rollout status ====="
  kubectl rollout status deployment/streamflix \
    -n streamflix --timeout=180s 2>&1 || true
  echo

  echo "===== Deployed image ====="
  kubectl get deployment streamflix -n streamflix \
    -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}' \
    2>&1 || true
  echo

  echo "===== Pods ====="
  kubectl get pods -n streamflix -o wide 2>&1 || true
  echo

  echo "===== Service ====="
  kubectl get service streamflix -n streamflix -o wide 2>&1 || true
  echo

  echo "===== Application health endpoint ====="
  if curl -fsS --max-time 5 http://localhost:8088/health; then
    echo
    echo "Health check: PASS"
  else
    echo "Health check: NOT VERIFIED"
    echo "If port-forward is not running, start it in another terminal:"
    echo "kubectl port-forward -n streamflix service/streamflix 8088:80"
  fi
  echo

  echo "===== Application HTTP response ====="
  curl -sS --max-time 5 -o /dev/null \
    -w 'HTTP status: %{http_code}\n' \
    http://localhost:8088/ || true
  echo

  echo "===== GitHub Actions workflow ====="
  echo "https://github.com/georgelolu/streamflix-aks/actions/workflows/deploy.yml"
  echo "Previously successful run: 39134172236"
  echo

  echo "===== End of verification ====="
} 2>&1 | tee "$OUTPUT"

echo
echo "Evidence saved to: $OUTPUT"
