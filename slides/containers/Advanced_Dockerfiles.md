
class: title

# Dockerfiles avancés

![construction](images/title-advanced-dockerfiles.jpg)

---

## Objectifs

Nous avons vu des Dockerfiles simples pour illustrer comment Docker
construit des images de conteneurs.

Dans cette section, nous allons voir d'autres commandes
propres aux Dockerfiles.

---

## `Dockerfile`, l'essentiel

* Les instructions d'un `Dockerfile` sont exécutées dans l'ordre.

* Chaque instruction ajoute une nouvelle couche à l'image (_layer_).

* Docker gère un cache avec les _layers_ des _builds_ précédents.

* Quand rien ne change dans les instructions ou les fichiers qui définissent
un _layer_, le _builder_ récupère la version en cache, sans exécuter l'instruction
de ce _layer_.

* L'instruction `FROM` DOIT être la première instruction (hormis les commentaires).

* Les lignes débutant par `#` sont considérées comme des commentaires.

* Quelques instructions (comme `CMD` et `ENTRYPOINT`) concernent les méta-données.
(avec pour conséquence que chaque mention de ces instructions rend les précédentes obsolètes)


---

## Instruction `RUN`

L'instruction `RUN` peut être utilisée de deux manières.

Via le _shell wrapping_, qui exécute la commande spécifiée dans un _shell_,
avec `/bin/sh -c`, exemple:

```dockerfile
RUN apt-get update
```

Ou via la méthode `exec`, qui évite l'expansion de chaine du _shell_, et
permet l'exécution pour les images qui n'embarquent pas `/bin/sh`, i.e. :

```dockerfile
RUN [ "apt-get", "update" ]
```

---

## `RUN` plus en détail

`RUN` est utile pour:

* Exécuter une commande.
* Enregistrer les changements du système de fichiers.
* Installer efficacement des bibliothèques, paquets et divers fichiers.

`RUN` n'est pas fait pour:

* Enregistrer l'état des *processus*
* Démarrer automatiquement un process en tache de fond (_daemon_).

Si vous voulez démarrer automatiquement un processus quand le container se lance,
vous devriez passer par `CMD` et/ou `ENTRYPOINT`.

---

## Fusion de _layers_:

Il est possible d'exécuter plusieurs commandes d'un seul coup:

```dockerfile
RUN apt-get update && apt-get install -y wget && apt-get clean
```

Il est aussi possible de répartir une même commande sur plusieurs lignes:


```dockerfile
RUN apt-get update \
 && apt-get install -y wget \
 && apt-get clean
```

---

## Instruction `EXPOSE`

L'instruction `EXPOSE` indique à Docker quels ports doivent être publié
pour cette image.

```dockerfile
EXPOSE 8080
EXPOSE 80 443
EXPOSE 53/tcp 53/udp
```

* Tous les ports sont privés par défaut;

* Déclarer un port avec `EXPOSE` ne suffit  pas à le rendre public;

* Le `Dockerfile` ne contrôle pas sur quel port un service sera exposé.

---

## Exposer des ports

* Quand vous lancez `docker run -p <port> ...`, ce port devient public;

    (Même s'il n'a pas été déclaré via `EXPOSE`.)

* Quand vous lancez `docker run -P...`(sans numéro de port), tous les ports
déclarés via `EXPOSE` deviennent publics.

Un *port public* est accessible depuis les autres containers
et depuis l'extérieur de la machine hôte.

Un *port privé* n'est pas accessible depuis l'extérieur.

---

## Instruction `COPY`

L'instruction `COPY` ajoute des fichiers et du contenu depuis votre machine hôte
vers l'image.

```dockerfile
COPY . /src
```

Cela va ajouter le contenu du *build context* (le dossier passé en argument
à la commande `docker build`) au dossier `/src` dans l'image.

---

## Isolation du *build context*

