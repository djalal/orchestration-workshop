# Docker Engine et autres moteurs de conteneurs

* Nous allons couvrir l'architecture du _Docker Engine_.

* Nous présenterons aussi d'autres moteurs de conteneurs.

---

class: pic

## Architecture externe du moteur Docker
![](images/docker-engine-architecture.svg)

---

## Architecture externe du moteur Docker

* Le moteur est un _daemon_ (processus tournant en tâche de fond).

* Toute interaction est faite à travers l'API REST exposé via une _socket_.

* Sur Linux, la _socket_ par défaut est de type UNIX: `/var/run/docker.sock`.

* Nous pouvons aussi utiliser une  _socket_ TCP, avec une authentification TLS mutuelle.

* La commande `docker` en ligne de commande communique avec le moteur à travers la _socket_.

Note: _stricto sensu_, l'API Docker n'est pas complètement REST.

Quelques opérations (e.g. la gestion interactive de conteneurs et la transmission de logs)
ne respectent pas le modèle REST.
---

class: pic

## Architecture interne du moteur Docker

![](images/dockerd-and-containerd.png)

---

## Architecture interne du moteur Docker

* Jusqu'à Docker 1.10: le Docker Engine est un binaire monolithique unique.

* À partir de Docker 1.11, le moteur est séparé en multiple parties:

 - `dockerd` (API REST, authentification, réseau, stockage)

 - `containerd` (cycle de vie du conteneur, controllé via une API gRPC)

 - `containerd-shim` (par conteneur; ne permet presque rien, à part redémarrer le moteur sans redémarrer les conteneurs)

 - `runc` (par conteneur; prend en charge le gros du travail lors du démarrage d'un conteneur)

* Quelques fonctionnalités (comme la gestion d'image et de _snapshot_) sont progressivement poussés hors de `dockerd` vers `containerd`.

Pour plus de détails, consulter [cette courte présentation par Phil Estes](https://www.slideshare.net/PhilEstes/diving-through-the-layers-investigating-runc-containerd-and-the-docker-engine-architecture).

---

## Autres moteurs de conteneurs

La liste suivante n'est pas exhaustive.

En outre, nous l'avons limité au conteneurs Linux.

Windows, macOS, Solaris, FreeBSD, etc. prennent aussi en charge les conteneurs (parfois sous un autre nom).

---

## LXC

* Le vénérable ancêtre (première publication en 2008).

* Docker se basait dessus à l'origine pour lancer ses conteneurs.

* Pas de _daemon_, ni API centrale.

* Chaque conteneur est géré par un processus `lxc-start`.

* Chaque processus `lxc-start` expose une API spécifique via une _socket_ locale UNIX, permettant l'intéraction avec le conteneur.

* Aucune notion d'image (les systèmes de fichier pour conteneur doivent être gérés à la main).

* Le réseau doit être configuré à la main.

---

## LXD

* Ré-utilise le code LXC (à travers liblxc)

* Se base sur LXC pour offrir une expérience plus moderne.

* Un _daemon_ expose une API REST.

* Peut gérer images, _snapshots_, migrations, réseaux et stockage.

* "offre une expérience utilisateur similaire aux machines virtuelles, en les remplaçant par des conteneurs Linux."

---

## rkt

* Comparable à `runc`.

* Pas de _daemon_ ni API.

* Fort emphase sur la sécurité (à travers la séparation de privilège).

* Paramètrage séparé du réseau (e.g. via les plugins CNI).

* Prise en charge partielle des images (_pull_, mais pas de _push_).

  (D'autres outils prennent en charge la génération d'image.)

---

## CRI-O

* Conçu pour être utilisé avec Kubernetes comme un runtime simple et basique.

* Comparable à `containerd`.

* Expose une interface gRPC via le _daemon_.

* Controlé par l'API CRI (Container Runtime Interface, définie par Kubernetes).

* Exige un moteur OCI sous-jacent (e.g. `runc`).

* Stockage, images et réseau pris en charge via des plugins CNI.

A notre connaissance, personne ne l'utilise directement (i.e. hors Kubernetes).

---

## systemd

* système "init" (PID 1) dans la plupart des distributions Linux modernes.

* Offre des outils comme `systemd-nspawn` et `machinectl` pour gérer les conteneurs.

* `systemd-nspawn` est "De bien des manières similaires à chroot(1), mais en plus puissant".

* `machinectl` peut intéragir avec des VMs ou des conteneurs gérés par systemd

* Expose une API DBUS.

* Supporte partiellement les images (sous forme d'archives tar ou d'image disque brutes).

* Couche réseau à gérer manuellement à part.

---

<<<<<<< HEAD
## Kata containers

* OCI-compliant runtime.

* Fusion of two projects: Intel Clear Containers and Hyper runV.

* Run each container in a lightweight virtual machine.

* Requires to run on bare metal *or* with nested virtualization.

---

## gVisor

* OCI-compliant runtime.

* Implements a subset of the Linux kernel system calls.

* Written in go, uses a smaller subset of system calls.

* Can be heavily sandboxed.

* Can run in two modes:

  * KVM (requires bare metal or nested virtualization),

  * ptrace (no requirement, but slower).

---

## Globalement ...

* Le Docker Engine est très centré sur le développeur:

 - facile à installer

 - facile à utiliser

 - pas d'installation manuelle

 - génération et transfert d'image de première classe

* En conséquence, c'est un outil fantastique sur les environnements de développement.

* Sur les serveurs:

 - Docker est un bon choix par défaut

 - Si vous utilisez Kubernetes, le moteur importe peu
