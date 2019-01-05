
class: title

# Comprendre les images Docker
![image](images/title-understanding-docker-images.png)

---

## Objectifs

Dans cette section, nous expliquerons:

 * Ce qu'est une image;

 * Ce qu'est un _layer_;

 * Les différents nommages d'image;

 * Comment chercher et télécharger des images;

 * Les _tags_ d'image et quand les utiliser.

---

## Qu'est-ce qu'une image?

* Image = fichiers + méta-données

* Ces fichiers forment le système de fichier racine de notre conteneur.

* Les méta-données indiquent un nombre de choses, comme:

  * l'auteur de l'image
  * la commande à exécuter dans le conteneur au démarrage
  * les variables d'environnement à initialiser
  * etc.

* Des couches composent les images, appelées _layers_, empilées les unes au-dessus des autres.

* Chaque couche peut ajouter, modifier, supprimer des fichiers ou des méta-données.

* Les _layers_ sont partagés entre images pour optimiser l'usage du disque, les temps de transfert et la consommation mémoire.

---

## Exemple d'une web app Java

Chaque des points suivants se traduira par un _layer_:

* couche de base CentOS
* Paquets et fichier de configuration fournis par le service informatique interne
* JRE
* Tomcat
* Dépendances de notre application
* Code et sources de notre application
* Configuration de notre appli

---

class: pic

## Le _layer_ en lecture/écriture

![layers](images/container-layers.jpg)

---

## Plusieurs conteneurs partageant la même image

![layers](images/sharing-layers.jpg)

---

## Différences entre conteneurs et images

* Une image est un système de fichiers en lecture seule.

* Un conteneur est un ensemble de processus encapsulé dans
une copie en lecture/écriture de ce système de fichiers.

* Pour optimiser le temps de démarrage du conteneur, on fait du
*copy-on-write* au lieu d'une copie traditionnelle.

* `docker run` démarre un conteneur depuis une image donnée.

---

## Comparaison avec la programmation orientée objet

* Conceptuellement, les images sont proches des *classes*.

* Conceptuellement, les _layers_ sont proches de l'*héritage*.

* Conceptuellement, les conteneurs sont proches des *instances*.

---

## Attends un peu...

Si une image est en lecture-seule, comment on la change?

* On ne la change pas.

* On lance un nouveau conteneur à partir de cette image.

* Puis on apporte des modifications à ce conteneur.

* Quand on a fini, nous les figeons dans un nouveau _layer_.

* Une nouvelle image est créée en empilant la nouvelle couche au-dessus de l'ancienne image.

---

## Le problème de l'oeuf et la poule

* La seule façon de créer une image est de geler un conteneur.

* La seule façon de créer un conteneur est d'instancier une image.

* A l'aide!

---

## Créer les premières images

Il existe une image spéciale vide, appelée `scratch`.

* Elle permet de générer une image *de zéro*.

La commande `docker import` charge un fichier tarball dans Docker.

* L'image importée devient une image indépendante.
* Cette nouvelle image a un seul _layer_.

Note: vous n'aurez sans doute jamais à faire cela vous-même.

---

## Créer d'autres images

`docker commit`

* Enregistre tous les changements d'un conteneur dans un nouveau _layer_.
* Génère une nouvelle image (en réalité une copie du conteneur).

`docker build` **(utilisé 99% du temps)**

* Exécute une séquence répétable de construction.
* C'est la méthode recommandée!

Nous expliquerons les deux méthodes dans un moment.

---

## Images et espaces de nommage

Il existe trois espaces de nommage (_namespaces_):

* Images officielles:

    par ex. `ubuntu`, `busybox`, etc.

* Images d'utilisateurs (et organisations):

    par ex. `jpetazzo/clock`

* Images auto hébergées

    par ex. `registry.example.com:5000/mon-image/privee`

Examinons chacun d'entre eux.

---

## Espace de nom 'racine'

L'espace de nom racine est pour les images officielles. Elles y sont placées par Docker Inc.,
mais sont généralement écrites et maintenues par des tierces parties.

Ces images inclut:

* De petites images "couteau suisse", telles busybox.

* Des images de distributions Linux servant de base aux _builds_, comme ubuntu, fedora, etc.

* Des services et composants prêts à l'emploi, comme redis, postgresql, etc.

* Plus de 130 à ce jour!

---

## Espace de nommage utilisateur

L'espace de nommage pour utilisateur contient les images dans Docker Hub fournies par les utilisateurs et organisations.

Par exemple:

