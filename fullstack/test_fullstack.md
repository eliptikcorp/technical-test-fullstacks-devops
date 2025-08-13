# Test Technique – Fullstack (Complexifié)

## 🎯 Objectif
Évaluer la capacité du candidat à concevoir et implémenter une application réelle où la **logique métier est non triviale**, les **données initiales sont imparfaites**, et où il faut **prendre des décisions d'architecture** (API, WebSocket, nettoyage des données).

---

## 🚩 Contexte
Tu dois développer un **système de gestion de tâches collaboratives** (TaskBoard) composé de :
- Backend (Laravel ou Django ou Spring Boot)
- Frontend (Angular ou React)
- Communication temps réel (WebSocket ou Server-Sent Events)

Fournis :
- Code source (backend + frontend)
- `docker-compose.yml` pour lancer l'ensemble
- `README.md` explicatif + diagramme simple (ERD ou sequence diagram)
- Suite de tests de base (unitaires/back-end + tests e2e léger)

---

## 🧩 Règles métiers (à implémenter)
1. **Tâches & Dépendances**
   - Une tâche peut dépendre de plusieurs autres tâches.
   - Une tâche ne peut être marquée `DONE` que si **toutes ses dépendances** sont `DONE`, **sauf** si un utilisateur avec le rôle `Manager` force la clôture.
2. **Priorité dynamique**
   - Priorité calculée : `base_priority + urgency_score`.
   - `base_priority` est fournie; `urgency_score` = points selon date d'échéance rapprochée, nombre de dépendances non résolues, et charge estimée.
3. **Assignation flexible**
   - Un utilisateur peut être assigné à plusieurs tâches.
   - Lorsqu'un utilisateur est supprimé, ses tâches restent but doivent être ré-attribuées automatiquement à son manager s'il existe, sinon rester en `UNASSIGNED`.
4. **Conflits et historique**
   - Toute modification de statut doit créer une entrée dans un journal d'événements (`events`), stockant `who`, `what`, `when`, `previous_value`.
5. **Permissions**
   - Les rôles possibles : `User`, `Lead`, `Manager`.
   - `Lead` peut modifier tâches des membres de son équipe.
   - `Manager` peut forcer clôture et réassignations.

---
## 🧪 Jeu de données initial (imparfait)
Les données initiales sont déjà intégrées dans les seeders Laravel existants. Ces données incluent :
- Entrées avec doublons (ex : 2 utilisateurs avec le même email).
- Tâches avec champs manquants (ex : `due_date: null`, `estimated_hours: "n/a"`).
- Références circulaires intentionnelles (ex : A dépend de B, B dépend de A).

Le candidat doit :
- Nettoyer les seeders existants pour garantir la conformité des données avec la base de données (déduplication, normalisation, correction des types).
- Décrire dans le README les décisions prises pour nettoyer les cas ambigus.

---

## 📡 Endpoints (partiels — compléter)
On fournit quelques endpoints de base; le candidat doit compléter les endpoints manquants et fournir une documentation claire.

Endpoints fournis (exemples) :
- `GET /tasks`
- `POST /tasks`
- `GET /users`
- `POST /auth/login`

**À ajouter/compléter** :
- `GET /tasks/:id/dependencies`
- `POST /tasks/:id/force-close` (Manager only)
- `GET /tasks?assigned_to=<user>&status=<status>&priority_gt=<n>`
- Endpoint pour journal d'événements `GET /events?task_id=...`

Le candidat doit fournir une documentation Postman ou OpenAPI (au choix) pour les endpoints critiques.

---

## 🔄 Temps réel
- Implémenter un canal temps réel (WebSocket ou SSE) qui notifie :
  - Changement de statut d'une tâche
  - Nouvelle assignation
  - Nouvel événement dans le journal

Le candidat est libre de choisir et configurer la solution technique pour la communication en temps réel.

---

## 🧰 Contraintes techniques
- Utiliser JWT pour l'authentification.
- Dockeriser l'app (backend + frontend + DB) via `docker-compose`.
- Fournir une configuration Docker complète pour lancer l'application.
- Commits réguliers et explicites : on évaluera la granularité et la qualité des messages.
- Fournir un diagramme simple (ERD ou sequence) dans `docs/diagram.png` ou `docs/diagram.svg`, créé par le candidat.

---

## 📋 Livrables attendus
- Repo avec `develop` branch contenant le travail.
- `README.md` : instructions d'installation, commandes, décisions d'implémentation, diagramme.
- `seed_data.json` + script d'import.
- Tests unitaires + quelques tests d'intégration.
- PR ouverte vers le repo principal (ou fork PR) avec description des étapes réalisées.

---

## ⏱ Temps recommandé
- 8 à 12 heures réalistes (tu peux répartir en étapes, mais montre commits progressifs).

---

## 📊 Barème & Critères d'évaluation
- **Logique métier** (respect des règles et robustesse) : 30%
- **Qualité backend (API, tests)** : 20%
- **Frontend (UX, réactivité, WebSocket)** : 20%
- **Docker / intégration** : 15%
- **Commits & Documentation (README, diagramme)** : 15%

**Points bonus** : proposition d'optimisations (caching, index DB), mise en place d'un petit job background (ex: recalcul périodique des priorités).

---

## 🚀 Soumission (Git/GitHub)
1. Fork le repo central `technical-test-fullstack-devops`.
2. Crée une branche `develop`.
3. Travaille avec des commits clairs et pousse sur ton fork.
4. Ouvre une Pull Request vers le repo central avec le titre `[Fullstack] Prénom Nom`.
5. Dans la PR, ajoute :
   - Lien vers la démo locale (comment lancer).
   - Capture d'écran ou courte vidéo (optionnel).
   - Explications des choix et limitations.

---

Bonne chance — on cherche surtout ta capacité à comprendre un domaine imprécis, à prendre des décisions et à produire une solution robuste et documentée.
