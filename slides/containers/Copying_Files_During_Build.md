
class: title

# Copier des fichiers pendant le _build_

![Monks copying books](images/title-copying-files-during-build.jpg)

---

## Objectifs

Jusqu'ici, nous avons installé des choses dans nos images de conteneurs
en téléchargeant des paquets.

Nous pouvons aussi copier des fichiers depuis le *build context* vers le
conteneur que nous générons.

Rappel: le *build context* est le dossier qui contient le Dockerfile.

Dans ce chapitre, nous apprendrons une nouvelle instruction du Dockerfile: `COPY`.

---

## Compilons du code C

Nous voulons construire un conteneur qui compiles un simple programme "Hello world" écrit en C.

Voici le programme, `hello.c`:

```bash
int main () {
  puts("Hello, world!");
  return 0;
}
```

Ouvrons un nouveau dossier, et plaçons ce fichier à l'intérieur.

Nous écrirons ensuite le Dockerfile.

---

## Le Dockerfile

Sur Debian et Ubuntu, le paquet `build-essential` nous donnera un compilateur.

En l'installant, n'oubliez pas de spécifier l'option `-y`, ou sinon le _build_ échouera
(puisque cette phase ne peut pas être intéractive).

Puis nous allons utiliser `COPY` pour placer le fichier source dans le conteneur.

```bash
FROM ubuntu
RUN apt-get update
RUN apt-get install -y build-essential
COPY hello.c /
RUN make hello
CMD /hello
```

Ecrivez ce Dockerfile.

---

## Tester notre programme C

* Créez les fichiers `hello.c` et `Dockerfile` dans le même dossier.

* Lancer `docker build -t hello .` dans ce dossier.

* Lancer `docker run hello`, vous devriez voir `Hello, world!`.

Victoire!

---

## `COPY` et le cache de _build_

* Lancez le _build_ encore.

* Maintenant, modifiez `hello.c` et lancer le _build_ encore.

* Docker peut mettre en cache les étapes impliquant `COPY`.

* Ces étapes ne seront pas exécutées si les fichiers n'ont pas changé.

---

## Détails

* On peut `COPY` des dossiers complets en récursif.

* D'anciens Dockerfiles peuvent aussi comporter l'instruction `ADD`.
  <br/>C'est similaire sauf qu'il peut aussi extraire des archives automatiquement.

* Si nous voulions vraiment compiler le code C dans le conteneur, nous aurions:

  * copié le source dans un dossier différent, via l'instruction `WORKDIR`.

  * ou mieux encore, utilisé l'image officielle `gcc`.
