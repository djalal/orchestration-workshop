
class: title

# Installer Docker

![install](images/title-installing-docker.jpg)

---

## Objectifs

A la fin de cette leçon, vous saurez:

* Comment installer Docker.

* Quand utiliser `sudo` pour lancer des commandes Docker.

*Note:* si on vous a fourni une VM de formation pour cet atelier,
vous pouvez passer ce chapitre, puisque la VM a déjà Docker
d'installé, et Docker est déjà configuré pour tourner sans `sudo`.

---

## Installer Docker

Il existe bien des manières d'installer Docker.

Nous pouvons distinguer sans ordre de préférence:

* Installer Docker sur une machine Linux existante (physique ou VM)

* Installer Docker sur macOS ou Windows

* Installer Docker sur une flotte de VMs de cloud

---

## Installer Docker sur Linux

* La méthode recommandée est d'installer les paquets fournis par Docker Inc.:

  https://store.docker.com

* La méthode générale est:

  - ajouter les dépôts de paquet de Docker Inc. à votre configuration de système.

  - installer le Docker Engine

* Les instructions détaillées d'installation (par distribution) est disponible sur:

  https://docs.docker.com/engine/installation/

* Vous pouvez aussi l'installer à partir d'exécutables (si votre distribution n'est pas supportée):

  https://docs.docker.com/engine/installation/linux/docker-ce/binaries/

---

class: extra-details

## Paquets Docker Inc. vs paquets de distribution

* Docker Inc. publie de nouvelles versions mensuelles (expérimentales) et trimestrielles (stables).

* Les nouvelles versions sont immédiatement disponibles sur les dépôts de paquets chez Docker Inc.

* Les distributions Linux ne mettent pas tout le temps à jour leur version de Docker.

  (Parfois, ce faisant, cela casserait leurs règles de mise à jour mineures/majeures)

* Parfois, des distributions Linux ont publié des paquets avec des modifications spéciales.

* Parfois, ces modifications ont introduit des bugs de sécurité ☹

* Installer Docker depuis les dépôts de Docker Inc. demande un poil plus de travail …

  … mais ça vaut le coup en général!

---

## Installer Docker sur macOS et Windows

* Sur macOS, la méthode recommandée est d'utiliser Docker Desktop pour Mac:

  https://hub.docker.com/editions/community/docker-ce-desktop-mac

* Sur Windows 10 Pro, Enterprise et Education, on a Docker Desktop pour Windows:

  https://hub.docker.com/editions/community/docker-ce-desktop-windows

* Pour d'anciennes versions de Windows, on peut installer Docker Toolbox:

  https://docs.docker.com/toolbox/toolbox_install_windows/

* Sur Windows 2016, vous pouvez aussi le moteur natif:

  https://docs.docker.com/install/windows/docker-ee/

---

## Docker Desktop pour Mac et Windows

* Des éditions spéciales s'intégrant mieux avec leurs systèmes d'exploitation respectifs.

* Livré avec une interface conviviale (GUI) pour gérer les paramètres et la configuration.

* Exploite la couche de virtualisation de l'OS hôte. (par ex. l'[API Hypervisor](https://developer.apple.com/documentation/hypervisor) sur macOS)

* Elle s'installe comme une application normale sur l'hôte.

* Sous le capot, les deux applications exécutent une mini VM (usage transparent)

* Elle accède aux ressources réseau comme les autres applications.
  <br/>(et pour cela, s'intègre mieux avec les VPNs pros et les pares-feu)

* Le système de fichiers est implémenté à travers le partage de volumes (cf. plus loin)

* Les deux éditions supportent juste une seule VM Docker à la fois ...
  <br/>
  ... mais on peut passer par `docker-machine`, Docker Toolbox, VirtualBox, etc. pour monter un _cluster_.

---

## Lancer Docker sur macOS et Windows

Quand on lance `docker version` depuis le terminal:

* la ligne de commande se connecte au Docker Engine via la socket,
* le Docker Engine est, en fait, lancé dans une VM,
* ... mais la ligne de commande ne le sait pas et ne s'en occupe pas,
* la ligne de commande envoie une requête à l'API REST,
* le Docker Engine dans la VM traite la requête,
* la ligne de commande récupère la réponse et vous l'affiche.

Toute communication avec le Docker Engine passe à travers l'API.

Cela rend possible le travail avec des Docker Engine distants comme s'ils étaient en local.

---

## Avertissement de sécurité important

* Si vous avez accès à la socket de contrôle  de Docker, vous pouvez prendre le contrôle de la machine.

  (Parce que vous pouvez lancer des conteneurs qui ont accès aux ressources machine)

* Par conséquent, l'utilisateur `docker` sur Linux est équivalent à `root`.

* Vous devriez en restreindre l'accès au même niveau que `root`.

* Par défaut, la socket de contrôle de Docker appartient au groupe `docker`.

* Vous pouvez y ajouter les utilisateurs de confiance.

* Dans le cas contraire, vous devrez préfixer chaque commande `docker` avec `sudo`, par ex.:

  ```bash
  sudo docker version
  ```
