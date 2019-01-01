# Astuces pour Dockerfiles efficaces

Nous allons voir comment:

* réduire le nombre de _layers_.

* Exploiter le cache de _build_ pour accélérer la construction.

* Injecter les tests unitaires dans le processus de génération.

---

## Reducing the number of layers
## Réduire le nombre de _layers_

* Chaque ligne du Dockerfile ajoute une nouvelle couche.

* Ecrivez votre Dockerfile pour exploiter le système de cache de Docker.

* Combinez les commandes avec `&&` pour chainer les commandes et `\` pour empiler les lignes.

Note: il est fréquent d'écrire un Dockerfile ligne par ligne:

```dockerfile
RUN apt-get install thisthing
RUN apt-get install andthatthing andthatotherone
RUN apt-get install somemorestuff
```

Puis le corriger très facilement avant déploiement:

```dockerfile
RUN apt-get install thisthing andthatthing andthatotherone somemorestuff
```

---

## Eviter de ré-installer les dépendances à chaque _build_

* Problème classique de Dockerfile:

  "chaque fois que je change une ligne de code, toutes mes dépendances sont ré-installées!"

* Solution: `COPY`-er les listes de dépendances (`packages.json`, `requirements.txt`, etc.)
  à part pour éviter de ré-installer des dépendances inchangées chaque fois.

---

## Exemple de "mauvais" `Dockerfile`

Les dépendances sont ré-installées chaque fois, car le système de _build_ ne sait pas si `requirements.txt` a été mis à jour.

```bash
FROM python
WORKDIR /src
COPY . .
RUN pip install -qr requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]
```

---

## Correction du `Dockerfile`

Ajouter les dépendances dans une étape à part permet à Docker un cache plus efficace, car il ne les installera que si `requirements.txt` change.

```bash
FROM python
COPY requirements.txt /tmp/requirements.txt
RUN pip install -qr /tmp/requirements.txt
WORKDIR /src
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

---

## Injecter les tests unitaires dans le processus de génération.

```dockerfile
FROM <baseimage>
RUN <install dependencies>
COPY <code>
RUN <build code>
RUN <install test dependencies>
COPY <test data sets and fixtures>
RUN <unit tests>
FROM <baseimage>
RUN <install dependencies>
COPY <code>
RUN <build code>
CMD, EXPOSE ...
```

* Le _build_ échoue dès qu'une instruction échoue
* Si `RUN <unit tests>` échoue, le _build_ ne produira aucune image
* S'il réussit, le _build_ générera une image propre (sans librairie de test ni données)

---

# Exemples de Dockerfile

Il y a quelque astuces, conseils et techniques qu'on peut appliquer dans nos Dockerfiles.

Mais parfois, on se doit de passer par des formes différentes, voire opposées, selon:

 - la complexité du projet,

 - le langage de programmation ou le _framework_ choisi,

 - l'étape du projet (nouveau MVP vs prod super-stable),

 - si nous générons une image finale, ou une base pour d'autres images,

 - etc.

Nous allons montrer quelques exemples de techniques très différentes.

---

## Quand optimiser une image

Au moment d'écrire des images officielles, c'est une bonne idée de réduire au maximum:

- le nombre de couches,

- la taille finale de l'image.

C'est souvent au détriment du temps de génération et du confort pour le mainteneur de l'image; mais quand une image est téléchargée des millions de fois, économiser ne serait-ce qu'une poignée de secondes de délai vaut le coup.

.small[
```dockerfile
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd
...
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_UPSTREAM_VERSION}.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data /usr/src/wordpress
```
]

