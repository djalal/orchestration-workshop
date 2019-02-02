
class: title

# Conteneurs en tâche de fond

![Background containers](images/title-background-containers.jpg)

---

## Objectifs

Nos premiers conteneurs étaient *interactifs*.

Nous allons maintenant voir comment:

* Lancer un conteneur non-interactif
* Lancer un conteneur en tâche de fond.
* Lister les conteneurs en cours d'exécution.
* Vérifier les logs d'un conteneur.
* Arrêter un conteneur.
* Lister les conteneurs à l'arrêt.

---

## Un conteneur non-interactif

Nous allons lancer un petit conteneur spécial.

Ce conteneur ne fait qu'afficher l'heure à chaque seconde.

```bash
$ docker run jpetazzo/clock
Fri Feb 20 00:28:53 UTC 2015
Fri Feb 20 00:28:54 UTC 2015
Fri Feb 20 00:28:55 UTC 2015
...
```

* Ce conteneur va tourner indéfiniment.
* Pour l'arrêter, appuyer sur `^C`.
* Docker a automatiquement téléchargé l'image `jpetazzo/clock`.
* Cette image est une image utilisateur, créée par `jpetazzo`.
* Nous en apprendrons plus sur les images utilisateur (et autres types d'images) plus tard.

---

## Lancer un conteneur en tâche de fond

Les conteneurs peuvent être démarrés en tâche de fond, avec l'option `-d` (mode _daemon_)

```bash
$ docker run -d jpetazzo/clock
47d677dcfba4277c6cc68fcaa51f932b544cab1a187c853b7d0caf4e8debe5ad
```

* Nous ne voyons pas l'affichage du conteneur.
* Mais pas de souci: Docker collecte tout affichage et l'écrit dans un log!
* Docker nous retourne un identifiant (ID) du conteneur.

---

## Lister les conteneurs en cours d'exécution

Comment vérifier que notre conteneur est encore lancé?

Avec `docker ps`, tout comme la commande `ps` d'UNIX, qui liste les processus qui tournent.

```bash
$ docker ps
CONTAINER ID  IMAGE           ...  CREATED        STATUS        ...
47d677dcfba4  jpetazzo/clock  ...  2 minutes ago  Up 2 minutes  ...
```

Docker nous indique:

* l'ID (tronqué) de notre conteneur;
* l'image utilisée pour démarrer le conteneur;
* que notre conteneur est lancé (`Up`) depuis quelques minutes;
* d'autres informations (COMMAND, PORTS, NAME) que nous verrons plus tard.

---

## Lancer plus de conteneurs

Démarrons deux autres conteneurs.

```bash
$ docker run -d jpetazzo/clock
57ad9bdfc06bb4407c47220cf59ce21585dce9a1298d7a67488359aeaea8ae2a
```

```bash
$ docker run -d jpetazzo/clock
068cc994ffd0190bbe025ba74e4c0771a5d8f14734af772ddee8dc1aaf20567d
```

Vérifiez que `docker ps` mentionne correctement tous les 3 conteneurs.

---

## Afficher uniquement le dernier conteneur démarré

Quand de nombreux conteneurs tournent déjà, il peut être utile
de limiter l'affichage au dernier conteneur démarré.

C'est à ça que sert l'option `-l` ("Last"):

```bash
$ docker ps -l
CONTAINER ID  IMAGE           ...  CREATED        STATUS        ...
068cc994ffd0  jpetazzo/clock  ...  2 minutes ago  Up 2 minutes  ...
```

---

## Voir uniquement les IDs des conteneurs

Plusieurs commandes Docker sont basées sur des IDs de conteneurs: `docker stop`, `docker rm`, etc.

Si nous voulons lister uniquement les IDs de nos conteneurs (sans les autres colonnes ni en-tête),
nous pouvons utiliser l'option `-q` ("Quiet", "Quick"):

```bash
$ docker ps -q
068cc994ffd0
57ad9bdfc06b
47d677dcfba4
```

---

## Combinaison d'options

Nous pouvons combiner `-l` et `-q` pour uniquement voir l'ID du dernier conteneur démarré:

```bash
$ docker ps -lq
068cc994ffd0
```

A première vue, cela parait vraiment utile dans le cadre de scripts.

Toutefois, si nous voulons démarrer un conteneur et récupérer son ID de manière sécurisée,
il est plus conseillé d'utiliser `docker run -d`, ce que nous aborderons dans un instant.

(Using `docker ps -lq` is prone to race conditions: what happens if someone
else, or another program or script, starts another container just before
we run `docker ps -lq`?)

---

## Voir les logs d'un conteneur

On vous a dit que Docker enregistrait l'affichage d'un conteneur.

C'est le moment d'en parler.

```bash
$ docker logs 068
Fri Feb 20 00:39:52 UTC 2015
Fri Feb 20 00:39:53 UTC 2015
...
```

* Nous avons spécifié un *préfixe* de l'ID d'un conteneur.
* On peut, bien sûr, utiliser l'ID complet.
* La commande `logs` va afficher les logs *complets* du conteneur.
 <br/>(Parfois, c'est bien trop. Voyons comment gérer ça.)

---

## Afficher uniquement la fin des logs

Pour éviter de se faire spammer avec des dizaines de pages d'infos,
on peut utiliser l'option `--tail`:

```bash
$ docker logs --tail 3 068
Fri Feb 20 00:55:35 UTC 2015
Fri Feb 20 00:55:36 UTC 2015
Fri Feb 20 00:55:37 UTC 2015
```

* Le paramètre est le nombre de lignes que nous voulons afficher.

---

## Suivre les logs en temps réel

Tout comme la commande UNIX standard `tail -f`, on peut
suivre les logs de notre conteneur:

```bash
$ docker logs --tail 1 --follow 068
Fri Feb 20 00:57:12 UTC 2015
Fri Feb 20 00:57:13 UTC 2015
^C
```

* Cela affichera la dernière ligne du fichier log
* Puis, l'affichage continuera de se mettre à jour en temps réel.
* Pour sortir, appuyer sur `^C`.

---

## Arrêter notre conteneur

Il y a deux façons de stopper notre conteneur détaché;

* Le tuer via la commmande `docker kill`.
* Le stopper via la commande `docker stop`.

La première arrête le conteneur immédiatement, en utilisant
le signal `KILL`.

La seconde est plus douce. Elle envoie un signal `TERM`, et
après 10 secondes, si le conteneur n'est pas arrêté,
il envoie `KILL`.

Rappel: le signal `KILL` ne peut être intercepté, et terminera
le conteneur de force.

---

## Arrêter nos conteneurs

Essayons d'arrêter un de ces conteneurs:

```bash
$ docker stop 47d6
47d6
```

Cela va prendre 10 secondes:

* Docker envoie le signal TERM;
* le conteneur ne réagit pas à ce signal
  (c'est un simple script Shell sans gestion
  de signal spécifique);
* 10 secondes plus tard, puisque le conteneur est
toujours actif, Docker envoie le signal KILL;
* ceci neutralise le conteneur.

---

## Supprimer le reste des conteneurs

Soyons moins patient avec les deux autres conteneurs:

```bash
$ docker kill 068 57ad
068
57ad
```

Les commandes `stop` et `kill` acceptent plusieurs IDs de conteneurs.

Ces conteneurs seront supprimés immédiatement (sans le délai de 10 secondes).

Vérifions que nos conteneurs ne s'affichent plus:

```bash
$ docker ps
```

---

## Lister les conteneurs arrêtés

Nous pouvons aussi afficher les conteneurs stoppés, avec l'option `-a` (`--all`).

```bash
$ docker ps -a
CONTAINER ID  IMAGE           ...  CREATED      STATUS
068cc994ffd0  jpetazzo/clock  ...  21 min. ago  Exited (137) 3 min. ago
57ad9bdfc06b  jpetazzo/clock  ...  21 min. ago  Exited (137) 3 min. ago
47d677dcfba4  jpetazzo/clock  ...  23 min. ago  Exited (137) 3 min. ago
5c1dfd4d81f1  jpetazzo/clock  ...  40 min. ago  Exited (0) 40 min. ago
b13c164401fb  ubuntu          ...  55 min. ago  Exited (130) 53 min. ago
```
