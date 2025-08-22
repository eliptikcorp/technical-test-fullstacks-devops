# Exercice 4 — Observabilité & Alerting

Cette documentation décrit comment lancer l’observabilité et retrouver le dashboard Grafana présenté (API Overview).

## Démarrage de la stack observabilité

- Lancer l’ensemble (API, Nginx, DB, Prometheus, Grafana):
  ```bash
  docker compose -f devops/starter/docker-compose.yml up -d
  ```

## Accès services
- Nginx (proxy vers API): http://localhost:8080 (endpoints: `/health`, `/ping`)
- Prometheus: http://localhost:9090 (scrape `/metrics` sur `api:3000`)
- Grafana: http://localhost:3001 (login: `admin` / `admin`)

## Dashboard Grafana
- Provisionné automatiquement depuis `devops/starter/grafana/provisioning/...`
- Titre: API Overview
- Panneaux inclus:
  - API Health (UP/DOWN)
  - HTTP 200 rate
  - CPU Usage (%)
  - Memory Usage (MiB)
  - Uptime (heures)
  - CPU & Memory Over Time
  - Request duration (p95)

## Règles d’alerting Prometheus
- Chargées via `devops/starter/prometheus/rules.yml`
- Principales alertes:
  - APIDown: `up{job="api"} == 0` pendant 1m
  - APIHighErrorRate: `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05` pendant 5m
  - APILatencyP95High: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 0.5` pendant 10m

## Générer du trafic (pour alimenter les métriques)
- PowerShell (Windows):
  ```powershell
  for ($i=0; $i -lt 100; $i++) { Invoke-WebRequest -UseBasicParsing http://localhost:8080/ping | Out-Null; Start-Sleep -Milliseconds 200 }
  ```
- Bash:
  ```bash
  for i in {1..100}; do curl -s http://localhost:8080/ping >/dev/null; sleep 0.2; done
  ```

## Vérification rapide
- Grafana > Dashboards > API Overview:
  - "API Health" doit être UP
  - Les graphes CPU/Mem et la p95 s’animent après génération de trafic
- Prometheus:
  - Target `api` UP
  - Règles d’alerting présentes

## Playbook de réaction (succinct)
- APIDown → vérifier logs/containers, si régression post-déploiement: `./scripts/rollback.sh`
- 5xx élevé → corréler logs/métriques, rollback si nécessaire, ouvrir incident
- Latence p95 élevée → vérifier saturation (CPU/Mem/DB), scaler et/ou rollback

## Prérequis rapides
- Docker et Docker Compose opérationnels.
- Ports libres: 8080 (Nginx), 3000 (API), 3001 (Grafana), 9090 (Prometheus).

## Arrêt & Nettoyage
```bash
docker compose -f devops/starter/docker-compose.yml down -v
```
- down -v supprime aussi les volumes (base Postgres). Enlevez -v pour garder les données.

## PromQL de contrôle (rapide)
Dans Grafana (Explore) ou direct Prometheus:
```promql
# Disponibilité de l'API
up{job="api"}

# Taux de 200 par seconde
rate(http_requests_total{status="200"}[$__rate_interval])

# Durée p95 des requêtes
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[$__rate_interval])) by (le))
```

## Forcer des signaux pour tester
- Générer du trafic (déjà ci-dessus): boucles curl/bash ou PowerShell.
- Simuler une panne API (alerte APIDown):
  ```bash
  docker compose -f devops/starter/docker-compose.yml stop api
  # Attendre > 1 minute (règle APIDown) puis:
  docker compose -f devops/starter/docker-compose.yml start api
  ```
- Générer des 404 (erreurs côté client) pour voir les métriques HTTP:
  ```bash
  for i in {1..50}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/does-not-exist; done
  ```

## Dépannage
- Ports déjà utilisés → changez les mappings de ports dans devops/starter/docker-compose.yml ou arrêtez les services en conflit.
- Grafana vide → attendez ~15s après le démarrage; vérifiez que le datasource Prometheus est "green" dans Connections > Data sources.
- Prometheus ne scrape pas l'API → vérifiez que le container api est healthy et que /metrics répond (http://localhost:3000/metrics depuis l’hôte si port mappé).
- WSL2/Windows → si les URLs localhost ne répondent pas, vérifiez Docker Desktop/WSL2 et les proxies d’entreprise.