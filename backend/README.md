# ChallengeS4

## Configuration des variables d'environnement

Avant de lancer les services, assurez-vous de configurer les variables d'environnement pour le backend :

1. Accédez au répertoire backend.
2. Copiez le fichier `.env.example` pour créer votre propre fichier `.env` :
   ```bash
   cp .env.example .env
   ```

## Instructions pour lancer et créer la base de données

1. Accédez au répertoire backend.
2. Exécutez la commande `docker-compose up` pour lancer et créer la base de données.
3. Exécutez la commande `go mod tidy` pour télécharger les dépendances.
4. Accédez au répertoire backend/cmd/migrate.
5. Exécutez la commande `go run migrate.go` pour effectuer les migrations de la base de données.
6. Accédez au répertoire backend/cmd/fixtures.
7. Exécutez la commande `go run fixtures.go` pour insérer les données de test dans la base de données.

## Instructions pour lancer le serveur API

1. Accédez au répertoire backend/cmd/weezemaster.
2. Exécutez la commande `go run main.go` pour lancer le serveur API.

Pour consulter le Swagger, ouvrez votre navigateur et accédez à l'URL suivante : `localhost:8080/swagger/index.html`.