# DIVERGENCE.md

This file tracks every Sure upstream file that has been directly modified for the Kirkvik family finance instance.

**Purpose:** Keep a clear audit trail of customizations to upstream Sure files. When Sure releases an update, this log identifies which files need manual merge review.

**Scope:** Only files that _diverge_ from the Sure upstream belong here. New files added by this fork (e.g., config/deploy.yml, db/seeds/kirkvik_categories.rb, locale nb.yml files) are additive — they don't appear here unless they replace or modify an upstream file.

**Additive-only strategy:** All Kirkvik customizations should be in new files or new namespaces wherever possible. Direct modifications to upstream files are the exception, not the rule.

---

## Modified Files

| File | Change | Date | Reason |
|------|--------|------|--------|
| `compose.yml` | Created production compose.yml from `compose.example.yml` with Kirkvik-specific config: Redis pinned to `redis:7-alpine`, `maxmemory 256mb`, `appendonly yes`, `mem_limit 512m`; backup retention 30 days; `TZ=Europe/Oslo` on all services; `RAILS_FORCE_SSL=true`, `RAILS_ASSUME_SSL=true`, `APP_DOMAIN=frihetsformuen.no`; removed default `SECRET_KEY_BASE` to require explicit secret generation | 2026-03-13 | Production safety (Redis OOM prevention, SSL, Norwegian timezone, no committed secrets) |
| `.gitignore` | Unignored `compose.yml` (was gitignored upstream); added `.kamal/secrets` | 2026-03-13 | `compose.yml` is tracked in fork; `.kamal/secrets` must never be committed |
| `config/application.rb` | Added 3 lines after `config.i18n.fallbacks = true`: `config.i18n.default_locale = :nb`, `config.i18n.available_locales = [:nb, :en]`, `config.time_zone = "Europe/Oslo"` | 2026-03-13 | INFRA-04/INFRA-05: Norwegian as default locale, restrict to nb+en, Oslo timezone |

## New Files (Additive — Not Upstream Modifications)

These files are additions to the fork and do not conflict with upstream:

| File | Purpose |
|------|---------|
| `config/deploy.yml` | Kamal 2 deployment configuration targeting DigitalOcean + frihetsformuen.no |
| `.kamal/secrets.example` | Template for Kamal secret injection (real secrets go in `.kamal/secrets`, which is gitignored) |
| `.env.kirkvik.example` | Template for required environment variables |
| `db/seeds/kirkvik_categories.rb` | Idempotent seed for Kirkvik family budget category hierarchy |
| `lib/tasks/kirkvik_seed.rake` | Rake task wrapper for kirkvik_categories.rb seed |
| `config/locales/models/category/nb.yml` | Norwegian Bokmål translations for Category model strings |
| `config/locales/views/budgets/nb.yml` | Norwegian Bokmål translations for Budgets views |
| `config/locales/views/enable_banking_items/nb.yml` | Norwegian Bokmål translations for Enable Banking flow |
| `config/locales/views/components/nb.yml` | Norwegian Bokmål translations for shared UI components (provider sync summary) |
| `config/locales/views/recurring_transactions/nb.yml` | Norwegian Bokmål translations for Recurring Transactions views |
| `config/locales/views/reports/nb.yml` | Norwegian Bokmål translations for Reports views |
| `lib/tasks/kirkvik_setup.rake` | Rake task to configure Kirkvik family with Norwegian locale, NOK, Oslo timezone |
| `DIVERGENCE.md` | This file |

---

*Last updated: 2026-03-13*
*Phase: 01-foundation (Plans 01-04)*
