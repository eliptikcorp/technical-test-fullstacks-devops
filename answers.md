# Réponses aux Questions DevOps

## 1. Comment gérez-vous les secrets en production (vault vs GitHub Secrets vs env files) ? Expliquer la stratégie choisie.

### Stratégie recommandée : Approche hybride avec HashiCorp Vault

**Pour la production :**
- **HashiCorp Vault** comme référentiel central des secrets
- **GitHub Secrets** pour les credentials de CI/CD (clés API Vault, tokens de déploiement)
- **Jamais d'env files** en production avec des secrets en clair

**Implémentation :**
```bash
# CI/CD récupère les secrets depuis Vault
vault kv get -field=db_password secret/myapp/prod/database

# Injection dans les containers via init containers ou sidecar patterns
# Secrets montés en volumes temporaires (tmpfs)
```

**Rotation automatique :**
- Secrets DB rotatés automatiquement (30 jours)
- API keys avec expiration courte (7 jours)
- Certificats TLS via cert-manager + Let's Encrypt

**Pourquoi cette approche :**
- Centralisation et auditabilité des accès
- Rotation automatique
- Principe de moindre privilège
- Chiffrement au repos et en transit

> Note (projet local/CI) :
> - Les fichiers `.env` ne sont pas commités, et un `.env.example` documente les variables nécessaires (voir devops/starter/api/.env.example). Les patterns `.env*` sont ignorés dans `.gitignore`.
> - Pour la CI, utiliser GitHub Secrets (ex: `REGISTRY_TOKEN`, `VAULT_TOKEN`, etc.) et ne jamais exposer de secrets dans les logs.
> - Optionnel pour dépôt privé: chiffrer des fichiers sensibles avec SOPS + age/PGP et déchiffrer en CI (clés en GitHub Secrets).

## 2. Décrire une procédure de rollback en cas de déploiement défectueux.

### Procédure de Rollback Automatisée

**1. Détection automatique des problèmes :**
```yaml
# Healthchecks post-déploiement
- HTTP 200 sur /health dans les 60s
- Latency p95 < 500ms pendant 5 minutes
- Error rate < 1% pendant 10 minutes
```

**2. Rollback automatique :**
```bash
# Script de rollback (atomic symlink switch)
./scripts/rollback.sh

# Actions :
# 1. Identifier la release précédente stable
# 2. Switch atomique du symlink deploy/current
# 3. Restart des services avec la release précédente
# 4. Validation des healthchecks
# 5. Nettoyage de la release défectueuse
```

**3. Rollback manuel d'urgence :**
```bash
# Rollback immédiat en cas de panne critique
kubectl rollout undo deployment/api --to-revision=2
# ou
docker service update --rollback api
```

**4. Post-rollback :**
- Investigation des logs et métriques
- Post-mortem avec équipe
- Fix et nouveau déploiement après validation

> Note (projet) : le rollback est automatisé via <scripts/rollback.sh> et un "atomic switch" de symlink `deploy/current` vers la release précédente. Le manifeste `deploy/releases/<ts>/manifest.json` trace la version (tag/sha/date/runner).

## 3. Comment monitoreriez-vous une augmentation soudaine du 500 Errors ?

### Monitoring et Alerting des Erreurs 5xx

**1. Métriques clés à surveiller :**
```promql
# Taux d'erreur 5xx
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100

# Volume d'erreurs
sum(rate(http_requests_total{status=~"5.."}[5m]))

# Latency corrélée
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**2. Alertes Prometheus :**
```yaml
groups:
- name: api.rules
  rules:
  - alert: High5xxRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100 > 5
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Taux d'erreur 5xx élevé: {{ $value }}%"
      
  - alert: High5xxVolume
    expr: sum(rate(http_requests_total{status=~"5.."}[5m])) > 10
    for: 1m
    labels:
      severity: warning
```

**3. Dashboard Grafana - Vue d'urgence :**
- Graphique en temps réel du taux d'erreur
- Top 10 des endpoints en erreur
- Corrélation avec CPU/Memory/DB connections
- Logs d'erreur centralisés (ELK/Loki)

**4. Procédure d'intervention :**
1. **Détection** : Alert Slack/PagerDuty en <2min
2. **Investigation** : Logs applicatifs + infrastructure
3. **Mitigation** : Rollback si nécessaire
4. **Communication** : Status page + équipes
5. **Résolution** : Fix + déploiement + validation

> Note (projet) : les règles Prometheus incluent APIDown, taux d’erreur 5xx et latence p95. Le dashboard Grafana fournit santé, 200 rate, CPU/Mem, uptime et p95 pour investiguer rapidement.

## 4. Comment automatiser les migrations DB dans un pipeline sûr ?

### Pipeline de Migration DB Sécurisé

**1. Stratégie Blue-Green pour les migrations :**
```yaml
# Pipeline GitLab CI/CD
migration-check:
  script:
    # Validation des migrations en local
    - docker-compose -f test/docker-compose.yml up -d db
    - npm run migrate:test
    - npm run migrate:rollback:test  # Test rollback
    
migration-staging:
  script:
    # Backup pré-migration
    - pg_dump $STAGING_DB > backup_$(date +%Y%m%d_%H%M%S).sql
    # Migration avec timeout
    - timeout 300 npm run migrate:staging
    # Validation post-migration
    - npm run test:integration:staging
    
