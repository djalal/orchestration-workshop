# Construire des images en mode interactif

Dans cette section, nous allons créer notre première image de conteneur.

Cela sera une image de distribution basique, mais nous pré-installerons
le paquet `figlet`.

Nous allons:

* Créer un conteneur à partir d'une image de base.

* Installer un logiciel à la main dans le conteneur, et en
faire une nouvelle image.

* Apprendre de nouvelles commandes: `docker commit`, `docker tag` et `docker diff`.

---

## Le plan

1. Lancer un conteneur (avec `docker run`) avec notre distro Linux de choix.

2. Lancer un tas de commandes pour installer et configurer notre logiciel depuis
l'intérieur du conteneur.

3. (en option) examiner les changements dans le conteneur via `docker diff`.

4. Transformer le conteneur en une nouvelle image avec `docker commit`.

5. (en option) ajouter un _tag_ à l'image avec `docker tag`.

---

## Préparer notre conteneur

Démarrez un conteneur Ubuntu:

```bash
$ docker run -it ubuntu
root@<yourContainerId>:#/
```

Lancez la commande `apt-get update` pour rafraîchir la liste des paquets disponibles à l'installation.

Puis lancez la commande `apt-get install figlet` pour installer le programme qui nous intéresse.

```bash
root@<yourContainerId>:#/ apt-get update && apt-get install figlet
.... AFFICHAGE DES COMMANDES APT-GET ....
```

---

## Inspecter les changements

Taper `exit` dans le terminal du conteneur pour quitter le mode interactif.

Maintenant lançons `docker diff` pour afficher les différences entre l'image de base
et notre conteneur.

```bash
$ docker diff <yourContainerId>
C /root
A /root/.bash_history
C /tmp
C /usr
C /usr/bin
A /usr/bin/figlet
...
```

---

class: x-extra-details

## Docker trace les changements du système de fichiers

Comme expliqué auparavant:

* Une image est en lecture seule uniquement.

* Quand on opère des changements, cela se passe sur une copie de l'image.

* Docker peut afficher les différences entre l'image et sa copie.

* Pour cause de performance, Docker utilise le système _copy-on-write_.
  <br/>(i.e. démarrer un conteneur basé sur une grosse image
  ne provoque pas une énorme copie de fichier.)

---

## Bénéfices sur la sécurité du _Copy-on-write_

* `docker diff` nous offre une vue simple des changements à auditer.

  (à la Tripwire)

* Les conteneurs peuvent aussi être démarrés en mode lecture-seule.
  (leur système de fichier racine sera en lecture seule, mais ils pourront quand même
   disposer de volumes de données en lecture/écriture)

---

## Figer nos changements dans une nouvelle image

La commande `docker commit` va créer une nouvelle couche avec nos changements,
and et une nouvelle image utilisant cette nouvelle couche.

```bash
$ docker commit <yourContainerId>
<newImageId>
```

Le retour de la commande `docker commit` sera l'ID de la nouvelle image créée.

Nous pourrons l'utiliser comme argument à `docker run`.

---

## Tester notre nouvelle image

Lançons cette image:

```bash
$ docker run -it <newImageId>
root@fcfb62f0bfde:/# figlet hello
 _          _ _       
| |__   ___| | | ___  
| '_ \ / _ \ | |/ _ \ 
| | | |  __/ | | (_) |
|_| |_|\___|_|_|\___/ 
```

Ça marche! .emoji[🎉]

---

## _Tagger_ des images

Se référer à une image par son ID n'est pas pratique. Utilisons un _tag_ à la place.

Nous pouvons passer par la commande `tag`:

```bash
$ docker tag <newImageId> figlet
```

Mais nous pouvons aussi spécifier le _tag_ comme un argument de `commit`:

```bash
$ docker commit <containerId> figlet
```

Et ensuite l'exécuter via son _tag_:

```bash
$ docker run -it figlet
```

---

## Et après?

Méthode manuelle = pas bien.

Méthode automatisée = bien.

Dans le prochain chapitre, nous apprendrons comment automatiser
 le processus de construction en écrivant un `Dockerfile`.
