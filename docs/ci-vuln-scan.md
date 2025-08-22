# CI — Scan de vulnérabilités (Exercice 2)

Objectif (extrait): « Scanne les vulnérabilités (ou exécute trivy/act basic check) — si impossible, documenter l'approche ».

## Mise en œuvre dans ce repo
- Le workflow GitHub Actions contient un job de scan vulnérabilités avec Trivy (scan du repo et de l'image Docker).
- Le scan est non-bloquant (continue-on-error: true) pour ne pas échouer la CI en cas de findings, tout en rendant les résultats visibles dans les logs.
- Référence du workflow: <mcfile name="ci.yml" path="c:\Users\waris\technical-test-fullstacks-devops\.github\workflows\ci.yml"></mcfile>

Ce que fait le job vuln-scan:
- Trivy FS: analyse le système de fichiers du repo (dépendances, IaC, etc.).
- Trivy Image: analyse l'image Docker construite par le job de build.

## Rappel workflow & job utilisés
- Fichier: .github/workflows/ci.yml
- Job: vuln-scan ("Vulnerability scan (Trivy FS - non-bloquant)")
  - Étape 1: Trivy FS (repo) — flags: --severity HIGH,CRITICAL --ignore-unfixed --no-progress
  - Étape 2: Build image éphémère starter-api:${GITHUB_SHA}
  - Étape 3: Trivy Image (même flags)
- Comportement: non-bloquant via continue-on-error: true (les PR ne cassent pas, mais les résultats sont visibles dans les logs).

## Exécution locale rapide (Linux/macOS)
1) Avec Trivy installé
```bash
# Scanner le repo
trivy fs --severity HIGH,CRITICAL --ignore-unfixed --no-progress .

# Construire puis scanner l'image
docker build -f devops/starter/api/Dockerfile -t starter-api:local .
trivy image --severity HIGH,CRITICAL --ignore-unfixed --no-progress starter-api:local
```

2) Sans installer Trivy (via Docker)
```bash
# Scanner le repo
docker run --rm -v "$PWD":/repo -w /repo aquasec/trivy:latest fs --severity HIGH,CRITICAL --ignore-unfixed --no-progress /repo

# Scanner l'image
docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --no-progress starter-api:local
```

3) Via act (simuler GitHub Actions)
```bash
# Lancer uniquement le job de scan sur un événement PR
act pull_request -j vuln-scan
```

## Exécution locale rapide (Windows PowerShell)
```powershell
# Scanner le repo (Docker)
docker run --rm -v ${PWD}:/repo -w /repo aquasec/trivy:latest fs --severity HIGH,CRITICAL --ignore-unfixed --no-progress /repo

# Construire puis scanner l'image
docker build -f devops/starter/api/Dockerfile -t starter-api:local .
docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --no-progress starter-api:local
```

## Version de l'image Trivy
- Le workflow utilise aquasec/trivy:latest pour rester à jour des définitions.
- Si vous préférez stabiliser les résultats, remplacez par un tag versionné (ex: aquasec/trivy:0.54.1) dans vos commandes/CI.

## Politique de blocage (rappel)
- Actuellement: non-bloquant (continue-on-error: true).
- Pour bloquer sur failles HIGH/CRITICAL:
  - Rendez les étapes bloquantes (supprimez continue-on-error) et/ou
  - Ajoutez --exit-code 1 aux commandes Trivy.

## Dépannage
- Cannot connect to the Docker daemon → vérifiez que Docker Desktop/daemon tourne et que votre utilisateur a les droits.
- image not found lors du scan d'image → construisez l'image locale avant le scan (voir commandes ci-dessus).
- Rate limiting sur les bases Trivy → relancez plus tard; le cache local (~/.cache) accélère les scans suivants.

## Bonnes pratiques
- Pinner la version Trivy en CI pour des résultats reproductibles si nécessaire.
- Scanner à la fois le système de fichiers (IaC, deps) et l'image Docker.
- Réviser les findings critiques et planifier les corrections; ne pas laisser le non-bloquant éternellement.

## Sorties attendues
- Les rapports Trivy apparaissent dans les logs du job GitHub Actions.
- Aucun artefact n'est uploadé par défaut (possible d'ajouter un export JSON/SARIF si souhaité).

## Limitations & conseils
- De rares faux positifs peuvent apparaître; re-vérifier avant de bloquer le pipeline.
- Le cache Trivy (~/.cache) accélère les scans ultérieurs; le job CI monte ce cache quand c'est pertinent.
- Mettre à jour régulièrement la version de Trivy utilisée (tag de l'image Docker ou binaire) pour bénéficier des dernières définitions.