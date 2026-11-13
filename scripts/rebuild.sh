#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DAILY="$ROOT/stacks/daily"

terraform -chdir="$DAILY" apply -auto-approve
aws eks update-kubeconfig --name epharmacy-tf --region ap-south-1

ROLE_ARN=$(terraform -chdir="$DAILY" output -raw alb_controller_role_arn)
VPC=$(terraform -chdir="$ROOT/stacks/persistent" output -raw vpc_id)
helm repo add eks https://aws.github.io/eks-charts >/dev/null && helm repo update >/dev/null
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --set clusterName=epharmacy-tf --set region=ap-south-1 --set vpcId=$VPC \
  --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ROLE_ARN" \
  --disable-openapi-validation
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller

"$ROOT/scripts/bootstrap-k8s.sh"

echo "Infrastructure is ready. Next: deploy the services with Helm (three stages),"
echo "apply the Ingress, then update CloudFront with the new ALB DNS."