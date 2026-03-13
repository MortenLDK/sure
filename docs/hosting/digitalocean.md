# Deploying Kirkvik Finance on DigitalOcean with Kamal 2

This runbook covers the complete deployment of the Kirkvik Finance instance (Sure fork) on DigitalOcean using Kamal 2. It is the playbook that Plan 04 follows step by step.

**App:** frihetsformuen.no (family finance tracker, private instance)
**Stack:** Rails 7.2 / PostgreSQL 16 / Redis 7 / Sidekiq / Kamal 2 + kamal-proxy
**Registry:** GHCR (GitHub Container Registry)

---

## Section 1: Prerequisites

Before starting, ensure you have:

- DigitalOcean account with billing enabled
- Domain `frihetsformuen.no` with DNS access (Namecheap, Cloudflare, or DO DNS)
- SSH key added to DigitalOcean account (Settings → Security → SSH Keys)
- Kamal installed locally: `gem install kamal`
- Docker installed locally — Kamal builds images on your local machine
- GitHub account with a fork of the Sure repo
- GitHub PAT with `write:packages` scope (for GHCR push):
  - Create at: https://github.com/settings/tokens
  - Select: `write:packages` scope (allows push to ghcr.io)

---

## Section 2: Create Droplet

**Recommended spec:**
- Size: 4GB RAM / 2 vCPU / 80GB SSD (Regular, ~$24/month)
- Image: Ubuntu 24.04 LTS
- Region: FRA1 (Frankfurt) or AMS3 (Amsterdam) — lowest latency to Norway
- Options: Enable **Droplet Backups** (~$4.80/month — weekly full-disk snapshots as safety net)
- SSH keys: Select your registered SSH key

**Via DigitalOcean web console** or via `doctl` CLI:

```bash
# Install doctl if not already installed
brew install doctl  # macOS
doctl auth init     # authenticate

# Create droplet (adjust region as needed)
doctl compute droplet create sure-kirkvik \
  --size s-2vcpu-4gb \
  --image ubuntu-24-04-x64 \
  --region fra1 \
  --ssh-keys YOUR_SSH_KEY_FINGERPRINT \
  --wait

# Get droplet IP
doctl compute droplet list --format Name,PublicIPv4
```

Note the public IPv4 address — you need it for DNS and `config/deploy.yml`.

---

## Section 3: Server Preparation

Kamal handles Docker installation automatically via `kamal setup`. However, the firewall and fail2ban must be configured manually first:

```bash
ssh root@DROPLET_IP

# System updates
apt update && apt upgrade -y
apt install -y ufw fail2ban

# Configure firewall — SSH, HTTP, HTTPS only
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

# Enable fail2ban for SSH brute force protection
systemctl enable fail2ban
systemctl start fail2ban

# Verify firewall is active
ufw status verbose
```

**Note:** Do NOT install Docker manually. Kamal installs and configures Docker on the server during `kamal setup`. Manual Docker installation can conflict with Kamal's setup.

---

## Section 4: DNS Setup

Point your domain to the droplet before deploying — kamal-proxy handles Let's Encrypt SSL, which requires DNS to be resolving at deploy time.

```bash
# Add these records in your DNS provider:
# A record:     frihetsformuen.no       → DROPLET_IP
# A record:     www.frihetsformuen.no   → DROPLET_IP
# (or CNAME www → @)

# Verify DNS propagation (wait 2-15 minutes after creating records)
dig frihetsformuen.no A
dig www.frihetsformuen.no A

# Both should return your DROPLET_IP
```

**Do not proceed to deploy until DNS resolves correctly.** kamal-proxy will attempt to obtain an SSL certificate during deployment and will fail if DNS is not ready.

---

## Section 5: Configure Kamal Secrets

All secrets are stored locally in `.kamal/secrets` (gitignored) and injected by Kamal at deploy time.

```bash
# From the local project directory (C:/Users/Morten Lund Kirkvik/sure)
cp .kamal/secrets.example .kamal/secrets

# Edit .kamal/secrets with real values:
#   KAMAL_REGISTRY_PASSWORD=ghp_your_github_pat_with_write_packages_scope
#   SECRET_KEY_BASE=$(openssl rand -hex 64)
#   POSTGRES_USER=sure_user
#   POSTGRES_PASSWORD=$(openssl rand -base64 32)
#   POSTGRES_DB=sure_production
```

**Security rules:**
- `.kamal/secrets` is gitignored — never commit real secrets
- `SECRET_KEY_BASE` must be 64+ hex chars — generate fresh with `openssl rand -hex 64`
- `POSTGRES_PASSWORD` must be random — generate with `openssl rand -base64 32`

---

## Section 6: Update deploy.yml with Droplet IP and GitHub Username

