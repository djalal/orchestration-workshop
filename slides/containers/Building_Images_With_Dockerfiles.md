
class: title

# Construire des images Docker avec un Dockerfile

![Construction site with containers](images/title-building-docker-images-with-a-dockerfile.jpg)

---

## Objectifs

Nous allons construire une image de conteneur automatiquement, grâce au `Dockerfile`.

A la fin de cette leçon, vous saurez comment:

* Ecrire un `Dockerfile`.

* Générer une image (_build_) via un `Dockerfile`.

---

## Aperçu d'un `Dockerfile`

* Un `Dockerfile`est une recette de construction pour une image Docker.

* Il contient une série d'instructions indiquant à Docker comment l'image est construite.

* La commande `docker build` génère une image à partir d'un `Dockerfile`.

---

## Ecrire notre premier `Dockerfile`

Notre Dockerfile doit être dans un **dossier nouveau et vide**.

1. Ajouter un nouveau dossier pour accueillir notre `Dockerfile`.

```bash
$ mkdir myimage
```

2. Créer un fichier `Dockerfile` à l'intérieur de ce nouveau dossier.

```bash
$ cd myimage
$ vim Dockerfile
```

Bien sûr, vous pouvez utiliser n'importe quel éditeur de votre choix.

---

## Entrez ces lignes dans notre Dockerfile...

```dockerfile
FROM ubuntu
RUN apt-get update
RUN apt-get install figlet
```

* `FROM` indique notre image de base pour notre _build_.

* Chaque ligne `RUN` sera exécutée par Docker pendant le _build_.

* Nos commandes `RUN` *doivent être non-interactive*.
  <br/>(Aucune entrée ne peut être fournie à Docker pendant le _build_).

* Dans bien des cas, nous ajouterons l'option `-y` à `apt-get`.

---

## Construisons-la!

Enregistrez notre fichier, et lancez:

```bash
$ docker build -t figlet .
```

* `-t` indique le _tag_ à appliquer à l'image.

* `.` indique la localisation du *build context*.

Nous parlerons en détails du _build context_ plus tard.

Pour garder les choses simples: c'est le dossier où se trouve notre `Dockerfile`.

---

## Que se passe-t-il quand nous générons l'image?

L'affichage de `docker build` ressemble à ceci:

.small[
```bash
docker build -t figlet .
Sending build context to Docker daemon  2.048kB
Step 1/3 : FROM ubuntu
 ---> f975c5035748
Step 2/3 : RUN apt-get update
 ---> Running in e01b294dbffd
(...output of the RUN command...)
Removing intermediate container e01b294dbffd
 ---> eb8d9b561b37
Step 3/3 : RUN apt-get install figlet
 ---> Running in c29230d70f9b
(...output of the RUN command...)
Removing intermediate container c29230d70f9b
 ---> 0dfd7a253f21
Successfully built 0dfd7a253f21
Successfully tagged figlet:latest
```
]

* L'affichage des commandes `RUN`a été omis.
* Voyons voir en quoi consiste cette affichage.

---

## Envoi du _build context_ à Docker

```bash
Sending build context to Docker daemon 2.048 kB
```

* Le _build context_ est le dossier `.` donné à `docker build`.

