# Publier des images sur le Docker Hub

Nous avons généré nos premières images.

Nous pouvons maintenant les publier vers le Docker Hub!

*Vous n'avez pas à faire les exercices de cette section,
parce qu'ils exigent un compte sur le Docker Hub, et nous
ne voulons forcer personne à en créer un.*

*Veuillez noter, toutefois, que la création d'un compte sur
le Docker Hub est gratuite (sans carte bancaire), et que
l'hébergement d'images publiques est aussi gratuit.*

---

## Connexion au Docker Hub

* C'est faisable depuis la ligne de commande Docker:
  ```bash
  docker login
  ```

.warning[Depuis Docker sur Mac/Windows, ou Docker sur un
poste de travail Linux, on peut (et on préfére si possible)
s'intégrer avec le trousseau de clés du système pour stocker
les accès en sécurité. Toutefois, sur la plupart des serveurs
Linux, ce sera stocké par défaut dans `~/.docker/config`.]

---

## _Tags_ d'image et adresses de registre

* Docker et ses _tags_ d'images sont comme Git et ses tags/branches.

* Ce sont des _pointeurs_ vers un ID d'image spécifique.

* Marquer une image ne *renomme pas* cette image: elle ne fait qu'ajouter une étiquette.

* En poussant une image vers un registre distant, l'adresse de registre est dans le _tag_.

  Example: `registry.example.net:5000/image`

* Qu'en est-il des images du Docker Hub?

--

* `jpetazzo/clock` est, en fait, `index.docker.io/jpetazzo/clock`

* `ubuntu` est, en fait, `library/ubuntu`, i.e. `index.docker.io/library/ubuntu`

---

## Etiqueter une image pour la pousser sur le _Hub_

* Ajoutons une étiquette à notre image `figlet` (ou une autre):
  ```bash
  docker tag figlet jpetazzo/figlet
  ```

* Et poussons-là sur le Hub:
  ```bash
  docker push jpetazzo/figlet
  ```

* C'est tout!

--

* N'importe qui peut maintenant `docker run jpetazzo/figlet` de partout.

---

## Les vertus des _builds_ automatisés

* Vous pouvez lier un dépôt du Docker Hub avec un dépôt Github ou BitBucket.

* Chaque _push_ dans Github/Bitbucket va déclencher un _build_ sur Docker Hub.

* Si l'image est générée avec succès, elle sera disponible sur Docker Hub.

* Vous pouvez associer _tags_ et branches entre le code source et images de conteneurs.

* Si vous maintenez des dépôts publics, tout ça est gratuit.

---

class: extra-details

## Installer un _build_ automatisé

* Vous avez besoin d'un code source "Dockerisé"!
* Direction https://github.com/jpetazzo/trainingwheels pour le _fork_.
* Allez sur Docker Hub (https://hub.docker.com/) et connectez-vous. Sélectionnez "Repositories" dans la barre de navigation bleue.
* Connectez votre compte Docker Hub à votre compte Github.
* Cliquez sur le bouton "Create".
* Puis allez dans l'onglet "Builds".
* Cliquez sur l'icône Github et choisissez le compte/dépôt que nous avons juste _fork_.
* Dans le bloc "Builds rules" en bas de page, indiquez `/www` dans la colonne "Build context" (ou le dossier qui contient le Dockerfile).
* Cliquez "Save and build" pour lancer un _build_ immédiatement (sans attendre le prochain _git push_).
* Les prochains _builds_ seront automatiques, grâce aux notifications Github.
