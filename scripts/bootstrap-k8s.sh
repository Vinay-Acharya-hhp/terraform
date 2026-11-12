#!/usr/bin/env bash
# Creates the namespace, Secret, ConfigMap and databases from Terraform outputs.
# Safe to rerun. Run it after every `terraform apply` of the daily stack.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DAILY="$ROOT/stacks/daily"
PERSISTENT="$ROOT/stacks/persistent"
NS=epharmacy

RDS_HOST=$(terraform -chdir="$DAILY" output -raw rds_endpoint)
REDIS_HOST=$(terraform -chdir="$DAILY" output -raw redis_endpoint)
DB_PASSWORD=$(terraform -chdir="$DAILY" output -raw db_password)
CF_DOMAIN=$(terraform -chdir="$PERSISTENT" output -raw cloudfront_domain)

for v in RDS_HOST REDIS_HOST DB_PASSWORD CF_DOMAIN; do
  [ -n "${!v}" ] || { echo "ERROR: $v is empty"; exit 1; }
done
echo "RDS=$RDS_HOST"
echo "REDIS=$REDIS_HOST"
echo "CORS=https://$CF_DOMAIN"

# Namespace
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Keep an existing JWT secret on reruns, generate a new one otherwise
JWT_SECRET=$(kubectl -n "$NS" get secret epharmacy-secrets \
  -o jsonpath='{.data.JWT_SECRET}' 2>/dev/null | base64 -d || true)
[ -n "$JWT_SECRET" ] || JWT_SECRET=$(openssl rand -base64 32)

# Secret: passwords only
kubectl -n "$NS" create secret generic epharmacy-secrets \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

# ConfigMap: hostnames, URLs, ports, CORS origin
kubectl -n "$NS" create configmap epharmacy-config \
  --from-literal=DB_USERNAME=admin \
  --from-literal=REDIS_HOST="$REDIS_HOST" \
  --from-literal=REDIS_PORT=6379 \
  --from-literal=EUREKA=http://eureka:8761/eureka/ \
  --from-literal=CORS_ALLOWED_ORIGINS="https://$CF_DOMAIN" \
  --from-literal=DB_URL_USER="jdbc:mysql://$RDS_HOST:3306/user_db" \
  --from-literal=DB_URL_MEDICINE="jdbc:mysql://$RDS_HOST:3306/medicine_db" \
  --from-literal=DB_URL_CART="jdbc:mysql://$RDS_HOST:3306/cart_db" \
  --from-literal=DB_URL_ORDER="jdbc:mysql://$RDS_HOST:3306/order_db" \
  --from-literal=DB_URL_PAYMENT="jdbc:mysql://$RDS_HOST:3306/payment_db" \
  --dry-run=client -o yaml | kubectl apply -f -

# Databases (RDS is recreated every night, so they must be recreated too)
kubectl -n "$NS" run mysql-client --rm -i --restart=Never --image=mysql:8.4 \
  --env="MYSQL_PWD=$DB_PASSWORD" --command -- \
  mysql -h "$RDS_HOST" -u admin -e \
  "CREATE DATABASE IF NOT EXISTS user_db; CREATE DATABASE IF NOT EXISTS medicine_db; CREATE DATABASE IF NOT EXISTS cart_db; CREATE DATABASE IF NOT EXISTS order_db; CREATE DATABASE IF NOT EXISTS payment_db; SHOW DATABASES;"

echo "Done."