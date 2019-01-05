
class: title

# Notre environnement de formation

![SSH terminal](images/title-our-training-environment.jpg)

---

## Notre environnement de formation

- Si vous assistez à un atelier ou un tutoriel:

  - une VM a été provisionnée pour chaque apprenant

- Si vous suivez ou révisez ce cours tout seul, vous pouvez:

  - installer Docker en local (comme expliqué dans le chapitre "Installer Docker")

  - installer Docker sur une VM dans le cloud (par ex.)

  - utiliser https://www.play-with-docker.com/ pour lancer en un instant un environnement de formation

---

## Notre VM Docker

*Cette section suppose que vous suivez ce cours dans le cadre d'un
tutoriel, une atelier ou une formation, où chaque apprenant reçoit
une VM Docker individuelle.*

- La VM est créée juste avant la formation.

- Elle restera allumée pendant toute la durée de la formation.

- Elle sera détruite peu de temps après la formation.

- Elle est fournie avec Docker et quelques autres outils utiles.

---

## C'est *quoi* Docker?


- "Installer Docker" signifie en vrai "Installer le *Docker Engine* et le client en ligne de commande".

- Le Docker Engine est un *daemon* (un service tournant en tâche de fond).

- Ce *daemon* gère les conteneurs, à la manière d'un hyperviseur qui gère ses VMs.

- Nous dialoguons avec le Docker Engine par la Docker CLI (ligne de commande).

- Docker CLI et Docker Engine communiquent via une API.

- Il existe de nombreux autres programmes, et de composants client, pour exploiter cette API.

---

## Pourquoi on ne lance pas Docker en local?

- On va télécharger des images de conteneur et des paquets de distribution.

- Cela pourrait quelque peu stresser la connexion WiFi locale, et nous ralentir.

- Au lieu de ça, on préfère passer par une VM distante qui a une meilleure connectivité.

- Dans de rares cas, installer Docker en local peut s'avérer tortueux:

  - pas d'accès au compte admin/root (poste géré par une DSI stricte)

  - CPU ou système d'exploitation 32 bits.

  - vieille version de l'OS (par ex. CentOS 6, OSX pré-Yosemite, Windows 7)

- Il est meilleur de passer du temps à apprendre les conteneurs qu'à trifouiller l'installateur!

---

## Se connecter à votre Machine Virtuelle

Vous avez besoin d'un client SSH.

 * Sur OS X, Linux et autres systèmes UNIX, `ssh` suffit:

```bash
$ ssh <login>@<ip-address>
```

* Sur Windows, si vous n'avez pas de client SSH, vous pouvez télécharger:

  * Putty (www.putty.org)

  * Git BASH (https://git-for-windows.github.io/)

  * MobaXterm (https://mobaxterm.mobatek.net/)

---

## Vérifier votre Machine Virtuelle

Une fois connecté(e), assurez-vous que la commande Docker de base fonctionne:

.small[
```bash
$ docker version
Client:
 Version:       18.03.0-ce
 API version:   1.37
 Go version:    go1.9.4
 Git commit:    0520e24
 Built:         Wed Mar 21 23:10:06 2018
 OS/Arch:       linux/amd64
 Experimental:  false
 Orchestrator:  swarm

Server:
 Engine:
  Version:      18.03.0-ce
  API version:  1.37 (minimum version 1.12)
  Go version:   go1.9.4
  Git commit:   0520e24
  Built:        Wed Mar 21 23:08:35 2018
  OS/Arch:      linux/amd64
  Experimental: false
```
]

Si ça ne marche pas, levez la main et un assistant viendra vous aider!
