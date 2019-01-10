
class: title

# Processus de développement local avec Docker

![Construction site](images/title-local-development-workflow-with-docker.jpg)

---

## Objectifs

A la fin de cette section, vous serez capable de:

* Partager du code entre conteneur et hôte.

* Utiliser un processus de développement local simple.

---

## Développement local dans un conteneur

On veut résoudre les problèmes suivants:

- "Ça marche sur ma machine"

- "Pas la même version"

- "Manque une dépendance"

En utilisant les conteneurs Docker, on arrivera à un environnement de développement homogène.

---

## Travailler à l'application "namer"

* Nous avons à travailler sur une application dont le code est sur:

  https://github.com/jpetazzo/namer.

* De quoi s'agit-il? On ne le sait pas encore!

* Récupérons le code.

```bash
$ git clone https://github.com/jpetazzo/namer
```

---

## Examiner le code

```bash
$ cd namer
$ ls -1
company_name_generator.rb
config.ru
docker-compose.yml
Dockerfile
Gemfile
```

--

Aha, un `Gemfile`! C'est du Ruby. Probablement. On s'en doute. A moins que?

---

## Examiner le `Dockerfile`

```dockerfile
FROM ruby

COPY . /src
WORKDIR /src
RUN bundler install

CMD ["rackup", "--host", "0.0.0.0"]
EXPOSE 9292
```

* Cette appli utilise l'image de base `ruby`.
* Le code est copié dans `/src`.
* Les dépendances sont installées avec `bundler`.
* L'application est lancé via `rackup`.
* Elle écoute sur le port 9292.

---

## Générer et lancer l'application "namer"

* Générons l'application grâce au `Dockerfile`!

--

```bash
$ docker build -t namer .
```

--

* Et maintenant lancez-là. *on doit publier ses ports.*

--

```bash
$ docker run -dP namer
```

--

* Vérifiez sur quel port le conteneur écoute.

--

```bash
$ docker ps -l
```

---

## Accéder à notre application

* Pointez le navigateur sur le serveur Docker, et sur le port alloué au conteneur.

--

* Cliquez "Recharger" plusieurs fois.

--

* C'est un générateur de nom d'entreprise de première classe, certifié ISO, niveau opérateur de réseau!

  (Avec 50% de plus de baratin que la moyenne de la compétition!)

  (Attends, c'était 50% de plus, ou 50% de moins? *Qu'importe!*)

  ![web application 1](images/webapp-in-blue.png)

---

## Amender le code

Option 1:

* Modifier le code en local
* Re-générer une image
* Relancer un conteneur

Option 2:

* S'introduire dans le conteneur (avec `docker exec`)
* Installer un éditeur
* Changer le code depuis l'intérieur du conteneur

Option 3:

* Utiliser un *volume* pour monter les fichiers locaux dans le conteneur
* Opérer les changements en local
* Constater les changements dans le conteneur

---

## Notre premier volume

On va indiquer à Docker de monter le dossier en cours sur `/src` dans le conteneur.

```bash
$ docker run -d -v $(pwd):/src -P namer
```

* `-d`: le conteneur doit tourner en mode détaché (en arrière-plan).

* `-v`: le dossier du hôte mentionné doit être monté à l'intérieur du conteneur.

* `-P`: tous les ports exposés par cette image doivent être publiés.

* `namer` est le nom de l'image à exécuter.

* Nous n'ajoutons pas la commande à lancer car elle est déjà dans le Dockerfile.

Note: sur Windows, remplacer `$(pwd)`par `%cd%` (ou `${pwd}` avec PowerShell).

---

## Monter les volumes dans des conteneurs

L'option `-v` monte un dossier depuis votre hôte dans le conteneur Docker.

La structure de l'option est:

```bash
[chemin-hote]:[chemin-conteneur]:[rw|ro]
```

* Si `[chemin-hote]` ou `[chemin-conteneur]` n'existe pas, il sera créé.

* Vous pouvez contrôler l'option d'écriture du volume avec les options `ro` et `rw`.

* Si vous ne spécifiez ni `rw` ou `ro`, ce sera `rw` par défaut.

Il y aura un chapitre complet sur les volumes!

---

## Tester le conteneur de développement

* Trouvez le port utilisé par notre nouveau conteneur.

```bash
$ docker ps -l
CONTAINER ID  IMAGE  COMMAND  CREATED        STATUS  PORTS                   NAMES
045885b68bc5  namer  rackup   3 seconds ago  Up ...  0.0.0.0:32770->9292/tcp ...
```

