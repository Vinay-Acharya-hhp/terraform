#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DAILY="$ROOT/stacks/daily"
PERSISTENT="$ROOT/stacks/persistent"
CHART="$ROOT/helm"
INGRESS="$ROOT/helm/extras/ingress.yaml"
NS=epharmacy

# 0. Pre-checks
[ -f "$DAILY/terraform.tfvars" ] || { echo "Missing $DAILY/terraform.tfvars (zone pins)"; exit 1; }
[ -f "$CHART/Chart.yaml" ]       || { echo "No Chart.yaml in $CHART"; exit 1; }
[ -f "$INGRESS" ]                || { echo "Missing $INGRESS"; exit 1; }

# 1. Infrastructure
terraform -chdir="$DAILY" init -input=false >/dev/null
terraform -chdir="$DAILY" apply -auto-approve
aws eks update-kubeconfig --name epharmacy-tf --region ap-south-1
kubectl get nodes

# 2. ALB controller (the IAM role is new every day)
ROLE_ARN=$(terraform -chdir="$DAILY" output -raw alb_controller_role_arn)
VPC=$(terraform -chdir="$PERSISTENT" output -raw vpc_id)
helm repo add eks https://aws.github.io/eks-charts >/dev/null && helm repo update >/dev/null
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=epharmacy-tf --set region=ap-south-1 --set vpcId="$VPC" \
  --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ROLE_ARN" \
  --disable-openapi-validation
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller --timeout=300s

# 3. Namespace, Secret, ConfigMap, databases
"$ROOT/scripts/bootstrap-k8s.sh"
