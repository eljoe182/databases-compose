# databases-compose

A local development stack of databases and related UIs, orchestrated with Docker Compose.

## What’s included

The repository root `docker-compose.yaml` defines:

- **SQL Server 2017** (`sqlserver2017`) — host port **2866** → container `1433`
- **SQL Server 2022** (`sqlserver2022`) — host port **2433** → container `1433`
- **MySQL 8** (`mysql-db`) — host port **6612** → container `3306`
- **MongoDB 7** (`mongodb`) — host port **27017**
- **Redis 7.2** (`redis-cache`) — host port **6379**
- **RedisInsight** (`redis_insight`) — host port **5540**
- **Elasticsearch 8.12** (`elasticsearch`) — host port **3200** → container `9200` (HTTP), and **9300**
- **Kibana 8.12** (`kibana`) — host port **5601**

All services share a single Docker bridge network named `databases`.

## Prerequisites

- Docker Desktop (or Docker Engine) with Docker Compose v2 (`docker compose`)

## Quick start

1. Create your `.env` file:

```bash
cp env.sample .env
```

2. Fill required variables in `.env` (see [Environment variables](#environment-variables)).

3. Start the whole stack:

```bash
docker compose up -d
```

4. Check running containers:

```bash
docker compose ps
```

To stop everything:

```bash
docker compose down
```

## Environment variables

Variables used by `docker-compose.yaml` (see `env.sample`):

- **SQL Server**
  - `MSSQL_PASSWORD`: password for the `sa` user (must satisfy SQL Server password rules)
- **MySQL**
  - `DB_DATABASE`
  - `DB_USERNAME`
  - `DB_PASSWORD`
- **Redis**
  - `REDIS_PASSWORD`
- **Elasticsearch / Kibana**
  - `ELASTICSEARCH_USER` (typically `elastic`, used by your scripts/tools)
  - `ELASTICSEARCH_PASSWORD` (password for the `elastic` user)
  - `ELASTICSEARCH_KIBANA_TOKEN` (service account token used by Kibana)
- **MongoDB**
  - `MONGO_ROOT_PASSWORD`
  - Optional: `MONGO_ROOT_USERNAME` (default `root`)
  - Optional: `MONGO_DATABASE` (default `test`)

## Service URLs (from your host)

- **RedisInsight**: `http://localhost:5540`
- **Kibana**: `http://localhost:5601`
- **Elasticsearch**: `http://localhost:3200`
  - Note: this compose disables HTTP TLS for local dev (`xpack.security.http.ssl.enabled=false`).

## Data persistence (local folders)

Compose mounts local directories so data survives restarts:

- `./mongodb/data` → MongoDB data directory
- `./redis` → Redis data directory (includes `dump.rdb`)
- `./redis_insight` → RedisInsight data
- `./elasticsearch` → Elasticsearch data directory
- `./mssql/backups` → SQL Server backup directory inside containers

These folders are intentionally ignored via per-service `.gitignore` files.

## Elasticsearch + Kibana setup

Kibana connects to Elasticsearch using a **service account token** (not the `elastic` user).

Follow the step-by-step guide:

- `docs/elasticsearch/README.md`

## SQL Server backups / restore

### Copy a `.bak` into the SQL Server 2017 container

This repo includes `copy_database.sh`:

```bash
./copy_database.sh /absolute/path/to/DEMO.bak
```

It copies the backup to `/var/opt/mssql/backup` inside `sqlserver2017`.

### Restore example

See `mssql/backups/mssql-restore-database.sql` for a sample `RESTORE DATABASE` script that restores from:

- `/var/opt/mssql/backup/DEMO.bak`

## Notes / known gaps

- The `mysql` service mounts `./mysql` and `./config/mysql/my.cnf`, but those paths are **not present** in this repository. If you want to use MySQL, create them (example):

```bash
mkdir -p mysql config/mysql
printf '%s\n' '[mysqld]' 'sql_mode=STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' > config/mysql/my.cnf
```

Or update `docker-compose.yaml` to match your preferred MySQL layout.

## Security

- Never commit real secrets. The root `.gitignore` ignores `.env`.
- This stack is intended for **local development** (not for exposure on the public internet).