(Source: [Image officielle Wordpress](https://github.com/docker-library/wordpress/blob/618490d4bdff6c5774b84b717979bfe3d6ba8ad1/apache/Dockerfile))

---

## Quand ne *pas* optimiser une image

Parfois, il est préférable de prioriser le *confort du mainteneur*

En particulier, si:

 - l'image change beaucoup,

 - l'image a peu d'utilisateurs (par ex. 1 seul, le mainteneur!),

 - l'image est générée et lancée sur la même machine,

 - l'image est générée et lancée sur des machines sur un réseau très rapide...

Dans ces cas, mieux vaut garder les choses simples!

(Prochaine diapo: un Dockerfile qui peut être utilisé pour un aperçu de site Jekyll / *github pages*)

---

```dockerfile
FROM debian:sid

RUN apt-get update -q
RUN apt-get install -yq build-essential make
RUN apt-get install -yq zlib1g-dev
RUN apt-get install -yq ruby ruby-dev
RUN apt-get install -yq python-pygments
RUN apt-get install -yq nodejs
RUN apt-get install -yq cmake
RUN gem install --no-rdoc --no-ri github-pages

COPY . /blog
WORKDIR /blog

VOLUME /blog/_site

EXPOSE 4000
CMD ["jekyll", "serve", "--host", "0.0.0.0", "--incremental"]
```

---

## Multi-dimensional versioning systems
## Système de version multi-dimensionnels

Un _tag_ d'image peut indiquer une version de l'image.

Mais parfois, plusieurs composants importants co-existent, et nous devons indiquer les versions de chacun.

C'est possible en passant par des variables d'environnement:

```dockerfile
ENV PIP=9.0.3 \
    ZC_BUILDOUT=2.11.2 \
    SETUPTOOLS=38.7.0 \
    PLONE_MAJOR=5.1 \
    PLONE_VERSION=5.1.0 \
    PLONE_MD5=76dc6cfc1c749d763c32fff3a9870d8d
```

(Source: [Image officielle Plone](https://github.com/plone/plone.docker/blob/master/5.1/5.1.0/alpine/Dockerfile))

---

## _Entrypoints_ et démarreurs

Il est très répandu de définir un _entrypoint_ spécifique.

Ce point d'entrée est généralement un script, réalisant une série d'opération telles que:

 - vérifications avant démarrage (si une dépendance obligatoire n'est pas disponible, afficher un message d'erreur sympa au lieu d'un obscur paquet de lignes dans un fichier log);

 - génération ou validation de fichier de configuration;

 - limiter les privilèges (avec par ex. `su` ou `gosu`, parfois combiné avec `chown`);

 - et plus encore.

---

## Un script d'_entrypoint_ typique

```dockerfile
 #!/bin/sh
 set -e

 # first arg is '-f' or '--some-option'
 # or first arg is 'something.conf'
 if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
 	set -- redis-server "$@"
 fi

 # allow the container to be started with '--user'
 if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
 	chown -R redis .
 	exec su-exec redis "$0" "$@"
 fi

 exec "$@"
```

(Source: [Image officielle Redis](https://github.com/docker-library/redis/blob/d24f2be82673ccef6957210cc985e392ebdc65e4/4.0/alpine/docker-entrypoint.sh))

---

## Factoriser les informations

Pour faciliter la maintenance (et éviter les erreurs humaines), éviter de répéter des informations comme:

- numéros de versions,

- URLs de ressources distantes (par ex. fichiers tarballs) ...

Pour ce faire, utilisez des variables d'environnement.

.small[
```dockerfile
ENV NODE_VERSION 10.2.1
...
RUN ...
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
...
```
]

(Source: [Image officielle Nodejs](https://github.com/nodejs/docker-node/blob/master/10/alpine/Dockerfile))

---

## Surcharge

En théorie, les images de production et développement devraient être les mêmes.

En pratique, nous avons souvent besoin d'activer des comportements spécifiques en développement (par ex. trace de debogage).

Une façon de concilier les deux besoins est d'utiliser Compose pour activer ces comportements.

Jetons un oeil à l'appli de démo [trainingwheels](https://github.com/jpetazzo/trainingwheels) comme exemple.

---

## Image de production

Le Dockerfile génère une image exploitant gunicorn:

```dockerfile
FROM python
RUN pip install flask
RUN pip install gunicorn
RUN pip install redis
COPY . /src
WORKDIR /src
CMD gunicorn --bind 0.0.0.0:5000 --workers 10 counter:app
EXPOSE 5000
```

(Source: [Dockerfile trainingwheels](https://github.com/jpetazzo/trainingwheels/blob/master/www/Dockerfile))

---

## Fichier Compose de développement

Ce fichier Compose utilise la même image, mais avec quelques valeurs surchargées en développement:

- On préfère le serveur Flask de développement (surcharge de `CMD`);

- On définit la variable d'environnement `DEBUG`;

- On utilise un volume pour fournir un processus de développement local plus rapide.

.small[
```yaml
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
```
]

(Source: [Fichier Compose trainingwheels](https://github.com/jpetazzo/trainingwheels/blob/master/docker-compose.yml))

---

## Comment choisir quelles bonnes pratiques sont les meilleures?

- Le but principal des conteneurs est de rendre notre vie meilleure;

- Dans ce chapitre, nous avons montré bien des façons d'écrire des Dockerfiles;

- Ces Dockerfiles utilisent parfois des techniques diamétralement opposée;

- Et pourtant, c'était la "bonne" technique *pour cette situation spécifique*;

- C'est bien (et souvent encouragé) de commencer simple et d'évoluer selon le besoin;

- N'hésitez pas à revoir ce chapitre plus tard (après quelques Dockerfiles) pour inspiration!
