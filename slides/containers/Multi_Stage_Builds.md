# Réduire la taille de l'image

* Dans notre précédent exemple, notre image finale contenait:

  * notre programme `hello`

  * son code source

  * le compilateur

* Seul le premier élément est strictement nécessaire.

* Nous allons voir comment obtenir une image sans les composants superflus.

---

## Ne pouvons-nous pas retirer les fichiers superflus avec `RUN`?

Que se passe-t-il si nous utilisons une des commandes suivantes?

- `RUN rm -rf ...`

- `RUN apt-get remove ...`

- `RUN make clean ...`

--

Cela ajoute une couche qui supprime un tas de fichiers.

Mais les couches précédentes (qui ont ajouté les fichiers) existent toujours.

---

## Retirer les fichiers avec un _layer_ en plus

En téléchargeant une image, tous les _layers_ doivent être récupérés.

| Instruction Dockerfile | Taille du _layer_ | Taille de l'image |
| ---------------------- | ---------- | ---------- |
| `FROM ubuntu` | Taille de l'image de base | Taille de l'image de base  |
| `...` | ... | Somme de cette couche <br/>+ toutes les précédentes |
| `RUN apt-get install somepackage` | Taille des fichiers ajoutés <br/>(e.g. qqes Mo) | Somme de cette couche <br/>+ toutes les couches précédentes|
| `...` | ... | Somme de cette couche <br/>+ toutes les couches précédentes |
| `RUN apt-get remove somepackage` | Env. zéro<br/>(méta-données seules) | Identique à la précédente |

En conséquence, `RUN rm` ne réduit pas la taille de l'image, ni ne libère d'espace disque.

---

## Supprimer les fichiers inutiles

Des techniques variées sont disponibles pour obtenir des images plus petites:

 - dégonflement de _layers_,

 - ajouter des binaires qui sont générés hors du Dockerfile,

 - aplatir l'image finale,

 - les _builds multi-stage_, à multiples étapes.

Passons-les en revue rapidement.

---

## Dégonflement de _layers_

Vous verrez souvent des Dockerfiles comme suit:

```dockerfile
FROM ubuntu
RUN apt-get update && apt-get install xxx && ... && apt-get remove xxx && ...
```

Ou la variante plus lisible:

```dockerfile
FROM ubuntu
RUN apt-get update \
 && apt-get install xxx \
 && ... \
 && apt-get remove xxx \
 && ...
```

Cette commande `RUN` nous retourne une seule couche.

Les fichiers qui y sont ajoutés, puis supprimés dans le même _layer_, n'augmentent pas sa taille.

---

## Dégonflement de _layers_ : pour et contre

Pours:

- fonctionne sur toutes les versions de Docker

- n'exige pas d'outils spéciaux

Contre:

- pas très lisible

- quelques fichiers inutiles pourrait subsister si le nettoyage n'est pas assez poussé

- ce _layer_ est coûteux (lent à générer)

---

## Compiler les binaires hors du Dockerfile

Cela résulte dans un Dockerfile qui ressemble à ça:

```dockerfile
FROM ubuntu
COPY xxx /usr/local/bin
```

Bien sûr, cela suppose que le fichier `xxx` existe déjà dans le _build context_.

Ce fichier doit exister avant de lancer `docker build`.

Par exemple, il peut:

- exister dans le dépôt du code,
- être créé par un autre outil (script, Makefile...),
- être créé par un autre conteneur puis extrait depuis l'image.

