# Elasticsearch and Kibana (local Docker)

This stack uses **Elasticsearch 8.12** and **Kibana 8.12** from the repository root `docker-compose.yaml`. Kibana connects to Elasticsearch with a **service account token** (not the `elastic` superuser). The `elastic` user password is for **HTTP API access**, CLI tools, and logging into the Kibana UI when applicable.

## Prerequisites

- Elasticsearch and Kibana containers running (`docker compose up -d elasticsearch kibana` from the repo root).
- Compose sets `xpack.security.http.ssl.enabled=false` for local development so the REST API on port **9200** uses **HTTP** inside the Docker network. **Do not use this pattern on the public internet.**

## 1. Set or reset the `elastic` user password

Use this password for:

- REST calls (e.g. `curl -u elastic:<password> http://localhost:3200`), mapped from container `9200` → host `3200`.
- Optional: logging into the Kibana web UI as `elastic` in development.

### Option A — Reset password (works on an existing cluster)

Run inside the running Elasticsearch container:

```bash
docker exec -it elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic --batch
```

The command prints the new password once. Copy it and store it securely.

### Option B — Interactive reset (you type the password)

```bash
docker exec -it elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i
```

### First-time cluster only — `ELASTIC_PASSWORD` (optional)

On the **very first** start of an empty data directory, you can set the bootstrap password via environment variable on the `elasticsearch` service (see Elastic’s Docker documentation). After the node has formed a cluster, changing this variable alone does **not** rotate the stored password; use **Option A** or **B** instead.

## 2. Create Kibana credentials (service account token)

Kibana 8 **must** use a **service account token** to connect to Elasticsearch. Using `ELASTICSEARCH_USERNAME=elastic` in Kibana is **blocked** by Kibana’s configuration validation.

Create a token (pick any token name; here `docker-compose`):

```bash
docker exec elasticsearch /usr/share/elasticsearch/bin/elasticsearch-service-tokens create elastic/kibana docker-compose
```

Example output:

```text
SERVICE_TOKEN elastic/kibana/docker-compose = AAEAAWVsYXN0aWMva2liYW5hL2RvY2tlci1jb21wb3NlO...
```

Copy the full value after the `=` (the string starting with `AAEAA...`).

### List or delete tokens (optional)

```bash
# List tokens for the elastic/kibana service account
docker exec elasticsearch /usr/share/elasticsearch/bin/elasticsearch-service-tokens list elastic/kibana

# Delete a named token
docker exec elasticsearch /usr/share/elasticsearch/bin/elasticsearch-service-tokens delete elastic/kibana/docker-compose
```

After deleting the token referenced in `.env`, create a new token and update `ELASTICSEARCH_KIBANA_TOKEN` before restarting Kibana.

## 3. Update `.env` in the repository root

Set or refresh these variables (used by `docker compose` from the repo root):

| Variable | Purpose |
|----------|---------|
| `ELASTICSEARCH_USER` | Usually `elastic` (for your own scripts / documentation). |
| `ELASTICSEARCH_PASSWORD` | Password for the `elastic` user (from section 1). |
| `ELASTICSEARCH_KIBANA_TOKEN` | Full service token string from section 2 (no quotes in `.env`). |

Then restart Kibana so it picks up the new token:

```bash
docker compose up -d kibana
```

## 4. Verify

- **Elasticsearch** (from the host, HTTP on mapped port `3200`):

  ```bash
  curl -s -u "elastic:${ELASTICSEARCH_PASSWORD}" http://localhost:3200 | head
  ```

  Load variables from `.env` in your shell if needed, or paste the password when prompted.

- **Kibana UI**: open `http://localhost:5601`. If the UI asks for credentials, use the `elastic` user and the password from section 1 (typical for local setups).

- **Kibana logs** (should not repeat `Unable to retrieve version information` or `security_exception` for the service account):

  ```bash
  docker logs kibana 2>&1 | tail -30
  ```

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| `socket hang up` talking to Elasticsearch | Protocol mismatch (HTTP vs HTTPS). This compose uses **HTTP** on `9200` for local dev; keep `ELASTICSEARCH_HOSTS=http://elasticsearch:9200` in Compose unless you re-enable HTTP TLS on Elasticsearch. |
| `failed to authenticate service account [elastic/kibana]` | Token expired, deleted, or wrong cluster. Create a new token (section 2) and update `ELASTICSEARCH_KIBANA_TOKEN`. |
| `value of "elastic" is forbidden` in Kibana | Kibana cannot use the `elastic` user for its Elasticsearch connection; use a service account token as documented above. |

## Security note

Never commit real passwords or tokens to git. Keep secrets in `.env` (ignored by version control) or a secret manager.
