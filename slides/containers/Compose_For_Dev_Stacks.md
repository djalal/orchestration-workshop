# Compose pour les développeurs

Utiliser des Dockerfiles est super pour générer des images de conteneurs.

Et si nous voulions travailler avec une suite complexe composée de plusieurs conteneurs?

Au final, on voudra disposer de scripts spécifiques et automatisés pour construire,
lancer et connecter nos conteneurs entre eux.

Il y a une meilleure méthode: utiliser Docker Compose.

Dans ce chapitre, nous utiliserons Compose pour démarrer un environnement de développement.

---

## Qu'est-ce que Docker Compose?

Docker Compose (à l'origine appelé `fig`) est un outil externe.

Contrairement au Docker Engine, il est écrit en Python. C'est aussi un logiciel libre.

L'idée générale de Compose est de permettre un processus de démarrage très facile et puissant:

1. Récupérez votre code.

2. Lancez `docker-compose up`.

3. Votre appli est lancée et prête à l'emploi!

---

## Aperçu de Compose

Voici comment on travaille avec Compose:

* Vous décrivez un ensemble (ou _stack_) de conteneurs dans un fichier YAML appelé `docker-compose.yml`.

* Vous lancez `docker-compose up`.

* Compose télécharge automatiquement les images, génère les conteneurs et les démarre.

* Compose configure les liens, volumes et autres options de Docker pour vous.

* Compose peut lancer les conteneurs en arrière-plan, ou en avant-plan.

* Quand on lance nos conteneurs en avant-plan, leur sortie est agrégée à l'affichage.

Avant de s'y plonger, voyons un petit exemple de Compose en action.

---

class: pic

![composeup](images/composeup.gif)

---

## Vérifier si Compose est installé

Si vous utilisez les machines virtuelles de formation officielle, Compose a été pré-installé.

Si vous utilisez Docker pour Mac/Windows ou Docker Toolbox, Compose y est inclus.

Si vous êtes sur Linux (desktop ou serveur), vous devrez install Compose depuis la [page de release](https://github.com/docker/compose/releases) ou avec `pip install docker-compose`.

Vous pouvez vérifier votre installation en tapant:

```bash
$ docker-compose --version
```

---

## Lancer notre première _stack_ avec Compose

Première étape: cloner le code source de l'appli que nous allons manipuler.

```bash
$ cd
$ git clone https://github.com/jpetazzo/trainingwheels
...
$ cd trainingwheels
```

Seconde étape: démarrer votre appli.

```bash
$ docker-compose up
```

Observez Compose pendant qu'il génère et lance votre appli avec les paramètres
corrects, y compris la mise en réseau des conteneurs entre eux.

---

## Lancer notre première _stack_ avec Compose

Vérifiez que notre appli répond sur: `http://<yourHostIP>:8000`.

![composeapp](images/composeapp.png)

---

## Arrêter l'appli

Quand vous tapez `^C`, Compose tente d'arrêter en douceur tous les conteneurs.

Après 10 secondes (ou après plusieurs `^C`), ils seront tous stoppés de force.

---

## Le fichier `docker-compose.yml`

Voici le fichier utilisé dans la démo:

.small[
```yaml
version: "2"

services:
  www:
    build: www
    ports:
      - 8000:5000
    user: nobody
    environment:
      DEBUG: 1
    command: python counter.py
    volumes:
      - ./www:/src

  redis:
    image: redis
```
]

---

## Structure du fichier Compose

Un fichier Compose possède plusieurs sections:

* `version` est obligatoire. (On devrait utiliser `"2"` ou plus. La version 1 est obsolète.)

* `services` est obligatoire. Un service est une ou plusieurs copies de la même image sous forme de conteneurs.

* `networks` est optionnel et indique à quels réseaux devraient se connecter nos conteneurs.
  <br/>(Par défaut, les conteneurs seront liés à un réseau privé, unique par fichier compose.)

* `volumes` est optionnel et peut définir les volumes utilisés et/ou partagés par les conteneurs.

---

## Versions des fichiers Compose

* La version 1 est obsolète et ne devrait pas être utilisée.

  (Si vous voyez un fichier Compose sans `version` ni `services`, c'est une version 1.)

* La version 2 ajoute le support des réseaux et volumes.

* La version 3 ajoute le support des options de déploiements (montée en charge, mises à jour progressives, etc.).

La [documentation Docker](https://docs.docker.com/compose/compose-file/) a un excellent niveau d'information sur le format du fichier Compose, à propos de toutes les différentes versions.

---

## Conteneurs dans `docker-compose.yml`

Chaque service dans le fichier YAML doit mentionner soit `build`, ou `image`.

* `build` indique un chemin contenant un Dockerfile

* `image` indique un nom d'image (local, ou sur un registre).

* Si les deux sont spécifiés, une image sera générée depuis le dossier `build` et nommée selon `image`.

Les autres paramètres sont optionnels.

Ils encodent tous les paramètres typiques de la commande `docker run`.

Ils comportent parfois des améliorations mineures.

---

## Paramètres de conteneur

* `command` indique quoi lancer (comme la commande `CMD` du Dockerfile).

* `ports` se traduit par une (ou plusieurs) options `-p` de correspondance des ports.
  <br/>Vous pouvez spécifier des ports locaux (par ex. `x:y` pour exposer le port public `x`).

* `volumes` se traduit par une (ou plusieurs) options `-v`.
  <br/>Vous pouvez utiliser des chemins relatifs ici.

Pour la liste complète, voir: https://docs.docker.com/compose/compose-file/

---

## Commandes Compose

Nous avons déjà vu `docker-compose up`, mais en voici une autre, `docker-compose build`.

Cela va lancer `docker build` pour tous les conteneurs mentionnant un chemin `build`.

On peut aussi l'invoquer automatiquement en lançant l'application:

```bash
docker-compose up --build
```

Une autre option commune est de démarrer les conteneurs en arrière-plan:

```bash
docker-compose up -d
```

---

## Vérifier le statut des conteneurs

Cela peut se révéler fastidieux de vérifier le statut de vos conteneurs avec `docker ps`, surtout quand plusieurs applis tournent en même temps.

Compose nous facilite la tâche; avec `docker-compose ps`, il n'affichera
que le statut des conteneurs de la _stack_ en cours:

```bash
$ docker-compose ps
Name                      Command             State           Ports
----------------------------------------------------------------------------
trainingwheels_redis_1   /entrypoint.sh red   Up      6379/tcp
trainingwheels_www_1     python counter.py    Up      0.0.0.0:8000->5000/tcp
```

---

## Nettoyage (1)

Si vous avez démarré votre application en arrière-plan avec Compose, et que vous allez l'arrêter vite fait, vous pouvez passer par la commande `kill`:

```bash
$ docker-compose kill
```

De même, `docker-compose rm` vous permet de supprimer les conteneurs (après confirmation):

```bash
$ docker-compose rm
Going to remove trainingwheels_redis_1, trainingwheels_www_1
Are you sure? [yN] y
Removing trainingwheels_redis_1...
Removing trainingwheels_www_1...
```

---

## Nettoyage (2)

Par ailleurs, `docker-compose down` va arrêter et supprimer les conteneurs.

Cette commande va aussi supprimer d'autres ressources, comme les réseaux spécialement créés pour cette application.

```bash
$ docker-compose down
Stopping trainingwheels_www_1 ... done
Stopping trainingwheels_redis_1 ... done
Removing trainingwheels_www_1 ... done
Removing trainingwheels_redis_1 ... done
```

Enfin, `docker-compose -v` supprimer tout, y compris les volumes.

---

## Manipulation spéciale de volumes

Compose est malin. Si votre conteneur utilise des volumes, quand vous
re-démarrez votre appli, Compose va créer un nouveau conteneur, mais
fera attention à reprendre les volumes utilisés à l'origine.

Cela rend plus simple la mise à jour d'un service et ses données, où Compose va
télécharger les images et rédémarrer la _stack_.

---

## Nommer un projet avec Compose

* Quand vous lancez une commande Compose, Compose déduit un "nom de projet" pour votre appli.

* Par défaut, le "nom de projet" est le nom de votre dossier en cours.

* Par exemple, si vous êtes dans `/home/zelda/src/ocarina`, le nom du projet est `ocarina`.

* Toutes les ressources initiées par Compose sont marquées avec ce nom de projet.

* Le nom du projet apparaît comme préfixe des noms pour toutes les ressources.

  Par ex., dans l'exemple précédent, le service `www` va créer un conteneur `ocarina_www_1`.

* Le nom du projet peut être surchargé avec `docker-compose -p`.

---

## Lancer deux copies de la même appli

Si vous voulez exécuter deux exemplaires de la même appli simultanément, tout ce que vous avez à faire est de vous assurer que chaque exemplaire a un nom de projet différent.

Vous pouvez:

* soit copier votre code dans un nouveau dossier avec un nom différent

* soit démarrer chaque copie avec `docker-compose -p nomdeprojet up`

Chaque copie s'exécutera dans un réseau différent, totalement isolé des autres.

C'est idéal pour débogger des régressions, comparer entre 2 versions, etc.