migration-prod:
  when: manual  # Validation humaine requise
  script:
    # Maintenance mode ON
    - kubectl scale deployment api --replicas=0
    # Backup complet
    - pg_dump $PROD_DB > prod_backup_$(date +%Y%m%d_%H%M%S).sql
    # Migration
    - npm run migrate:prod
    # Validation
    - npm run test:smoke:prod
    # Maintenance mode OFF
    - kubectl scale deployment api --replicas=3
```

**Exemple GitHub Actions (adapté au repo) :**
```yaml
name: DB migrations (example)
on:
  workflow_dispatch:
jobs:
  db-migrate:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports: [ '5432:5432' ]
        options: >-
          --health-cmd "pg_isready -U postgres" \
          --health-interval 10s --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install deps
        working-directory: devops/starter/api
        run: npm ci
      - name: Run migrations (staging)
        env:
          DATABASE_URL: ${{ secrets.STAGING_DB_URL }}
        run: |
          echo "npm run migrate:staging (exemple)" 
      - name: Validate and smoke tests
        run: echo "npm run test:smoke:staging (exemple)"
      - name: Rollback on failure
        if: failure()
        env:
          DATABASE_URL: ${{ secrets.STAGING_DB_URL }}
        run: |
          echo "psql restore backup (exemple)" 
          exit 1
```

> Notes :
> - Utiliser des migrations backward‑compatibles, et un backup/restauration testés.

**2. Migrations compatibles backwards :**
```sql
-- ✅ Sûr : Ajout de colonne optionnelle
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- ❌ Dangereux : Suppression de colonne (faire en 2 étapes)
-- Étape 1 : Déployer code qui n'utilise plus la colonne
-- Étape 2 : Supprimer la colonne après validation
```

**3. Rollback automatique :**
```bash
# En cas d'échec de migration
if [ $MIGRATION_FAILED ]; then
  echo "Migration failed, restoring backup"
  psql $DB_URL < latest_backup.sql
  kubectl rollout undo deployment/api
fi
```

## 5. Décrire une procédure pour gérer une panne critique où la base de données devient inaccessible.

### Procédure de Gestion de Panne DB Critique

**1. Diagnostic (0-5 minutes) :**
```bash
# Vérifications automatiques
- kubectl get pods -l app=postgres
- docker logs db-container --tail=100
- ping DB_HOST
- telnet DB_HOST 5432

# Métriques Grafana à vérifier :
- DB connections pool utilization
- Disk space usage (>90% = problème)
- Memory usage PostgreSQL
- Query execution time
```

**2. Escalade et Communication (5-10 minutes) :**
```bash
# Alertes automatiques déjà envoyées via :
- PagerDuty → Équipe OnCall
- Slack #incidents
- Status page (automatique via webhook)

# Activation du mode incident majeur
- War room Slack/Teams
- Communication client si >15min downtime
```

**3. Mitigation Immédiate (10-30 minutes) :**

**Scénario A - DB surchargée :**
```bash
# Réduire la charge
kubectl scale deployment api --replicas=1
# Killer les requêtes longues
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - interval '5 minutes';
```

**Scénario B - Corruption/Crash :**
```bash
# Tentative de restart
kubectl rollout restart statefulset/postgres
# Si échec → Restore depuis backup
```

**Scénario C - Problème infrastructure :**
```bash
# Basculement vers instance standby (si HA)
kubectl patch service postgres -p '{"spec":{"selector":{"role":"standby"}}}'
```

**4. Résolution (30-60 minutes) :**
```bash
# Restore depuis backup si nécessaire
pg_restore -d $DB_NAME latest_backup.dump
# Validation de l'intégrité
REINDEX DATABASE myapp;
VACUUM ANALYZE;
# Test complet de l'application
npm run test:integration:prod
```

**5. Prévention future :**

**Monitoring renforcé :**
```yaml
# Alertes préventives
- alert: DBDiskSpaceHigh
  expr: (1 - node_filesystem_avail_bytes{mountpoint="/var/lib/postgresql"} / node_filesystem_size_bytes) * 100 > 80
  
- alert: DBSlowQueries
  expr: pg_stat_statements_mean_time_ms > 1000
```

**Architecture résiliente :**
- **Haute disponibilité** : PostgreSQL avec réplication master-slave
- **Backups automatiques** : Point-in-time recovery (PITR) + backups quotidiens
- **Monitoring proactif** : Métriques custom + log analysis
- **Circuit breaker** : Dégradation gracieuse si DB indisponible
- **Cache Redis** : Réduction de la charge DB
- **Connection pooling** : PgBouncer pour optimiser les connexions

**Documentation de crise :**
- Runbook détaillé avec commandes exactes
- Contacts d'escalade (DBA, Ops, Management)
- SLA de récupération : RTO=30min, RPO=15min
- Tests de disaster recovery mensuels

## Annexe — Références & Lancements rapides

- Observabilité & Alerting (Exo 4): voir docs/exo4-observabilite.md pour le pas-à-pas (démarrage stack, accès Grafana/Prometheus, dashboard, alertes, playbook).