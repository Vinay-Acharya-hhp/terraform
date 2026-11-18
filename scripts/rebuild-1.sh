
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DAILY="$ROOT/stacks/daily"
PERSISTENT="$ROOT/stacks/persistent"
CHART="$ROOT/helm"
INGRESS="$ROOT/helm/extras/ingress.yaml"
NS=epharmacy


# 5. Ingress, then wait for the ALB hostname
kubectl apply -f "$INGRESS"
echo "Waiting for the ALB address..."
ALB_DNS=""
for _ in $(seq 1 60); do
  ALB_DNS=$(kubectl -n "$NS" get ingress epharmacy-api \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  [ -n "$ALB_DNS" ] && break
  sleep 10
done
[ -n "$ALB_DNS" ] || { echo "ERROR: no ALB address after 10 minutes"; exit 1; }
echo "ALB=$ALB_DNS"

# 6. Point CloudFront at the new ALB (replaces the manual origin edit)
echo "alb_dns_name = \"$ALB_DNS\"" > "$PERSISTENT/alb.auto.tfvars"
terraform -chdir="$PERSISTENT" apply -auto-approve     # waits for CloudFront, 5-10 min

# 7. Smoke test
CF=$(terraform -chdir="$PERSISTENT" output -raw cloudfront_domain)
echo "Site: https://$CF/"
echo -n "frontend: "; curl -s -o /dev/null -w "%{http_code}\n" "https://$CF/"
echo -n "api (500 or 429 with JSON is good): "
curl -s -o /dev/null -w "%{http_code}\n" -X POST "https://$CF/api/customer/login" \
  -H "Content-Type: application/json" -d '{}'
echo "A 502 in the first minute is normal while the ALB target turns healthy. Rerun the curl."