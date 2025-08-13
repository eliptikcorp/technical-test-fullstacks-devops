# Test Technique – DevOps (Sans serveur réel)

## 🎯 Objectif
Évaluer la capacité du candidat à automatiser build, tests, packaging, déploiement simulé et monitoring sans accès à des serveurs persistants. L'accent est mis sur la qualité des pipelines, la sécurité des secrets, l'observabilité et la capacité à produire une documentation reproductible.

---

## 🚩 Contexte
Tu dois prendre un projet "starter" (fourni) et construire une **chaîne CI/CD** automatisée, des artefacts dockerisés, une stratégie de déploiement simulé et une couche d'observabilité. Tout doit être exécutable dans un environnement local ou sur des environnements éphémères (GitHub Actions, Gitpod, Codespaces, Railway etc.).

---

## 🧩 Exercice 1 — Dockerisation complète
- Dockeriser l'application (multi-stage si nécessaire).
- Fournir `docker-compose.yml` qui lance :
  - app (API)
  - DB (Postgres ou MySQL)
- Optionnel : Ajouter un reverse proxy (nginx) ou un outil de monitoring léger (Prometheus + Grafana container, ou Netdata).
- S'assurer que :
  - Les volumes persistants sont configurés.
  - Les `.env` ne sont pas commit.
  - Un fichier `env.example` documente les variables nécessaires.

**Critères :**
- Images légères et multi-stage.
- Bonne séparation des responsabilités.
- Persistance fonctionnelle.

---

## 🔁 Exercice 2 — CI (GitHub Actions)
- Créer un workflow `ci.yml` qui :
  - Lint le code
  - Lance les tests unitaires
  - Build les images Docker
  - Exécute le script `scripts/deploy_local.sh` pour simuler un déploiement local
  - Scanne les vulnérabilités (ou exécute `trivy`/`act` basic check`) — si impossible, documenter l'approche
- Le workflow doit être déclenchable sur PR.

**Critères :**
- Étapes claires, jobs parallélisables.
- Gestion sécurisée des secrets (documentation et usage via GitHub Secrets).

---

## 🚀 Exercice 3 — CD (simulé)
Étant donné l'absence de serveurs, implémente une stratégie de **déploiement simulé** :

### Option A — Déploiement local "simulateur"
- Script `scripts/deploy_local.sh` qui :
  - Build les images
  - Lance `docker-compose -f deploy/docker-compose.yml up -d`
  - Copie les artefacts dans un répertoire `deploy/releases/<timestamp>/`
  - Met à jour un fichier `deploy/current -> deploy/releases/<timestamp>`
  - Génère un manifeste `deploy/releases/<timestamp>/manifest.json` contenant metadata (tag, sha, date, job-runner)
- Fournir un script `scripts/rollback.sh` qui rétablit `deploy/current` vers la release précédente.

### Option B — Environnements éphémères
- Démontrer déploiement sur un service gratuit/éducatif (GitHub Codespaces / Gitpod / Railway free tier).
- Fournir instructions pour reproduire le déploiement.

**Critères :**
- Automatisation reproducible.
- Manifesting & atomic switch (symlink) pour simuler gradual cutover.
- Rollback simple et testé.

---

## 📈 Exercice 4 — Observabilité & Alerting
- Fournir un docker-compose ou instructions GitHub Actions qui démarre :
  - Metrics exposition (Prometheus scrape target)
  - Documentation pour configurer un dashboard Grafana minimal (CPU, Memory, uptime, endpoint health).
- Optionnel : Logging centralisé (vector, fluentd, filebeat → loki).
- Décrire dans `README.md` les règles d'alerte critiques (ex: `error rate > X`, `latency > Yms`, `DB connections > Z`).

**Critères :**
- Dashboard minimal fonctionnel ou instructions claires pour l'utiliser.
- Playbook de réaction succinct (rollback, scaling, notification).

---

## ❓ Exercice 5 — Questions & cas pratiques (answers.md)
Répondre dans `answers.md` (format markdown) aux questions :
1. Comment gérez-vous les secrets en production (vault vs GitHub Secrets vs env files) ? Expliquer la stratégie choisie.
2. Décrire une procédure de rollback en cas de déploiement défectueux.
3. Comment monitoreriez-vous une augmentation soudaine du 500 Errors ?
4. Comment automatiser les migrations DB dans un pipeline sûr ?
5. Décrire une procédure pour gérer une panne critique où la base de données devient inaccessible. Inclure les étapes de diagnostic, résolution, et prévention future.

---

## 📋 Livrables attendus
- `docker-compose.yml` + `deploy/` scripts.
- `.github/workflows/ci.yml` (et `cd.yml` si pertinent).
- `README.md` avec instructions pour exécuter localement et en environnement éphémère.
- `answers.md` réponses aux questions.
- PR vers le repo central / fork PR.

---

## ⏱ Temps recommandé
- 10 à 12 heures réalistes selon expertise.

---

## 📊 Barème & Critères d'évaluation
- Dockerisation & persistance : 25%.
- CI (qualité des workflows) : 30%.
- Simulated CD (manifests, symlink, rollback) : 20%.
- Observabilité & alerting : 15%.
- Documentation & réponses (answers.md) : 10%.

---

## 🚀 Soumission (Git/GitHub)
1. Fork le repo central.
2. Crée une branche `develop`.
3. Commits réguliers et pousse sur ton fork.
4. Ouvre une Pull Request vers le repo central avec le titre `[DevOps] Prénom Nom`.
5. Dans la PR, préciser si un environnement éphémère a été utilisé (Codespaces/Gitpod/Railway) et fournir les URLs.

---

### ✅ Évaluation Git/GitHub (transversal)
Dans les deux tests, tu seras noté aussi sur :
- Qualité et granularité des commits.
- Usage de branches (feature branches, PR).
- Clarté du README et du PR description.
- Capacité à répondre aux commentaires de code review (si interaction réelle proposée).