```bash
# Edit config/deploy.yml — replace placeholders with real values:
#   DROPLET_IP_HERE  → actual droplet IP (appears 3 times: servers.web, accessories.db, accessories.redis)
#   GITHUB_USERNAME  → your GitHub username (fork owner — appears 2 times: image, registry)

# Verify replacements
grep -n "DROPLET_IP_HERE\|GITHUB_USERNAME" config/deploy.yml
# Should return no output (all placeholders replaced)
```

---

## Section 7: Deploy with Kamal

### First-time setup

`kamal setup` installs Docker, starts all accessories (PostgreSQL, Redis, backup), deploys the app, and configures kamal-proxy with SSL.

```bash
# Build image and push to GHCR, then deploy everything:
kamal setup
```

This single command:
1. SSH into the droplet
2. Installs Docker
3. Pulls and starts PostgreSQL and Redis accessories
4. Builds the app image locally
5. Pushes to GHCR
6. Pulls and starts the app container
7. Configures kamal-proxy with SSL via Let's Encrypt
8. Runs database migrations

### Subsequent deploys

```bash
kamal deploy
```

### Start the backup service

The backup container runs via Docker Compose `--profile backup` on the droplet. Kamal does not manage this profile — start it manually after first deploy:

```bash
# SSH into droplet and start backup service
ssh root@DROPLET_IP "cd /opt/sure && docker compose --profile backup up -d"

# Verify backup service is running
ssh root@DROPLET_IP "docker ps | grep backup"
```

The backup service uses `prodrigestivill/postgres-backup-local` with:
- `SCHEDULE=@daily` — runs at midnight
- `BACKUP_KEEP_DAYS=30` — 30 days of daily backups
- `BACKUP_KEEP_WEEKS=4` — 4 weekly backups
- `BACKUP_KEEP_MONTHS=6` — 6 monthly backups
- Volume: `/opt/sure/backups` on the droplet

---

## Section 8: Post-Deploy Configuration

After the app is deployed and accessible at https://frihetsformuen.no:

```bash
# Step 1: Register the Kirkvik family account
# Visit https://frihetsformuen.no in browser and create account
# Use: morten@[your email]
# This creates the Family record that the seed tasks require

# Step 2: Run locale/app configuration (from Plan 02)
kamal app exec --interactive 'rails kirkvik:setup'

# Step 3: Seed the 8 Kirkvik budget categories (from Plan 03)
kamal app exec --interactive 'rails kirkvik:seed'
```

Expected output from `rails kirkvik:seed`:
```
Kirkvik categories seeded:
  8 parent categories
  31 subcategories
  39 total

  wifi Abonnement & Tech (#6366f1)
    - Abonnement
  home Bolig & Lån (#b45309)
    - Avdrag
    - Barnehage
    ...
Done. Categories ready.
```

---

## Section 9: Verify PostgreSQL Volume Path

**Critical check** — must pass before any real financial data is entered. The Docker volume must be mounted at the standard PostgreSQL data directory path.

```bash
# Check that PostgreSQL data volume is populated
kamal accessory exec db 'ls /var/lib/postgresql/data | grep PG_VERSION'
# Expected output: PG_VERSION
# If output is empty, the volume is mounted incorrectly
```

**If empty:** The data will be written to a temporary container layer and lost on container restart. Stop and fix the volume configuration in `config/deploy.yml` before entering any data.

---

## Section 10: Backup Verification (INFRA-02)

**This section must be executed by Plan 04 to satisfy INFRA-02.**

### Two-layer backup architecture

| Layer | Mechanism | Retention | Granularity |
|-------|-----------|-----------|-------------|
| App-level | `prodrigestivill/postgres-backup-local` container | 30 days daily / 4 weeks / 6 months | Per-database SQL dump |
| Infrastructure | DigitalOcean Droplet Backups | 4 weekly snapshots | Full disk image |

### Verify backup container is creating files

```bash
# Wait 24 hours after first deploy, then check:
ssh root@DROPLET_IP "ls -la /opt/sure/backups/"

# Expected: directory with .sql.gz files
# If empty after 24h: check backup container logs
ssh root@DROPLET_IP "docker logs \$(docker ps -q --filter name=backup)"
```

### Backup restore test procedure

Run this on the droplet to verify restore works before any real data enters. This is the verification step for INFRA-02.

```bash
# SSH into droplet
ssh root@DROPLET_IP
cd /opt/sure

# 1. Verify backups exist
ls -la /opt/sure/backups/

# 2. Create a test database for restore verification
docker compose exec db createdb -U sure_user sure_restore_test

# 3. Restore latest backup to test database
# (adjust filename to match actual latest backup)
LATEST=$(ls -t /opt/sure/backups/*.sql.gz 2>/dev/null | head -1)
echo "Restoring from: $LATEST"
gunzip < "$LATEST" | docker compose exec -T db psql -U sure_user -d sure_restore_test

# 4. Verify row counts match between production and restore
echo "=== Production families count ==="
docker compose exec db psql -U sure_user -d sure_production \
  -c "SELECT count(*) FROM families;"

echo "=== Restored families count ==="
docker compose exec db psql -U sure_user -d sure_restore_test \
  -c "SELECT count(*) FROM families;"

# Counts must match — if they don't, the backup is corrupt

# 5. Clean up test database
docker compose exec db dropdb -U sure_user sure_restore_test
echo "Restore verification complete."
```