```bash
jpetazzo/clock
```

L'utilisateur Docker Hub est:

```bash
jpetazzo
```

Le nom de l'image est:

```bash
clock
```

---

## Espace de nommage auto-hébergé

Cet espace de nommage contient les images qui ne sont pas hébergées sur Docker Hub, mais sur des registres de tierce partie.

Ils contiennent le nom de serveur (ou adresse IP), et le port (en option), du serveur de registre.

Par exemple:

```bash
localhost:5000/wordpress
```

* `localhost:5000` est l'hôte et le port du registre
* `wordpress` est le nom de cette image

Other examples:

```bash
quay.io/coreos/etcd
gcr.io/google-containers/hugo
```

---

## Comment gérer et stocker les images?

On stocke les images:
 * sur votre hôte Docker.
 * dans un registre Docker.

Vous pouvez utiliser le client Docker pour télécharger (pull) ou téléverser (push) des images.

Pour être plus précis: vous pouvez utiliser le client Docker pour intimer au Docker Engine
de _push_ et _pull_ des images vers/depuis un registre.

---

## Afficher les images actuelles

Voyons quelles sont les images disponibles sur notre serveur.

```bash
$ docker images
REPOSITORY       TAG       IMAGE ID       CREATED         SIZE
fedora           latest    ddd5c9c1d0f2   3 days ago      204.7 MB
centos           latest    d0e7f81ca65c   3 days ago      196.6 MB
ubuntu           latest    07c86167cdc4   4 days ago      188 MB
redis            latest    4f5f397d4b7c   5 days ago      177.6 MB
postgres         latest    afe2b5e1859b   5 days ago      264.5 MB
alpine           latest    70c557e50ed6   5 days ago      4.798 MB
debian           latest    f50f9524513f   6 days ago      125.1 MB
busybox          latest    3240943c9ea3   2 weeks ago     1.114 MB
training/namer   latest    902673acc741   9 months ago    289.3 MB
jpetazzo/clock   latest    12068b93616f   12 months ago   2.433 MB
```

---

## Chercher des images

Nous ne pouvons lister *toutes* les images sur un registre distant, mais
nous pouvons chercher un mot-clé spécifique:

```bash
$ docker search marathon
NAME                     DESCRIPTION                     STARS  OFFICIAL  AUTOMATED
mesosphere/marathon      A cluster-wide init and co...   105              [OK]
mesoscloud/marathon      Marathon                        31               [OK]
mesosphere/marathon-lb   Script to update haproxy b...   22               [OK]
tobilg/mongodb-marathon  A Docker image to start a ...   4                [OK]
```


* "Stars" mesure la popularité de l'image.

* "Official" concerne les images qui sont dans le _namespace_ racine.

* "Automated" indique que l'image est générée automatiquement par le Docker Hub.
  <br/>(Cela signifie que leur recette de construction est toujours disponible.)

---

## Télécharger des images

Il y a deux façons de récupérer des images.

* Explicite, avec `docker pull`.

* Implicite, en lançant `docker run` et l'image n'est pas disponible en local.

---

## Télécharger une image via _pull_

```bash
$ docker pull debian:jessie
Pulling repository debian
b164861940b8: Download complete
b164861940b8: Pulling image (jessie) from debian
d1881793a057: Download complete
```

* Comme vu précédemment, les images sont faites de _layers_.

* Docker a téléchargé tous les _layers_ nécessaires.

* Dans notre exemple, `:jessie` indique quelle version exacte de Debian nous voulons.

C'est un _tag_ (étiquette) de version.

---

## Images et _tags_

* On peut associer des _tags_ aux images.

* C'est utile pour préciser les versions ou variantes d'une image.

* `docker pull ubuntu` va se référer à `ubuntu:latest`.

* Le _tag_ `:latest` est par tradition mis à jour fréquemment.

---

## Quand utiliser (et ne pas utiliser) les _tags_

Pas besoin de spécifier d'étiquette (_tag_) pour:

* des tests ou prototypes rapides.
* expérimenter.
* récupérer la dernière version.

Utiliser des _tags_ pour:

* Persister une procédure dans un script;
* Déployer en production;
* Garantir que la même version sera utilisée partout;
* Garantir la répétabilité future.

This is similar to what we would do with `pip install`, `npm install`, etc.

---

## Résumé du chapitre

Nous avons appris comment:

* Comprendre les images et _layers_;
* Fonctionne les espaces de nom dans Docker;
* Chercher et télécharger des images.

