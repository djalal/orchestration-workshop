
class: title

# Bases du réseau pour conteneur

![A dense graph network](images/title-container-networking-basics.jpg)

---

## Objectifs

Nous allons maintenant lancer des services connectés (acceptant des requêtes) dans des conteneurs.

À la fin de cette section, vous serez capable de:

* Lancer un service connecté dans un conteneur;

* Manipuler les bases du réseau pour conteneur;

* Trouver l'adresse IP d'un conteneur.

Nous expliquerons aussi les différents modèles de réseau usités par Docker.

---

## Un serveur web simple, statique

Lancer l'image `nginx` du Docker Hub, qui contient un serveur web basique:

```bash
$ docker run -d -P nginx
66b1ce719198711292c8f34f84a7b68c3876cf9f67015e752b94e189d35a204e
```

* Docker va télécharger l'image depuis le Docker Hub.

* `-d` dit à Docker de lancer une image en tâche de fond.

* `-P` dit à Docker de rendre se service disponible depuis d'autres serveurs.
  <br/>(`-P` est la version courte de `--publish-all`)

Mais, comment on se connecte à notre serveur web maintenant?

---

## Trouver le port de notre serveur web

Nous allons utiliser `docker ps`:

```bash
$ docker ps
CONTAINER ID  IMAGE  ...  PORTS                  ...
e40ffb406c9e  nginx  ...  0.0.0.0:32768->80/tcp  ...
```

* Le serveur web tourne sur le port 80 à l'intérieur du conteneur.

* Ce port correspond au port 32768 sur notre hôte Docker.

Nous expliquerons les pourquoi et comment de ce mappage.

Mais d'abord, assurons-nous que tout fonctionne correctement.

---

## Connexion à notre serveur web (IHM)

Pointer votre navigateur à l'adresse IP de votre hôte Docker, sur le port
affiché par `docker ps`, correspondant au port 80 du conteneur.

![Screenshot](images/welcome-to-nginx.png)

---

## Connexion à notre serveur web (CLI)

Vous pouvez aussi utiliser `curl` directement depuis le hôte Docker.

Assurez-vous d'utiliser le bon numéro de port s'il est différent
de notre exemple ci-dessous:

```bash
$ curl localhost:32768
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

---

## Comment Docker sait quel port associer?

* Il y a des meta-données dans l'image indiquant "cette image fait tourner quelque chose sur le port 80"

* On peut examiner ces meta-donnéees avec `docker inspect`:

```bash
$ docker inspect --format '{{.Config.ExposedPorts}}' nginx
map[80/tcp:{}]
```

* Cette méta-donnée a pour origine le Dockerfile, via le mot-clé `EXPOSE`.

* On peut le constater avec `docker history`:

```bash
$ docker history nginx
IMAGE               CREATED             CREATED BY
7f70b30f2cc6        11 days ago         /bin/sh -c #(nop)  CMD ["nginx" "-g" "…
<missing>           11 days ago         /bin/sh -c #(nop)  STOPSIGNAL [SIGTERM]
<missing>           11 days ago         /bin/sh -c #(nop)  EXPOSE 80/tcp
```

---

## Pourquoi le mappage de ports?

* Nous n'avons plus d'adresses IPv4.

* Les conteneurs ne peuvent pas avoir d'adresse IPv4 publiques.

* Ils possèdent des adresses privées.

* Les services doivent être exposés port par port.

* Le mappage de ports est obligatoire pour éviter les conflits.

---

## Trouver le port du serveur web via un script

Manipuler la sortie de `docker ps` serait fastidieux.

Il y a une commande pour nous aider:

```bash
$ docker port <containerID> 80
32768
```

---

## Affectation manuelle des numéros de port

Si vous voulez allouer vous-même les numéros de port, aucun souci:

```bash
$ docker run -d -p 80:80 nginx
$ docker run -d -p 8000:80 nginx
$ docker run -d -p 8080:80 -p 8888:80 nginx
```

* Trois serveurs web NGINX tournent.
* Le premier est exposé sur le port 80.
* Le deuxième est exposé sur le port 8000.
* Le troisième est exposé sur les ports 8080 et 8888.

Note: la convention est `port-du-hôte:port-du-conteneur`.

---

## Intégrer les conteneurs dans votre infrastructure

On peut intégrer les conteneurs au réseau de bien des manières.

* Démarrer le conteneur, pour laisser Docker lui allouer un port public.
  <br/>Puis lire le port affecté et l'injecter dans votre configuration.

* Choisir un numéro de port à l'avance, au moment de générer votre configuration.
  <br/>Puis démarrer votre conteneur en forçant les ports à la main.

* Utiliser un _plugin_ de réseau, pour brancher vos conteneurs sur des VLANs, tunnels, etc.

* Activer le *Mode Swarm* pour un déploiement à traver un _cluster_.
  <br/>Le conteneur sera accessible depuis n'importe quel noeud du _cluster_.

En utilisant Docker à travers une couche de gestion supplémentaire comme Mesos ou Kubernetes, ils fournissent en général leur propre mécanismes d'exposition de conteneurs.

---

## Trouver l'adresse IP du conteneur

Nous pouvons utiliser la commande `docker inspect` pour trouver l'adresse IP
de notre conteneur.

```bash
$ docker inspect --format '{{ .NetworkSettings.IPAddress }}' <yourContainerID>
172.17.0.3
```

* `docker inspect` est une commande avancée, qui peut retourner une tonne
d'informations à propos des conteneurs.

* Ici, nous lui fournissons une chaîne pour extraire exactement l'adresse IP
du conteneur.

---

## Interroger notre conteneur

Nous pouvons tester la connectivité du conteneur via l'adresse IP
déterminée précédemment. Voyons ceci avec l'outil `ping`.

```bash
$ ping <ipAddress>
64 bytes from <ipAddress>: icmp_req=1 ttl=64 time=0.085 ms
64 bytes from <ipAddress>: icmp_req=2 ttl=64 time=0.085 ms
64 bytes from <ipAddress>: icmp_req=3 ttl=64 time=0.085 ms
```

---

## Résumé du chapitre

Nous avons appris comment:

* Exposer un port sur le réseau;

* Manipuler les bases du réseau pour conteneur;

* Trouver une adresse IP de conteneur.

Dans le chapitre suivant, nous verrons comment connecter
les conteneurs entre eux, sans publier leurs ports.