* Il est envoyé (sous forme d'archive) par le client Docker au _daemon_ Docker.

* Cela permet d'utiliser un serveur distant pour le _build_ utilisant des fichiers locaux.

* Soyez attentifs (ou patient) si ce dossier est lourd et votre connexion est lente.

---

## Exécution de chaque étape

```bash
Step 2/3 : RUN apt-get update
 ---> Running in e01b294dbffd
(...output of the RUN command...)
Removing intermediate container e01b294dbffd
 ---> eb8d9b561b37
```

* Un container (`e01b294dbffd`) est créé à partir de l'image de base.

* La commande `RUN` se lance dans ce container.

* Le conteneur est sauvé dans une nouvelle image (`eb8d9b561b37`)

* Le conteneur de _build_ (`e01b294dbffd`) est supprimé.

* Le résultat de cette étape sera l'image de base pour la prochaine commande.

---

## Le système de cache

Si vous lancez le même _build_ de nouveau, ce sera instantané. Pourquoi?

* Après chaque étape de _build_, Docker prend un _snapshot_ de l'image résultante.

* Avant chaque nouvelle étape, Docker vérifie si la même séquence a été générée.

* Docker utilise les chaines de caractères exactes définies dans votre `Dockerfile`, donc:

  * `RUN apt-get install figlet cowsay `
    <br/> est différent de
    <br/> `RUN apt-get install cowsay figlet`
  * `RUN apt-get update` n'est pas exécuté, quand les miroirs sont mis à jour.

Vous pouvez forcer un nouveau _build_ avec `docker build --no-cache...`.

---

## Lancer l'image

L'image résultante n'est pas différente de celle définie manuellement.

```bash
$ docker run -ti figlet
root@91f3c974c9a1:/# figlet hello
 _          _ _       
| |__   ___| | | ___  
| '_ \ / _ \ | |/ _ \ 
| | | |  __/ | | (_) |
|_| |_|\___|_|_|\___/ 
```


Youpi! .emoji[🎉]

---

## Utiliser l'image et afficher l'historique

La commande `history` liste toutes les couches composant une image.

Pour chaque couche (_layer_), on voit la date de création, sa taille et la commande utilisée.

Quand une image est générée via un `Dockerfile`, chaque _layer_ correspond à une ligne du `Dockerfile`.

```bash
$ docker history figlet
IMAGE         CREATED            CREATED BY                     SIZE
f9e8f1642759  About an hour ago  /bin/sh -c apt-get install fi  1.627 MB
7257c37726a1  About an hour ago  /bin/sh -c apt-get update      21.58 MB
07c86167cdc4  4 days ago         /bin/sh -c #(nop) CMD ["/bin   0 B
<missing>     4 days ago         /bin/sh -c sed -i 's/^#\s*\(   1.895 kB
<missing>     4 days ago         /bin/sh -c echo '#!/bin/sh'    194.5 kB
<missing>     4 days ago         /bin/sh -c #(nop) ADD file:b   187.8 MB
```

---

## Introduction à la syntaxe JSON

La plupart des arguments de `Dockerfile` peuvent être passés sous deux formes:

* chaine simple:
  <br/>`RUN apt-get install figlet`

* liste JSON:
  <br/>`RUN ["apt-get", "install", "figlet"]`

We are going to change our Dockerfile to see how it affects the resulting image.

---

## Usage de la syntaxe JSON dans notre Dockerfile

Changeons notre Dockerfile comme suit:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
```

Puis relançons un _build_ du nouveau Dockerfile.

```bash
$ docker build -t figlet .
```

---

## Syntaxe JSON vs syntaxe simple

Comparons le nouvel historique:

```bash
$ docker history figlet
IMAGE         CREATED            CREATED BY                     SIZE
27954bb5faaf  10 seconds ago     apt-get install figlet         1.627 MB
7257c37726a1  About an hour ago  /bin/sh -c apt-get update      21.58 MB
07c86167cdc4  4 days ago         /bin/sh -c #(nop) CMD ["/bin   0 B
<missing>     4 days ago         /bin/sh -c sed -i 's/^#\s*\(   1.895 kB
<missing>     4 days ago         /bin/sh -c echo '#!/bin/sh'    194.5 kB
<missing>     4 days ago         /bin/sh -c #(nop) ADD file:b   187.8 MB
```

* La syntaxe JSON spécifie une commande *exact* à exécuter.

* La syntaxe simple spécifie une commande à être encapsulée dans `/bin/sh -c "..."`.

---

## Quand utiliser la syntaxe JSON et la syntaxe simple

* La syntaxe simple:

  * est plus facile à écrire
  * extrapole les variables d'environnement et d'autres expressions de shell
  * créé un processus supplémentaire (`/bin/sh -c ...`) pour interpréter la commande
  * exige l'existence de `/bin/sh` dans le conteneur

* La syntaxe JSON:

  * est plus longue à écrire (et à lire!)
  * passe tous les arguments sans interprétation
  * n'ajoute pas de processus supplémentaire
  * ne requière pas l'existence de `/bin/sh` dans le conteneur
