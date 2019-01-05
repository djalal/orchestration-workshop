
class: title

# Investir l'intérieur d'un conteneur
![Person standing inside a container](images/getting-inside.png)

---

## Objectifs

Sur un serveur classique ou unVM, nous avons parfois besoin de:

* se connecter sur la machine (via SSH ou la console),

* analyser les disques (en les retirant ou en démarrant en mode secours).

Dans ce chapitre, nous verrons comment faire ça sur des conteneurs.

---

## Récupérer un _shell_

De temps à autre, nous avons besoin de nous connecter à un serveur.

Dans un monde parfait, cela ne devrait pas être nécessaire.

* Vous devez installer ou mettre à jour des paquets (et leur configuration)?

  Passez pas la gestion de configuration (par ex. Ansible, Chef, Puppet, Salt...)

* Vous devez jeter un oeil aux logs et métriques?

  Collectez-les et passez par une plate-forme centralisée.

Dans la vraie vie, néanmoins... on doit souvent ouvrir un accès _shell_!

---

## Sans récupérer un _shell_

Même sans un système de déploiement parfait, on peut réaliser plein d'opérations sans passer par un _shell_.

* Installer des paquets peut (et devrait) être fait dans l'image d'un conteneur.

* Configurer le conteneur peut se faire à son démarrage, ou dans l'image.

* Toute configuration dynamique peut passer par un volume (partagé avec un autre conteneur).

* Tous logs passant par _stdout_ sont automatiquement collectés par le Docker Engine.

* N'importe quels autres logs peuvent être écrits dans un volume partagé.

* La machine hôte expose les métriques et les informations du processus.

_Mettons de côté pour plus tard les logs, volumes, etc. et jetons un oeil aux informations de processus!_

---

## Afficher les processus d'un conteneur depuis l'hôte

Si vous lancez Docker sur Linux, les processus de conteneurs sont visibles depuis l'hôte.

```bash
$ ps faux | less
```

* Faites défiler l'affichage de cette commande.

* Vous devriez voir le conteneur `jpetazzo/clock`.

* Un processus dans un conteneur est comme n'importe quel autre processus sur l'hôte.

* Nous pouvons utiliser des outils comme `lsof`, `strace`, `gdb`, ... pour les analyser.

---

class: extra-details

## Quelle est la différence entre les processus de l'hôte et d'un conteneur?

* Chaque processus (conteneurisé ou pas) appartient à des *namespaces* et *cgroups*.

* Les _namespaces_ et _cgroups_ déterminent ce qu'un processus peut "voir" et "faire".

* Analogie: chaque processus (conteneurisé ou pas) tourne avec un UID (user ID) spécifique.

* UID=0, c'est root, et dispose de privilèges supérieurs. Les autres utilisateurs sont dits normaux.

_Nous donneronss plus de détails sur les namespaces et cgroups plus tard._

---

## Récupérer un _shell_ dans un conteneur

* Parfois, nous devons récupérer un _shell_ malgré tout.

* On _pourrait_ faire tourner un serveur SSH dans le conteneur...

* Mais c'est plus facile d'utiliser `docker exec`.

```bash
$ docker exec -ti ticktock sh
```

* Cela créé un nouveau processus (avec `sh`) _à l'intérieur_ du conteneur.

* On peut arriver au même résultat "manuellement" avec l'outil `nsenter`.

---

## Réserves

* Cela exige que l'outil que nous voulons lancer pré-existe dans le conteneur.

* Certains outils (comme `ip netns exec`) permettent de s'attacher à _un_ namespace _à la fois_.

  (On peut par ex. configurer des interfaces réseau, même si vous n'avez pas `ifconfig` ou `ip` dans le conteneur.)

* Et surtout: le conteneur doit être en cours d'exécution.

* Et si le conteneur est stoppé ou en panne?

---

## Récupérer un _shell_ dans un conteneur à l'arrêt

* Un conteneur à l'arrêt n'est que du _stockage_ (comme un disque dur).

* SSH ne sert à rien pour accéder à un disque dur ou une clé USB!

* Nous devons brancher le disque avec une machine en fonctionnement.

* Comment ça se traduit dans le monde des conteneurs?

---

## Analyser un conteneur à l'arrêt

Comme exercice, nous allons essayer de trouver ce qui cloche avec `jpetazzo/crashtest`.

```bash
docker run jpetazzo/crashtest
```

Le conteneur démarre, mais s'arrête tout de suite, sans rien afficher.

Que ferait Mac Gyver &trade;?

D'abord, vérifions le statut de ce conteneur.

```bash
docker ps -l
```

---

## Examiner les changements de fichier

On peut passer `docker diff` pour voir les fichiers ajoutés / modifiés ou supprimés.

```bash
docker diff <container_id>
```

* L'ID du conteneur est affiché par `docker ps -l`.

* On peut aussi le voir avec `docker ps -lq`.

* L'affichage de `docker diff` montre quelques fichiers log intéressants!

---

## Accéder aux fichiers

* On peut extraire les fichiers avec `docker cp`.

```bash
docker cp <container_id>:/var/log/nginx/error.log .
```

* Et c'est là qu'on peut consulter le fichier log.

```bash
cat error.log
```

(Le dossier `/run/nginx` n'existe pas.)

---

## Explorer un conteneur en panne

* On peut redémarrer un conteneur avec `docker start` ...

* ... Mais il va sans doute retomber en panne immédiatement!

* On ne peut pas indiquer un programme différent à lancer avec `docker start`

* Mais on peut générer une nouvelle image à partir du conteneur en panne

```bash
docker commit <container_id> debugimage
```

* On peut alors lancer un nouveau conteneur depuis cette image, avec un point d'entrée spécifique

```bash
docker run -ti --entrypoint sh debugimage
```

---

class: extra-details

## Obtenir un _dump_ complet

* On peut aussi récupérer le système de fichiers complet pour un conteneur.

* C'est possible avec `docker export`.

* Cela génère une archive tar.

```bash
docker export <container_id> | tar tv
```

Cela nous donnera la liste détaillé du contenu de ce conteneur.