Voir par exemple [l'image officielle busybox](https://github.com/docker-library/busybox/blob/fe634680e32659aaf0ee0594805f74f332619a90/musl/Dockerfile) ou cette [image busybox plus ancienne](https://github.com/jpetazzo/docker-busybox).

---

## Compiler les binaires en dehors: pour et contre

Pours:

- l'image finale peut être très petite

Contre:

- exige un outil de _build_ supplémentaire

- nous retombons dans l'enfer des dépendances et le "ça-marche-sur-mon-poste"

Contre, si le binaire est ajouté au dépôt de code:

- brise la portabilité entre différentes plate-formes

- augmente largement la taille du dépôt si le binaire est souvent mis à jour

---

## Aplatir l'image finale

L'idée est de transformer l'image finale en une image à un seul _layer_.

Cela peut être réalisé de deux manières (au moins).

- Activer les fonctions expérimentales et aplatir l'image finale:
  ```bash
  docker image build --squash ...
  ```
- Exporter/importer l'image finale.
  ```bash
  docker build -t temp-image .
  docker run --entrypoint true --name temp-container temp-image
  docker export temp-container | docker import - final-image
  docker rm temp-container
  docker rmi temp-image
  ```

---

## Aplatir l'image finale: pour et contre

Pours:

- les images à _layer_ unique sont plus légères et rapides à télécharger

- les fichiers supprimés ne prennent plus de place ni de ressources réseau.

Contre:

- nous devons quand même activement supprimer les fichiers inutiles;

- aplatir une image peut prendre beaucoup de temps (pour les plus grosses images)

- aplatir est une opération qui annule le cache
  <br/>
  (ne changer ne serait-ce qu'un petit fichier, et toute l'image doit être aplatie de nouveau)


---

## _Builds_ multi-stage

Un _build multi-stage_ nous permet d'indiquer plusieurs étapes d'images.

Chaque étape constitue une image séparée, et peut copier les fichiers des images précédentes.

Nous allons voir comment ça marche plus en détail.

---

# _Builds_ multi-stage

* A tout moment dans notre `Dockerfile`, nous pouvons ajouter une ligne `FROM`.

* Cette ligne démarre une nouvelle étape dans notre _build_.

* Chaque étape peut accéder aux fichiers des étapes précédentes avec `COPY --from=...`.

* Quand un _build_ est étiqueté (avec `docker build -t ...`), c'est la dernière étape qui récupère le _tag_.

* Les étapes précédentes ne sont pas supprimées, elle seront utilisées par le cache, et peuvent être référencées.

---

## _Builds_ Multi-stage en pratique

* Chaque étape est numérotée, en débutant à `0`

* Nous pouvons copier un fichier d'une étape précédente en indiquant son numéro, par ex.:

  ```dockerfile
  COPY --from=0 /fichier/depuis/etape/une /chemin/dans/etape/courante
  ```

* Nous pouvons aussi nommer les étapes, et y faire référence:

  ```dockerfile
  FROM golang AS builder
  RUN ...
  FROM alpine
  COPY --from=builder /go/bin/mylittlebinary /usr/local/bin/
  ```

---

## _Builds_ multi-stage pour notre programme C

Nous allons changer notre Dockerfile pour:

* donner un surnom à notre première étape: `compiler`

* ajouter une seconde étape utilisant la même image de base `ubuntu`

* ajouter le binaire `hello` à la seconde étape

* vérifier que `CMD` est dans la seconde étape

Le Dockerfile résultant est dans la prochaine diapo.

---

## `Dockerfile` du _build_ multi-stage

Voici le Dockerfile final:

```dockerfile
FROM ubuntu AS compiler
RUN apt-get update
RUN apt-get install -y build-essential
COPY hello.c /
RUN make hello
FROM ubuntu
COPY --from=compiler /hello /hello
CMD /hello
```

Essayons de le générer, et vérifions que cela fonctionne bien:
```bash
docker build -t hellomultistage .
docker run hellomultistage
```

---

## Comparaison des tailles d'image en _build_ simple/multi-stage

Listez nos images avec `docker images`, et vérifiez la taille de:

- l'image de base `ubuntu`,

- l'image `hello` à étape unique,

- l'image `hellomultistage` à plusieurs étapes.

Nous pouvons arriver à des tailles d'images encore plus petites avec des images de base plus petites.

Toutefois, si nous utilisons une image de base commune (par ex. en prenant comme standard `ubuntu`), ces images en commun ne seront téléchargées qu'une fois par hôte, les rendant
virtuellement "gratuites".

---

## Cibles de _build_

* On peut aussi étiqueter une étape intermédiaire avec `docker build --target STAGE --tag NAME`

* Cela va créer une image (appelée `NAME`) correspondant à l'étape `STAGE`

* Elle peut être utilisée pour accéder facilement à une étape intermédiaire pour inspection.

  (Au lieu de fouiller l'affichage de `docker build` pour trouver l'ID d'image)

* Elle peut aussi être utilisée pour générer de multiples images avec un seul Dockerfile

  (Au lieu d'utiliser plusieurs Dockerfiles, qu'il faudrait perpétuellement synchroniser)
