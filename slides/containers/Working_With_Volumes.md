
class: title

# Travailler avec des volumes

![volume](images/title-working-with-volumes.jpg)

---

## Objectifs

A la fin de cette section, vous serez capable de:

* Créer des conteneurs gérant des volumes.

* Partager des volumes à travers des conteneurs.

* Partager un dossier du serveur avec un ou plusieurs conteneurs.

---

## Travailler avec des volumes

Les volumes Docker sont utilisés pour accomplir bien des buts, y compris:

* Contourner le système _copy-on-write_ pour obtenir une performance d'I/O native.

* Contourner le _copy-on-write_ pour laisser quelques fichiers hors de `docker commit`.

* Partager un dossier entre plusieurs conteneurs.

* Partager un dossier entre le serveur et le conteneur.

* Partager _un seul fichier_ entre l'hôte et le conteneur.

* Utiliser un stockage distant et un stockage spécifique avec les "pilotes de volumes".

---

## "Volumes", des dossiers spéciaux d'un conteneur

On peut déclarer des volumes de deux façons différentes.

* Dans un `Dockerfile`, avec une instruction `VOLUME`.

```dockerfile
VOLUME /uploads
```

* En ligne de commande, avec l'option `-v` avec `docker run`.

```bash
$ docker run -d -v /uploads myapp
```