Alternatively, use the verification script:
```bash
bash test/scripts/verify_backup_restore.sh
```

**INFRA-02 is satisfied when:** backup files exist on the droplet, restore produces the same row counts as production, and the test database is cleaned up.

---

## Section 11: Redis Verification

```bash
# Verify Redis maxmemory setting (should be 256MB = 268435456 bytes)
kamal accessory exec redis 'redis-cli CONFIG GET maxmemory'
# Expected: "maxmemory" followed by "268435456"

# Verify persistence is enabled (appendonly yes)
kamal accessory exec redis 'redis-cli CONFIG GET appendonly'
# Expected: "appendonly" followed by "yes"

# Verify Redis is healthy
kamal accessory exec redis 'redis-cli PING'
# Expected: PONG
```

---

## Section 12: Updating Kirkvik Finance (Sure fork)

To apply upstream Sure updates or local changes:

```bash
# Pull upstream Sure changes (if tracking upstream remote)
git fetch upstream
git merge upstream/main

# Resolve any conflicts in Kirkvik-specific files, then:
kamal deploy
```

Kamal handles zero-downtime deployment — new container starts, health check passes, then old container stops.

---

## Section 13: Troubleshooting

### SSL certificate not provisioned

```bash
# Check kamal-proxy logs
ssh root@DROPLET_IP "docker logs kamal-proxy 2>&1 | grep -i cert"

# Common cause: DNS not yet propagated when kamal setup ran
# Fix: wait for DNS, then re-run
kamal proxy stop
kamal proxy start
# Or trigger SSL refresh:
kamal proxy reboot
```

### Redis OOM (Out of Memory)

```bash
# Check Redis memory usage
kamal accessory exec redis 'redis-cli INFO memory | grep used_memory_human'

# If approaching 256MB, check for runaway cache keys
kamal accessory exec redis 'redis-cli DBSIZE'

# The allkeys-lru policy should handle eviction automatically
# If OOM kills are happening, check container memory limit (512m in deploy.yml)
```

### PostgreSQL volume path wrong

```bash
# Symptom: database data lost after container restart
# Diagnosis:
kamal accessory exec db 'ls /var/lib/postgresql/data'
# If empty: volume not mounted at correct path

# The volume must be: sure-kirkvik-db-data:/var/lib/postgresql/data
# Check config/deploy.yml accessories.db.volumes
```

### Locale not applying (Norwegian not showing)

```bash
# Check family record has locale set
kamal app exec --interactive 'rails runner "puts Family.first.locale"'
# Expected: "nb"

# If blank, run setup again:
kamal app exec --interactive 'rails kirkvik:setup'
```

### Kamal proxy port conflict

```bash
# Check what's on port 80/443
ssh root@DROPLET_IP "ss -tlnp | grep -E ':80|:443'"

# If another service is occupying the port:
ssh root@DROPLET_IP "systemctl stop nginx apache2 2>/dev/null; systemctl disable nginx apache2 2>/dev/null"

# Then restart kamal-proxy
kamal proxy restart
```

### Build fails locally

```bash
# Kamal builds Docker images locally — ensure Docker is running
docker info

# If Dockerfile is not found:
ls Dockerfile  # must exist in project root

# Check GHCR auth
docker login ghcr.io -u GITHUB_USERNAME -p YOUR_PAT
```

### Sidekiq not processing jobs

```bash
# Check Sidekiq process inside the web container
kamal app exec 'bundle exec sidekiq --version'

# View Sidekiq logs
kamal app logs --grep sidekiq

# Verify Redis connection from app container
kamal app exec 'rails runner "puts Sidekiq.redis { |c| c.ping }"'
# Expected: PONG
```

---

## Quick Reference — Kamal Commands

| Action | Command |
|--------|---------|
| First deploy (full setup) | `kamal setup` |
| Deploy new version | `kamal deploy` |
| View app logs | `kamal app logs -f` |
| Run Rails console | `kamal app exec --interactive 'rails console'` |
| Run rake task | `kamal app exec --interactive 'rails TASK_NAME'` |
| Restart app | `kamal app restart` |
| Check app status | `kamal app details` |
| Exec into db | `kamal accessory exec db 'psql -U sure_user -d sure_production'` |
| Exec into redis | `kamal accessory exec redis 'redis-cli'` |
| View proxy status | `kamal proxy details` |
| SSH into server | `kamal server exec "bash"` or `ssh root@DROPLET_IP` |