Note: vous pouvez manipuler uniquement les fichiers et dossier *contenus*
dans le *build context*. Tout chemin absolu est traité comme ayant pour racine
le *build context*, i.e que les 2 lignes suivantes sont équivalentes:

```dockerfile
COPY . /src
COPY / /src
```
Toute tentative d'utiliser `..` pour sortir du *build context* sera
détectée et bloquée par Docker, et le _build_ échouera.

Sans cela, un `Dockerfile` pourrait être valide sur une machine A, mais échouer sur une machine B.

---

## Instruction `ADD`

`ADD` fonctionne presque comme `COPY`, mais avec quelques petits plus.

`ADD` peut récupérer des fichiers à distance:

```dockerfile
ADD http://www.example.com/webapp.jar /opt/
```

Cette ligne irait  télécharger le fichier `webapp.jar` pour le placer
dans le dossier `/opt`.

`ADD` va automatiquement décompresser les fichiers zip et tar:

```dockerfile
ADD ./assets.zip /var/www/htdocs/assets/
```
Cette ligne décompresse `assets.zip` pour copier son contenu dans `/var/www/htdocs/assets`.

*Néanmoins*, `ADD` ne décompressera pas automatiquement les fichiers téléchargés à distance.

---

## `ADD`, `COPY`, et le cache de _build_

* Avant d'ajouter un nouveau _layer_, Docker vérifie son cache de *build*.

* Pour la plupart des instructions `Dockerfile`, Docker examine simplement le contenu
du Dockerfile pour la vérification du cache.

* Pour les instructions `ADD` et `COPY`, Docker vérifie aussi si les fichiers
à ajouter à l'image ont été modifiés.

* `ADD` doit toujours télécharger tout fichier distant avant de vérifier
s'il a changé.

  (Il ne sait pas utiliser par ex. les en-têtes ETags ou If-Modified-Since)


---

## Instruction `VOLUME`

L'instruction `VOLUME` indique à Docker qu'un dossier spécifique devrait
être un *volume*.

```dockerfile
VOLUME /var/lib/mysql
```

Les accès _filesystem_ dans les volumes contournent la couche _copy-on-write_,
offrant une performance native dans les I/O de ses dossiers.

Les volumes peuvent être attachés à plusieurs containers, permettant
de "transporter" les données d'un container à un autre, dans le cas par ex.
d'une mise à jour de base de données vers une version plus récente.

Il est possible de démarrer un container en mode "lecture seule".
Le _filesystem_ du container sera restreint en mode "lecture seule", mais
tout volume restera en lecture/écriture si nécessaire.

---

## Instruction `WORKDIR`

L'instruction `WORKDIR` change le dossier en cours
pour les instructions suivantes.

Cela affecte aussi `CMD` et `ENTRYPOINT`, puisque cela modifie
le dossier de démarrage quand un container se lance.

```dockerfile
WORKDIR /src
```

Vous pouvez spécifier plusieurs `WORKDIR` pour changer de dossier au cours
des différentes opérations.


---

## Instruction `ENV`

L'instruction `ENV` déclare des variables d'environnement qui devraient être
affectées dans tout _container_ lancé depuis cette image.

```dockerfile
ENV WEBAPP_PORT 8080
```

Ceci a pour résultat de créer une variable d'environnement dans tout
container provenant de cette image.

```bash
WEBAPP_PORT=8080
```

Vous pouvez aussi spécifier des variables d'environnement via `docker run.`

```bash
$ docker run -e WEBAPP_PORT=8000 -e WEBAPP_HOST=www.example.com ...
```

---

## Instruction `USER`

L'instruction `USER` change l'utilisateur ou l'UID à utiliser pour la suite des opérations,
mais aussi l'utilisateur au lancement du _container_.

Comme `WORKDIR`, elle peut être utilisée plusieurs fois, par ex.
pour repasser à `root` ou un autre utilisateur.

---

## Instruction `CMD`

