# Technical Test Fullstacks DevOps

Ce dépôt contient le code et la documentation pour le test technique Fullstack & DevOps.

## Prérequis

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Node.js](https://nodejs.org/) (si applicable)
- [npm](https://www.npmjs.com/) ou [yarn](https://yarnpkg.com/) (si applicable)

## Installation

1. Clonez le dépôt :
    ```bash
    git clone https://github.com/eliptikcorp/technical-test-fullstacks-devops.git
    cd technical-test-fullstacks-devops
    ```

2. Accédez à la section correspondant à votre profil :
    - **DevOps** : `cd devops/starter/api`
    - **Fullstack** : `cd fullstack/starter/backend`

3. Installez les dépendances :
    ```bash
    npm install
    # ou
    yarn install
    ```

4. Configurez les variables d'environnement si nécessaire (voir `.env.example`).

## Lancement du projet

### Avec Docker

```bash
docker-compose up --build
```

### En local

```bash
npm start
# ou
yarn start
```

## Structure du projet

### DevOps
- `devops/starter/api/` : Mini application Node.js pour le test DevOps.
- `devops/starter/docker-compose.yml` : Configuration Docker multi-conteneurs.
- `devops/starter/nginx/` : Configuration Nginx pour le reverse proxy.
- `devops/test_devops.md` : Instructions pour le test DevOps.

### Fullstack
- `fullstack/starter/backend/` : Backend Laravel pour le test Fullstack.
- `fullstack/starter/frontend/` : Frontend Dockerisé pour le test Fullstack.
- `fullstack/test_fullstack.md` : Instructions pour le test Fullstack.

## Tests

### DevOps
```bash
npm test
# ou
yarn test
```

### Fullstack
```bash
php artisan test
```

## Déploiement

Des instructions de déploiement peuvent être ajoutées selon l'environnement cible (cloud, serveur dédié, etc.).

## Auteur

- [Djamal GANI](https://github.com/yowedjamal)

## Licence

Ce projet est sous licence MIT.
