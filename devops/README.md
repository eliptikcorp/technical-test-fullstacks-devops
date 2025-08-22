# DevOps — Démarrage local rapide

Ce README te donne les commandes minimales pour lancer l’environnement DevOps en local (API + Nginx + Postgres + Prometheus + Grafana), exécuter les tests, et simuler un déploiement/rollback.

## Prérequis
- Docker Desktop (ou Docker Engine) et Docker Compose v2 (commande `docker compose`).
- Ports libres: 8080 (Nginx), 3000 (API), 3001 (Grafana), 9090 (Prometheus).

## Lancer la stack (API + DB + Nginx + Prometheus + Grafana)
Exécuter depuis la racine du dépôt:
```bash
docker compose -f devops/starter/docker-compose.yml up -d
```

Accès rapides:
- Nginx (reverse proxy): http://localhost:8080
  - Endpoints utiles: `/health`, `/ping`
- API directe: http://localhost:3000 (ex: `/metrics`)
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (login: `admin` / `admin`)

Arrêt & nettoyage:
```bash
docker compose -f devops/starter/docker-compose.yml down -v
# Enlevez -v si vous souhaitez conserver les données Postgres
```

## Tests & Lint de l’API
Depuis `devops/starter/api`:
```bash
npm install
npm test         # Jest
npm run lint     # ESLint
```

## Générer un peu de trafic (pour les métriques)
- Bash:
```bash
for i in {1..100}; do curl -s http://localhost:8080/ping >/dev/null; sleep 0.2; done
```
- PowerShell (Windows):
```powershell
for ($i=0; $i -lt 100; $i++) { Invoke-WebRequest -UseBasicParsing http://localhost:8080/ping | Out-Null; Start-Sleep -Milliseconds 200 }
```

## Build/Run de l’image API seule (optionnel)
Depuis la racine du dépôt:
```bash
docker build -f devops/starter/api/Dockerfile -t starter-api:local .
docker run --rm -p 3000:3000 -e NODE_ENV=production starter-api:local
```

## Simulation de déploiement & rollback (Exercice 3 — Option A)
Depuis la racine du dépôt:
```bash
bash scripts/deploy_local.sh      # crée deploy/releases/<timestamp> + manifest.json et bascule le symlink deploy/current
bash scripts/rollback.sh          # re-pointe deploy/current vers la release précédente
```
Artefacts:
- `deploy/releases/<timestamp>/` contient la release (docker-compose spécifique, conf Nginx, manifest.json avec tag/sha/date/runner).
- `deploy/current` est un lien symbolique atomique vers la release active.

## Observabilité & Alerting (Exercice 4)
La stack Grafana/Prometheus est incluse dans `devops/starter/docker-compose.yml`. Pour les requêtes PromQL, la vérification des alertes et des conseils de dépannage, voir:
- `docs/exo4-observabilite.md`

### Règles d’alerte (résumé)
- APIDown (critique): `up{job="api"} == 0` pendant 1m → la cible API ne répond plus.
- 5xx élevé (warning): `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05` pendant 5m → taux d’erreur > 5%.
- Latence p95 élevée (warning): `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 0.5` pendant 10m → p95 > 500ms.

## CI — Scan de vulnérabilités (Exercice 2)
Un job Trivy (non-bloquant) existe dans le workflow: `.github/workflows/ci.yml`.
- Détails, exécution locale et bonnes pratiques: `docs/ci-vuln-scan.md`.

## ☁️ Environnements Éphémères

### GitHub Codespaces
1. **Ouvrir dans Codespaces :**
   - Depuis GitHub : "Code" → "Codespaces" → "Create codespace on develop"
   - URL directe : https://github.com/codespaces/new?hide_repo_select=true&ref=develop

2. **Démarrer automatiquement :**
   ```bash
   docker compose -f devops/starter/docker-compose.yml up -d
   ```

3. **Accès aux services :**
   - Ports forwardés automatiquement par Codespaces
   - API : https://<id>-8080.app.github.dev
   - Grafana : https://<id>-3001.app.github.dev

### Gitpod
1. **URL d'accès :**
   ```
   https://gitpod.io/#https://github.com/W4Ro/technical-test-fullstacks-devops/tree/develop
   ```

2. **Configuration automatique :** 
   - Services lancés via `.gitpod.yml`
   - Ports exposés automatiquement

### Railway / Render (Déploiement Cloud)
1. **Variables d'environnement :** Utiliser `.env.example` comme référence
2. **Build :** `docker build -f devops/starter/api/Dockerfile devops/starter/api`
3. **Port :** 3000 (API Node.js)

## 📊 URLs de Test
- **Health check :** `curl https://<url>/health`
- **Métriques :** `curl https://<url>/metrics`
- **Ping :** `curl https://<url>/ping`