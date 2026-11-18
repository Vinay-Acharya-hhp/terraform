#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INGRESS="$ROOT/helm/extras/ingress.yaml"

kubectl delete -f "$INGRESS" --ignore-not-found
echo "Waiting for the ALB to be deleted..."
while [ -n "$(aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName' --output text)" ]; do
  sleep 10
done

helm uninstall epharmacy -n epharmacy 2>/dev/null || true

terraform -chdir="$ROOT/stacks/daily" destroy -auto-approve
rm -f "$ROOT/stacks/persistent/alb.auto.tfvars"
echo "Torn down. Run the verify commands to confirm nothing billable remains."