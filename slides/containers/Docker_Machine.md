# Gérer les hôtes avec Docker Machine

- Docker Machine est un outil pour provisionner et gérer des serveurs Docker.

- Il automatise la création d'une machine virtuelle:

 - en local, avec un outil tel que VirtualBox ou VMWare

 - sur un _cloud_ public tel que AWS EC2, Azure, Digital Ocean, GCP, etc.

 - sur un _cloud_ privé comme OpenStack.

- Il peut aussi configurer des machines existantes à travers une connection SSH.

- Enfin, il sait gérer autant de serveurs que vous voulez, avec autant de "pilotes" que vous voulez.

---

## Processus Docker Machine

1) Préparer l'environnement: configurer VirtualBox, récupérer les accès au _cloud_

2) Créer des hôtes avec `docker-machine create -d nom-pilote nom-machine`

3) Utiliser une machine spécifique avec `eval $(docker-machine env nom-machine)`

4) Profiter!

---

## Variables d'environnement

- La plupart des outils (CLI, bibliothèques, etc.) passant par l'API Docker peuvent accéder aux variables d'environnement.

- Ces variables sont:

 - `DOCKER_HOST` (indique une adresse+port de connexion, ou la socket UNIX)

 - `DOCKER_TLS_VERIFY` (active l'authentification mutuelle TLS)

 - `DOCKER_CERT_PATH` (chemin vers la paire de clés et certificat à utiliser lors de l'authentification)

- `docker-machine env ...` va générer les variables nécessaires pour se connecter à un certain hôte.

- `$(eval docker-machine env ...)` initialise ces variables dans le terminal en cours.

---

## Fonctions de gestion des hôtes

Avec `docker-machine`, on peut:

- mettre à jour un hôte à la dernière version de Docker Engine,

- démarrer/arrêter/redémarrer des hôtes,

- récupérer un _shell_ sur une machine distante (avec SSH),

- copier des ficheirs vers/depuis des machines distantes (avec SCP),

- monter un dossier distant du hôte sur le poste local (via SSHFS)

- etc.

---

## Le pilote `generic`

Lors de la mise en service d'un nouvel hôte, `docker-machine` exécute les étapes suivantes:

1) Créer l'hôte dans le _cloud_ ou via l'API de l'hyperviseur.

2) Se connecter à l'hôte via SSH.

3) Installer et configurer Docker sur l'hôte.

Avec le pilote `generic`, on fournit l'adresse IP d'un hôte exitant (au lieu des accès _cloud_), et on saute la première étape.

Cela permet de référencer des machines physiques, ou des VMs fournies par une tierce partie, ou un cloud sans API de mise en service.
