#!/usr/bin/env bash
set -euo pipefail

CHART="${1:?usage: $0 <path-to-helm-chart>}"
NS=epharmacy
REL=epharmacy

# Keys as they appear in values.yaml
ALL=(eureka user medicine cart payment order api-gateway)

# deploy <keys...>: enable the listed services, disable the rest, for this run only
deploy() {
  local sets=() k
  for k in "${ALL[@]}"; do
    if [[ " $* " == *" $k "* ]]; then
      sets+=(--set "$k.enabled=true")
    else
      sets+=(--set "$k.enabled=false")
    fi
  done
  helm upgrade --install "$REL" "$CHART" -n "$NS" --create-namespace "${sets[@]}"
}

# Wait until each deployment is actually ready, instead of sleeping
wait_for() {
  for d in "$@"; do
    kubectl -n "$NS" rollout status "deploy/$d" --timeout=300s
  done
}

echo "== Stage 1: eureka"
deploy eureka
wait_for eureka

echo "== Stage 2: user, medicine, cart, payment"
deploy eureka user medicine cart payment
wait_for user-service medicine-service cart-service payment-service

echo "== Stage 3: order and gateway (plain upgrade, values.yaml as written)"
helm upgrade --install "$REL" "$CHART" -n "$NS"
wait_for order-service api-gateway-service

kubectl get pods -n "$NS"