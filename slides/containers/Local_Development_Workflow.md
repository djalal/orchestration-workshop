
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

The `-v` flag mounts a directory from your host into your Docker container.

The flag structure is:

```bash
[host-path]:[container-path]:[rw|ro]
```

* If `[host-path]` or `[container-path]` doesn't exist it is created.

* You can control the write status of the volume with the `ro` and
  `rw` options.

* If you don't specify `rw` or `ro`, it will be `rw` by default.

There will be a full chapter about volumes!

---

## Testing the development container

* Check the port used by our new container.

```bash
$ docker ps -l
CONTAINER ID  IMAGE  COMMAND  CREATED        STATUS  PORTS                   NAMES
045885b68bc5  namer  rackup   3 seconds ago  Up ...  0.0.0.0:32770->9292/tcp ...
```

* Open the application in your web browser.

---

## Making a change to our application

Our customer really doesn't like the color of our text. Let's change it.

```bash
$ vi company_name_generator.rb
```

And change

```css
color: royalblue;
```

To:

```css
color: red;
```

---

## Viewing our changes

* Reload the application in our browser.

--

* The color should have changed.

  ![web application 2](images/webapp-in-red.png)

---

## Understanding volumes

* Volumes are *not* copying or synchronizing files between the host and the container.

* Volumes are *bind mounts*: a kernel mechanism associating a path to another.

* Bind mounts are *kind of* similar to symbolic links, but at a very different level.

* Changes made on the host or on the container will be visible on the other side.

  (Since under the hood, it's the same file on both anyway.)

---

## Trash your servers and burn your code

*(This is the title of a
[2013 blog post](http://chadfowler.com/2013/06/23/immutable-deployments.html)
by Chad Fowler, where he explains the concept of immutable infrastructure.)*

--

* Let's mess up majorly with our container.

  (Remove files or whatever.)

* Now, how can we fix this?

--

* Our old container (with the blue version of the code) is still running.

* See on which port it is exposed:
  ```bash
  docker ps
  ```

* Point our browser to it to confirm that it still works fine.

---

## Immutable infrastructure in a nutshell

* Instead of *updating* a server, we deploy a new one.

* This might be challenging with classical servers, but it's trivial with containers.

* In fact, with Docker, the most logical workflow is to build a new image and run it.

* If something goes wrong with the new image, we can always restart the old one.

* We can even keep both versions running side by side.

If this pattern sounds interesting, you might want to read about *blue/green deployment*
and *canary deployments*.

---

## Recap of the development workflow

1. Write a Dockerfile to build an image containing our development environment.
   <br/>
   (Rails, Django, ... and all the dependencies for our app)

2. Start a container from that image.
   <br/>
   Use the `-v` flag to mount our source code inside the container.

3. Edit the source code outside the containers, using regular tools.
   <br/>
   (vim, emacs, textmate...)

4. Test the application.
   <br/>
   (Some frameworks pick up changes automatically.
   <br/>Others require you to Ctrl-C + restart after each modification.)

5. Iterate and repeat steps 3 and 4 until satisfied.

6. When done, commit+push source code changes.

---

class: extra-details

## Debugging inside the container

Docker has a command called `docker exec`.

It allows users to run a new process in a container which is already running.

If sometimes you find yourself wishing you could SSH into a container: you can use `docker exec` instead.

You can get a shell prompt inside an existing container this way, or run an arbitrary process for automation.

---

class: extra-details

## `docker exec` example

```bash
$ # You can run ruby commands in the area the app is running and more!
$ docker exec -it <yourContainerId> bash
root@5ca27cf74c2e:/opt/namer# irb
irb(main):001:0> [0, 1, 2, 3, 4].map {|x| x ** 2}.compact
=> [0, 1, 4, 9, 16]
irb(main):002:0> exit
```

---

class: extra-details

## Stopping the container

Now that we're done let's stop our container.

```bash
$ docker stop <yourContainerID>
```

And remove it.

```bash
$ docker rm <yourContainerID>
```

---

## Section summary

We've learned how to:

* Share code between container and host.

* Set our working directory.

* Use a simple local development workflow.

