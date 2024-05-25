# ChallengeS4

## Instructions pour lancer et créer la base de données

1. Accédez au répertoire backend.
2. Exécutez la commande `docker-compose up` pour lancer et créer la base de données.
3. Accédez au répertoire backend/cmd/migrate.
4. Exécutez la commande `go run migrate.go` pour effectuer les migrations de la base de données.
5. Accédez au répertoire backend/cmd/fixtures.
6. Exécutez la commande `go run fixtures.go` pour insérer les données de test dans la base de données.

## Instructions pour lancer le serveur API

1. Accédez au répertoire backend/cmd/weezemaster.
2. Exécutez la commande `go run main.go` pour lancer le serveur API.

Pour consulter le Swagger, ouvrez votre navigateur et accédez à l'URL suivante : `localhost:8080/swagger/index.html`.