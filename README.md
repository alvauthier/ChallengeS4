# ChallengeS4

## Configuration des variables d'environnement

Avant de lancer les services, assurez-vous de configurer les variables d'environnement pour le backend :

1. Accédez au répertoire backend.
2. Copiez le fichier `.env.example` pour créer votre propre fichier `.env` :
   ```bash
   cp .env.example .env
   ```
3. Faire la même chose pour le frontend.
4. Se créer un compte Stripe, récupérer sa clé privée et la mettre dans le .env du backend, récupérer sa clé publique et la mettre dans le .env du frontend.

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

## Instructions pour lancer le frontend

1. Démarrer son émulateur.
2. Exécutez la commande `flutter pub get` puis `flutter run`.