Dans les deux cas, `/uploads` (à l'intérieur du conteneur) sera un volume.

---

class: extra-details

## Les volumes pour contourner le système _copy-on-write_

Les volumes agissent comme des passerelles vers le système de fichier de l'hôte.

* La performance d'un volume en termes d'I/O disque est exactement la même
  que sur l'hôte Docker.

* Quand on fait un `docker commit`, le contenu des volumes n'est pas intégré
  dans l'image résultante.

* Si une instruction `RUN` dans un `Dockerfile` change le contenu d'un volume,
  ces changements ne seront pas non plus enregistrés.

* Si un conteneur est démarré avec l'option `--read-only`, le volume sera
  toujours modifiable (à moins que le volume lui-même soit en lecture-seule).

---

class: extra-details

## Les volumes peuvent être partagés entre conteneurs

Vous pouvez démarrer un conteneur avec *exactement les mêmes volumes* qu'un autre.

Le nouveau conteneur aura les mêmes volumes, dans les mêmes dossiers.

Ils contiendront exactement la même chose, et resteront synchronisés.

Sous le capot, ce sont en fait les mêmes dossiers sur le serveur.

C'est possible avec l'option `--volumes-from` dans `docker run`.

Nous allons en voir un exemple dans les diapos suivantes.

---

class: extra-details

## Partager les logs d'un serveur d'application avec un autre conteneur

Démarrons un conteneur Tomcat:

```bash
$ docker run --name webapp -d -p 8080:8080 -v /usr/local/tomcat/logs tomcat
```

Maintenant, démarrons un conteneur `alpine` avec les mêmes volumes:

```bash
$ docker run --volumes-from webapp alpine sh -c "tail -f /usr/local/tomcat/logs/*"
```

Puis, d'une autre fenêtre, envoyons des requêtes à notre conteneur Tomcat:

```bash
$ curl localhost:8080
```

---

## Les volumes existent indépendemment des conteneurs

Si un conteneur est arrêté ou supprimé, ses volumes existent toujours et sont accessibles.

On peut lister et manipuler les volumes avec les sous-commandes de `docker volume`:

```bash
$ docker volume ls
DRIVER              VOLUME NAME
local               5b0b65e4316da67c2d471086640e6005ca2264f3...
local               pgdata-prod
local               pgdata-dev
local               13b59c9936d78d109d094693446e174e5480d973...
```

Certains des noms de volumes sont explicites (pgdata-prod, pgdata-dev).

D'autres (les IDs hexa) sont générés automatiquement par Docker.

---

## Nommer les volumes

* On peut créer des volumes sans conteneur, et les utiliser ensuite dans plusieurs conteneurs.

Ajoutons quelques volumes directement.

```bash
$ docker volume create webapps
webapps
```

```bash
$ docker volume create logs
logs
```

Nos volumes ne sont attachés à aucun dossier en particulier.

---

## Utiliser nos volumes nommés

* On active les volumes avec l'option `-v`.

* Quand le chemin côté hôte ne contient pas de /, il est traité comme un nom de volume.

Démarrons un serveur web avec les deux précédents volumes.

```bash
$ docker run -d -p 1234:8080 \
         -v logs:/usr/local/tomcat/logs \
         -v webapps:/usr/local/tomcat/webapps \
         tomcat
```

Vérifions que cela s'exécute normalement:

```bash
$ curl localhost:1234
... (Tomcat nous raconte combien il est content de tourner) ...
```

---

## Utiliser un volume d'un autre conteneur

* Nous allons modifier le contenu d'un volume depuis un autre conteneur.

* Dans cet exemple, nous allons lancer un éditeur de texte dans un autre conteneur.

  (Mais ça pourrait être un serveur FTP, un serveur WebDAV, un dépôt Git...)

Démarrons un autre conteneur attaché au volume `webapps`.

```bash
$ docker run -v webapps:/webapps -w /webapps -ti alpine vi ROOT/index.jsp
```

Il nous reste à vandaliser la page, enregistrer, et sortir.

Exécutons encore un `curl localhost:1234` pour voir nos changements.

---

## Usage des "bind-mounts" personnalisés

Dans certains cas, vous voudrez monter un dossier depuis l'hôte vers le conteneur:

* Pour gérer le stockage et les snapshots vous-même;

  (Avec LVM, ou un SAN, ou ZFS, ou toute autre chose!)

* ou vous avez un autre disque aux meilleures performances (SSD) ou à résilience supérieure (EBS)
et vous voulez y placer d'importantes données.

* ou vous voulez partager un dossier source entre votre hôte (où se trouve le source)
et le conteneur (où se passe la compilation et l'exécution).

Un moment, on a déjà vu ce cas d'usage dans notre exemple de processus de développement!
Pas mal.

```bash
$ docker run -d -v /chemin/depuis/notre/hote:/chemin/dans/le/conteneur image ...
```

---

class: extra-details

## Migrer des données avec `--volumes-from`

L'option `--volumes-from` indique à Docker de reprendre tous les volumes
d'un conteneur existant.

* Scenario: migrer de Redis 2.8 à Redis 3.0.

* Nous avons un conteneur (`myredis`) qui fait tourner Redis 2.8.

* Arrêtez le conteneur `myredis`.

* Démarrez un nouveau conteneur, avec l'image Redis 3.0, et l'option `--volumes-from`.

* Le nouveau conteneur va hériter des données de l'ancien.

* Les futurs conteneurs pourront aussi utiliser `--volumes-from`.

* Ne marche pas entre serveurs, donc impossible en clusters (Swarm, Kubernetes).


---

class: extra-details

## Migration de données en pratique

Créons un conteneur Redis.

```bash
$ docker run -d --name redis28 redis:2.8
```

Puis connectons-nous au conteneur Redis pour ajouter des données.

```bash
$ docker run -ti --link redis28:redis busybox telnet redis 6379
```

Envoyons les commandes suivantes:

```bash
SET counter 42
INFO server
SAVE
QUIT
```

---

class: extra-details

## Mettre à jour Redis

Arrêtez le conteneur Redis.

```bash
$ docker stop redis28
```

Démarrer le nouveau conteneur Redis.

```bash
$ docker run -d --name redis30 --volumes-from redis28 redis:3.0
```

---

class: extra-details

## Tester le nouveau Redis

Connectez-vous au conteneur Redis pour voir les données.

```bash
docker run -ti --link redis30:redis busybox telnet redis 6379
```

Lancez les commandes suivantes:

```bash
GET counter
INFO server
QUIT
```

---

## Cycle de vie des volumes

* Au moment de supprimer le conteneur, ses volumes sont conservés.

* On peut les lister avec `docker volume ls`.

* On peut y accéder en créant un conteneur avec `docker run -v`.

* On peut les supprimer avec `docker volume rm` ou `docker system prune`.

Au final, _vous_ êtes responsable de logger,
surveiller, et sauvegarder vos volumes.

---

class: extra-details

## Vérifier les volumes définis par une image

Vous vous demandez si une image a des volumes? Il suffit d'appeler `docker inspect`:

```bash
$ # docker inspect training/datavol
[{
  "config": {
    . . .
    "Volumes": {
        "/var/webapp": {}
    },
    . . .
}]
```

---

class: extra-details

## Vérifier les volumes utilisés par un conteneur

Pour voir quels dossiers sont en fait des volumes, et où est-ce qu'ils pointent,
passons par `docker inspect` (encore):

```bash
$ docker inspect <yourContainerID>
[{
  "ID": "<yourContainerID>",
. . .
  "Volumes": {
     "/var/webapp": "/var/lib/docker/vfs/dir/f4280c5b6207ed531efd4cc673ff620cef2a7980f747dbbcca001db61de04468"
  },
  "VolumesRW": {
     "/var/webapp": true
  },
}]
```

* On peut voir que le volume est présent sur le système de fichier de l'hôte Docker.

---

## Partager un seul fichier

La même option `-v` peut servir à partage un seul fichier (au lieu de tout un dossier).

Un des exemples les plus intéressants est de partager la socket de contrôle de Docker.

```bash
$ docker run -it -v /var/run/docker.sock:/var/run/docker.sock docker sh
```

Depuis ce conteneur, on peut lancer des commandes `docker` pour communiquer avec
le Docker Engine qui tourne sur ce serveur. Essayez `docker ps`!

.warning[Puisque ce conteneur a accès à la socket Docker, il a un accès root au hôte.]

---

## Plugins de volume

Vous pouvez installer des plugins pour gérer les volumes adossés à différents
systèmes de stockage ou ayant des fonctions spéciales. Par exemple:

* [REX-Ray](https://rexray.io/) - créer et gérer des volumes adossés à un système de stockage professionnel (SAN ou NAS), ou des solutions cloud (par ex. EBS, EFS).

* [Portworx](https://portworx.com/) - fournit un stockage par bloc distribué pour conteneurs.

* [Gluster](https://www.gluster.org/) - stockage open source, défini par code, qui peut grimper jusqu'à plusieurs petaoctets. Il fournit une interface pour du stockage d'objet, bloc ou fichier.

* et bien d'autres sur le [Docker Store](https://store.docker.com/search?category=volume&q=&type=plugin)!

---

## Volumes vs. Mounts

* Depuis Docker 17.06, une nouvelle option est disponible: `--mount`.

* Elle offre une syntaxe plus riche pour manipuler les données de conteneurs.

* Elle introduit une différence explicite entre:

 - les volumes (identifiés par un nom unique, gérés par un plugin de stockage),

 - les _bind mounts_ (identifiés par un chemin du hôte, sans gestion intermédiaire).

* L'option précédente `-v` / `--volume` reste toujours utilisable.

---

## Syntaxe de `--mount`

Attacher un dossier de l'hôte à un chemin du conteneur:

```bash
$ docker run \
  --mount type=bind,source=/path/on/host,target=/path/in/container alpine
```

Monter un volume dans un chemin du conteneur:

```bash
$ docker run \
  --mount source=myvolume,target=/path/in/container alpine
```

Monter un _tmpfs_ (pour stockage de fichiers temporaires en mémoire):

```bash
$ docker run \
  --mount type=tmpfs,destination=/path/in/container,tmpfs-size=1000000 alpine
```

---

## Résumé de section

Nous avons appris comment:

* Créer et gérer les images.

* Partager des volumes entre conteneurs.

* Partager un dossier de l'hôte avec un ou plusieurs conteneurs.
