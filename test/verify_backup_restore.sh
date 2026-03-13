#!/usr/bin/env bash
set -euo pipefail

# Kirkvik Backup Restore Verification Script
# Run on the DigitalOcean droplet after backup service has produced at least one backup.
# Usage: bash test/verify_backup_restore.sh

echo "=== Kirkvik Backup Restore Verification ==="
echo ""

# 1. Check backup exists
BACKUP_DIR="/opt/sure/backups"
LATEST=$(find "$BACKUP_DIR" -name "*.sql.gz" -type f | sort | tail -1)

if [ -z "$LATEST" ]; then
  echo "FAIL: No backup files found in $BACKUP_DIR"
  exit 1
fi

echo "Latest backup: $LATEST"
echo "Size: $(du -h "$LATEST" | cut -f1)"
echo ""

# 2. Create test database
echo "Creating test database for restore verification..."
docker compose exec -T db createdb -U "${POSTGRES_USER:-sure_user}" sure_restore_test 2>/dev/null || true

# 3. Restore backup to test database
echo "Restoring backup to test database..."
gunzip < "$LATEST" | docker compose exec -T db psql -U "${POSTGRES_USER:-sure_user}" -d sure_restore_test -q

# 4. Compare row counts
echo ""
echo "Comparing row counts..."

PROD_FAMILIES=$(docker compose exec -T db psql -U "${POSTGRES_USER:-sure_user}" -d "${POSTGRES_DB:-sure_production}" -t -c "SELECT count(*) FROM families;" | tr -d ' ')
TEST_FAMILIES=$(docker compose exec -T db psql -U "${POSTGRES_USER:-sure_user}" -d sure_restore_test -t -c "SELECT count(*) FROM families;" | tr -d ' ')

echo "  families: production=$PROD_FAMILIES restored=$TEST_FAMILIES"

if [ "$PROD_FAMILIES" = "$TEST_FAMILIES" ]; then
  echo "  PASS: Row counts match"
else
  echo "  FAIL: Row counts do not match"
fi

PROD_CATEGORIES=$(docker compose exec -T db psql -U "${POSTGRES_USER:-sure_user}" -d "${POSTGRES_DB:-sure_production}" -t -c "SELECT count(*) FROM categories;" | tr -d ' ')
TEST_CATEGORIES=$(docker compose exec -T db psql -U "${POSTGRES_USER:-sure_user}" -d sure_restore_test -t -c "SELECT count(*) FROM categories;" | tr -d ' ')

echo "  categories: production=$PROD_CATEGORIES restored=$TEST_CATEGORIES"

if [ "$PROD_CATEGORIES" = "$TEST_CATEGORIES" ]; then
  echo "  PASS: Row counts match"
else
  echo "  FAIL: Row counts do not match"
fi

# 5. Clean up
echo ""
echo "Cleaning up test database..."
docker compose exec -T db dropdb -U "${POSTGRES_USER:-sure_user}" sure_restore_test

echo ""
echo "=== Backup restore verification complete ==="
