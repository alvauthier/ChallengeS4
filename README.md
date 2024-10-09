# ChallengeS4

# Informations importantes après soutenance
Nous avons oublié de le présenter, mais on a, une fois connecté, la possibilité de trier l’affichage des concerts sur la page d’accueil selon ses centres d’intérêts et selon la date d’ajout (récent ou ancien).


La création de concert fonctionne en local, mais pas en production car :
Dans register_concert_screeb.dart :

On a : Uri.parse('http://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/concerts'),

Or il faut : Uri.parse('${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/concerts'),

Dans register_organization_screen.dart :
On a : Uri.parse('http://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/registerorganizer'),

Or il faut : Uri.parse('${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/registerorganizer'),

Cela causait donc un souci au niveau de l'API de la prod car elle est en HTTPS.
Avec ceci ça marche en production.


L’affichage de ses centres d’intérêts et pouvoir choisir, ainsi que recevoir des notifications lors de la création de concerts correspondant à ses centres d’intérêts fonctionne en production si on se base sur le dernier commit d’hier soir, « fix firebase for web ».
Il ne fonctionne plus depuis un commit réalisé tout à l’heure à savoir « fix profile » qui a cassé cette fonctionnalité. C’est un souci de droit qui empêchait de récupérer les centres d’intérêts de l’utilisateur.

Nous sommes vraiment désolés pour ces soucis.
Melvin et Alexandre

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

# Contributions
Alexandre VAUTHIER (@alvauthier) :  
Back-end :  
- quasiment tous les controllers (category, concert, interest, notification, payment, reservation, ticket, ticketlisting, user)
- middleware
- JWT valide 1 min, connexion valable pour 1 mois
- models
- fixtures
- database
- docker
- Firebase FCM
- temps réel via websockets
- envoi de mails de mot de passe oublié
Frontend :  
- Page des centres d'intérêts de l'utilisateur
- Page de ses tickets
- Revente des tickets
- Achat des tickets
- Page de remerciement pour un achat
- Page des tickets dispo en revente
- Stripe
- Notifications
- Quelques améliorations sur la page d'un concert
- Relier les pages du frontend avec les données issues de l'API
- chat en temps réel via websockets
- mot de passe oublié
- tri possible des concerts sur la page d'accueil selon centres d'intérêts et date d'ajout (récent ou ancien)

Melvin COURANT (@melvincourant) :
Back-end :
- controller message
- controller conversation
- changement de certains controllers pour le preload d'informations
Frontend :
- design global
- page d'accueil
- page d'un concert
- page des tickets de l'utilisateur
- chat
- première version de la barre de navigation
- page d'achat d'un ticket
- nouvelle navigation (go router)
- nouvelle navbar adaptative selon le rôle
- page de ses messages
- panel admin