* Ouvrez l'application sur votre navigateur web.

---

## Opérer un changement dans notre application

Notre client n'aime pas du tout la couleur de notre texte. Allons la changer.

```bash
$ vi company_name_generator.rb
```

Et changeons:

```css
color: royalblue;
```

En:

```css
color: red;
```

---

## Tester nos changements

* Recharger l'application dans notre navigateur

--

* La couleur doit avoir changé.

  ![web application 2](images/webapp-in-red.png)

---

## Comprendre les volumes

* *Aucune* copie ou synchronisation de fichiers entre hôte et conteneur ne se passe dans un volume.

* Les volumes sont des *bind mounts*: un mécanisme du noyau associant un chemin à un autre.

* Un bind mount est _une sorte de_ lien symbolique, mais à un niveau très différent.

* Tout changement sur l'hôte ou le conteneur sera visible de l'autre côté.

  (Puisque sous le capot, c'est le même fichier de toute façon.)

---

## Jetez vos serveurs et brûlez votre code

*(C'est le titre d'un [billet de blog de 2013](http://chadfowler.com/2013/06/23/immutable-deployments.html) par Chad Fowler, expliquant le concept d'infrastructure immuable.)*

--

* Mettons un grand bazar dans notre conteneur.

  (Supprimer des fichiers ou autre.)

* Maintenant, comment réparer ça?

--

* Notre vieux conteneur (avec la version bleue du code) tourne toujours.

* Voyons sur quel port c'est exposé:
  ```bash
  docker ps
  ```
* Pointez le navigateur dessus pour confirmer que ça marche toujours bien.

---

## Infrastructure immuable en deux mots

* Au lieu de *modifier* le serveur, nous en déployons un nouveau.

* Cela peut sembler un défi pour les serveurs classiques, mais c'est trivial avec les conteneurs.

* En fait, avec Docker, le processus le plus logique est de générer une nouvelle image et de la lancer.

* Si quoique ce soit cloche avec la nouvelle image, on peut toujours relancer l'ancienne.

* On peut même garder les deux versions côte-à-côte.

* Si ce motif vous semble intéressant, vous pouvez regarder du côté des déploiements *blue/green* ou *canary*

---

## Récap du process de développement

1. Ecrire un Dockerfile pour générer une image contenant l'environnement de développement.
   <br/>
   (Rails, Django, ... et toutes les dépendances de notre appli)

2. Démarrer un conteneur de cette image.
   <br/>
   Utiliser l'option `-v` pour monter notre code source dans le conteneur.

3. Modifier le code source hors des conteneurs, avec les outils d'habitude.
   <br/>
   (vim, emacs, textmate...)

4. Tester l'application.
   <br/>
   (Certains frameworks détecter les changements automatiquement
   <br/>D'autres exigent un Ctrl+C / redémarrage après chaque modification..)

5. Reboucler et répéter les étapes 3 et 4 jusqu'à satisfaction.

6. Quand c'est fini, faire un "commit+push" des changements de code.

---

class: extra-details

## Débugger à l'intérieur du conteneur

Docker dispose d'une commande appelée `docker exec`.

Cela permet aux utilisateurs de lancer un nouveau processus dans un conteneur déjà lancé.

Si parfois vous sentez que vous aimeriez entrer via SSH sur un conteneur: vous pouvez utiliser `docker exec` à la place.

Vous pouvez ainsi récupérer un terminal ou lancer une n'importe quelle autre commande pour automatisation.

---

class: extra-details

## Exemple avec `docker exec`

```bash
$ #Vous pouvez lancer des commandes ruby dans là même où l'appli tourne!
$ docker exec -it <yourContainerId> bash
root@5ca27cf74c2e:/opt/namer# irb
irb(main):001:0> [0, 1, 2, 3, 4].map {|x| x ** 2}.compact
=> [0, 1, 4, 9, 16]
irb(main):002:0> exit
```

---

class: extra-details

## Arrêter le conteneur

Maintenant que nous avons fini, arrêtons notre conteneur.

```bash
$ docker stop <yourContainerID>
```

Et supprimons-le.

```bash
$ docker rm <yourContainerID>
```

---

## Résumé de section

Nous avons appris à:

 * Partager le code entre conteneur et hôte.

 * Régler notre dossier de travail.

 * Utiliser un processus simple de développement.
