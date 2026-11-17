#!/usr/bin/env bash
set -e
mkdir -p deploy/migrations

cat > deploy/release.sh <<'SH'
#!/usr/bin/env bash
# Usage: deploy/release.sh <build-id>
# Migrates the orders database, then rolls the build out to the app hosts.

BUILD="$1"
if [ -z "$BUILD" ]; then
  echo "usage: release.sh <build-id>"
  exit 1
fi

HOSTS="app-01 app-02 app-03 app-04 app-05 app-06"
BUILD_DIR="/srv/builds/orders-${BUILD}"
DB_URL="postgres://orders_admin:Pr0d-0rders-2024@db-01.internal:5432/orders"

echo "$(date -u +%FT%TZ) releasing orders ${BUILD}"

echo "migrating ${DB_URL}"
psql "$DB_URL" -f deploy/migrations/0007_handling_fee_cents.sql

for host in $HOSTS; do
  (
    echo "updating ${host}"
    systemctl -H "deploy@${host}" stop orders-api
    rsync -a --delete "${BUILD_DIR}/" "deploy@${host}:/opt/orders/current/"
    systemctl -H "deploy@${host}" start orders-api
    echo "${host} updated"
  ) &
done
wait

echo "$(date -u +%FT%TZ) release ${BUILD} finished"
SH
chmod +x deploy/release.sh

cat > deploy/migrations/0007_handling_fee_cents.sql <<'SQL'
-- 0007: store the handling fee in cents, like every other money column
BEGIN;

ALTER TABLE orders RENAME COLUMN handling_fee TO handling_fee_cents;
UPDATE orders SET handling_fee_cents = ROUND(handling_fee_cents * 100);

COMMIT;
SQL