L'instruction `CMD` est la commande par défaut qui se lance quand un
container est instancié à partir d'une image.

```dockerfile
CMD [ "nginx", "-g", "daemon off;" ]
```

Ceci signifie que nous n'avons pas besoin de spécifier `nginx -g "daemon off;"`
lors du lancement de notre container.

Au lieu de:

```bash
$ docker run <dockerhubUsername>/web_image nginx -g "daemon off;"
```

Nous pouvons juste écrire:

```bash
$ docker run <dockerhubUsername>/web_image
```

---

## `CMD` plus en détail

Tout comme `RUN`, l'instruction `CMD` existe sous deux formes.

La première lance un *shell*:

```dockerfile
CMD nginx -g "daemon off;"
```

La seconde s'exécute directement, sans passer par un *shell*:

```dockerfile
CMD [ "nginx", "-g", "daemon off;" ]
```

---

class: extra-details

## Surcharger l'instruction `CMD`

`CMD` peut être forcé au lancement d'un container.

```bash
$ docker run -it <dockerhubUsername>/web_image bash
```

Ceci lancera `bash` au lieu de `nginx -g "daemon off;"`.

---

## Instruction `ENTRYPOINT`

L'instruction `ENTRYPOINT` ressemble à l'instruction `CMD`, sauf
que les arguments passés en ligne de commande sont *ajoutés* au point d'entrée.

Note: vous devez utiliser pour cela la syntaxe "exec" (`["..."]`).

```dockerfile
ENTRYPOINT [ "/bin/ls" ]
```

Avec ceci, si nous lançons la commande:

```bash
$ docker run training/ls -l
```

Au lieu d'essayer de lancer `-l`, le container va exécuter `/bin/ls -l`

---

class: extra-details

## Surcharger l'instruction the `ENTRYPOINT`

Le point d'entrée peut aussi être redéfini.

```bash
$ docker run -it training/ls
bin   dev  home  lib64  mnt  proc  run   srv  tmp  var
boot  etc  lib   media  opt  root  sbin  sys  usr
$ docker run -it --entrypoint bash training/ls
root@d902fb7b1fc7:/#
```

---

## Comment `CMD` et `ENTRYPOINT` interagissent

Les instructions `CMD` et `ENTRYPOINT` fonctionnent mieux
quand elles sont définies ensemble.

```dockerfile
ENTRYPOINT [ "nginx" ]
CMD [ "-g", "daemon off;" ]
```

La ligne `ENTRYPOINT` spécifie la command à lancer et la ligne `CMD`
spécifie ses options. En ligne de commande, nous pourrons donc
potentiellement surcharger les options le cas échéant.

```bash
$ docker run -d <dockerhubUsername>/web_image -t
```

Cela surchargera les options `CMD` avec de nouvelles valeurs.

---

## Instructions Dockerfile avancées

* `ONBUILD` vous permet de cacher des commandes qui ne seront
 executées que quand cette image servira de base à une autre.
* `LABEL` ajoute des meta-datas libres à l'image.
* `ARG` déclare des variables de _build_ (optionelles ou obligatoires).
* `STOPSIGNAL` indique le signal à envoyer lors d'un `docker stop` (`TERM` par défault).
* `HEALTHCHECK` définit une commande de test vérifiant le statut d'un container.
* `SHELL` choisit le programme par défaut pour la forme _string_ de RUN, CMD, etc.

---

class: extra-details

## Instruction `ONBUILD`

L'instruction `ONBUILD` est un déclencheur. Elle indique les commandes à
exécuter quand une image se base sur l'image en cours de _build_.

Ceci est utile pour construire des images qui seront une base pour d'autres images.

```dockerfile
ONBUILD COPY . /src
```

* Vous ne pouvez pas chainer des instructions `ONBUILD`.
* `ONBUILD` ne peut être utilisé pour déclencher des instructions `FROM`
