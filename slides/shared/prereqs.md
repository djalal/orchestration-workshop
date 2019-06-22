# Pre-requis

- Être à l'aise avec la ligne de commande UNIX

  - se déplacer à travers les dossiers

  - modifier des fichiers

  - un petit peu de bash-fu (variables d'environnement, boucles)


- Un peu de savoir-faire sur Docker

 - `docker run`, `docker ps`, `docker build`

 - idéalement, vous savez comment écrire un Dockerfile et le générer.
   <br/>
   (même si c'est une ligne `FROM` et une paire de commandes `RUN`)

- C'est totalement autorisé de ne pas être un expert Docker!


---

class: title

*Raconte moi et j'oublie.*
<br/>
*Apprends-moi et je me souviens.*
<br/>
*Implique moi et j'apprends.*

Attribué par erreur à Benjamin Franklin

[(Plus probablement inspiré du philosophe chinois confucianiste Xunzi)](https://www.barrypopik.com/index.php/new_york_city/entry/tell_me_and_i_forget_teach_me_and_i_may_remember_involve_me_and_i_will_lear/)

---

## Sections pratiques

- Cet atelier est entièrement pratique

- Nous allons construire, livrer et exécuter des conteneurs!

- Vous être invité(e) à reproduire toutes les démos

- Les sections "pratique" sont clairement identifiées, via le rectangle gris ci-dessous

.exercise[

- C'est le genre de trucs que vous êtes censé faire!

- Allez à @@SLIDES@@ pour voir ces diapos

- Joignez-vous au salon de chat: @@CHAT@@

<!-- ```open @@SLIDES@@``` -->

]

---

class: in-person

## Où allons-nous lancer nos conteneurs?

---

class: in-person, pic

![Tu gagnes un cluster!](images/you-get-a-cluster.jpg)

---

class: in-person

## Vous avez votre cluster de VMs dans le cloud

- Chaque personne aura son cluster privé de VMs dans le cloud (partagé avec personne d'autre)

- Les VMs resterons allumées toute la durée de la formation

- Vous devez avoir une petite carte avec identifiant+mot de passe+adresses IP

- Vous pouvez automatiquement SSH d'une VM à une autre

- Les serveurs ont des alias: `node1`, `node2`, etc.

---

class: in-person

## Pourquoi ne pas lancer nos conteneurs en local?

- Installer cet outillage peut être difficile sur certaines machines

  (CPU ou OS à 32bits... Portables sans accès admin, etc.)

- *Toute l'équipe a téléchargé ces images de conteneurs depuis le WiFi!
  <br/>... et tout s'est bien passé* (litéralement personne)

- Tout ce dont vous avez besoin est un ordinateur (ou même une tablette), avec:

  - une connexion internet

  - un navigateur web

  - un client SSH

---

class: in-person

## Clients SSH

- Sur Linux, OS X, FreeBSD... vous être sûrement déjà prêt(e)

- Sur Windows, récupérez un de ces logiciels:

  - [putty](http://www.putty.org/)
  - Microsoft [Win32 OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH)
  - [Git BASH](https://git-for-windows.github.io/)
  - [MobaXterm](http://mobaxterm.mobatek.net/)


- Sur Android, [JuiceSSH](https://juicessh.com/)
  ([Play Store](https://play.google.com/store/apps/details?id=com.sonelli.juicessh))
  marche plutôt pas mal.

- Petit bonus pour: [Mosh](https://mosh.org/) en lieu et place de SSH, si votre connexion internet à tendance à perdre des paquets.

---

class: in-person, extra-details

## What is this Mosh thing?

*You don't have to use Mosh or even know about it to follow along.
<br/>
We're just telling you about it because some of us think it's cool!*

- Mosh is "the mobile shell"

- It is essentially SSH over UDP, with roaming features

- It retransmits packets quickly, so it works great even on lossy connections

  (Like hotel or conference WiFi)

- It has intelligent local echo, so it works great even in high-latency connections

  (Like hotel or conference WiFi)

- It supports transparent roaming when your client IP address changes

  (Like when you hop from hotel to conference WiFi)

---

class: in-person, extra-details

## Using Mosh

- To install it: `(apt|yum|brew) install mosh`

- It has been pre-installed on the VMs that we are using

- To connect to a remote machine: `mosh user@host`

  (It is going to establish an SSH connection, then hand off to UDP)

- It requires UDP ports to be open

  (By default, it uses a UDP port between 60000 and 61000)
