# Redémarrer et s'attacher aux conteneurs

Nous avons lancé des conteneurs en avant-plan, et en tâche de fond.

Dans ce chapitre, nous verrons comment:

 * Passer un conteneur en tâche de fond.
 * Attacher un conteneur d'arrière-plan pour l'amener au premier plan.
 * Redémarrer un conteneur arrêté.

---

## Avant-plan et arrière-plan

La distinction entre les conteneurs d'avant-plan et d'arrière-plan est arbitraire.

Du point de vue de Docker, tous les conteneurs sont les mêmes.

Tous les conteneurs tournent de la même manière, qu'ils aient un client attaché ou pas.

Il est toujours possible de détacher un conteneur, et de se ré-attacher à un conteneur.

Analogie: s'attacher à un conteneur est comme brancher un clavier et un écran à un serveur physique.

---

## Détacher un conteneur (Linux/macOS)

* Si vous démarrez un conteneur *interactif* (avec l'option `-it`), vous pouvez vous en détacher.

* La séquence pour "détachement" est `^P^Q`.

* Par ailleurs, vous pouvez le détacher en tuant le client Docker.

  (Mais pas avec la touche `^C`, car cela enverrait le signal `SIGINT` au conteneur.)

Mais que représente `-it`?

* `-t` signifie "allouer un terminal".
* `-i` signifie "connecter stdin à ce terminal"

---

## Détacher, suite. (PowerShell Win et cmd.exe)

* `^P^Q` ne fonctionne pas.

* `^C` va le détacher, au lieu de stopper le conteneur.

* Utiliser Bash, Subsystem pour Linux, etc. sur Windows se comporte comme les shells Linux/macOS.

* PowerShell et Bash fonctionnent bien tous les deux sur Win 10; attention en revanche aux subtilités.

---

class: extra-details

## Spécifier une séquence de détachement personnalisée

* `^P^Q` ne vous convient pas? Pas de souci!
* Vous pouvez changer cette séquence avec `docker run --detach-keys`
* On peut aussi la passer comme une option globale au moteur.

Démarrez un conteneur avec une commande de détachement spécifique:

```bash
$ docker run -ti --detach-keys ctrl-x,x jpetazzo/clock
```

Se détacher en tapant `^X x`. (C'est Ctrl-x puis x, pas deux fois Ctrl-X!)

Vérifier que notre conteneur tourne toujours:

```bash
$ docker ps -l
```

---

class: extra-details

## S'attacher à un conteneur

On peut s'attacher à un conteneur:

```bash
$ docker attach <containerID>
```

* Le conteneur doit être lancé.
* Il peut y avoir plusieurs clients attachés au même conteneur.
* Si on ne précise pas `--detach-keys` en s'attachant, la valeur par défaut reste `^P^Q`.

Essayez-la sur notre conteneur précédent:

```bash
$ docker attach $(docker ps -lq)
```

Vérifier que `^X x` ne passe pas, mais que `^P ^Q` fonctionne.

---

## Se détacher de conteneurs non-interactifs

* **Avertissement:** si le conteneur a été démarré sans `-it`...

  * vous ne pourrez pas le détacher avec `^P^Q`
  * si vous tapez `^C`, le signal sera passé au conteneur

* Rappel: vous pouvez toujours le détacher en tuant le client Docker.

---

## Vérifier la sortie du conteneur

* Utilisez `docker attach` si vous souhaitez envoyer des commandes au conteneur.

* Si vous voulez juste afficher la sortie du conteneur, utilisez `docker logs`.

```bash
$ docker logs --tail 1 --follow <containerID>
```

---

## Redémarrer un conteneur

Quand un conteneur est sorti, il est dans un état arrêté.

Il peut être redémarré avec la commande `start`.

```bash
$ docker start <yourContainerID>
```

Le conteneur sera redémarré avec les mêmes options qu'à sa création originelle.

Vous pouvez vous y ré-attacher si vous voulez interagir:

```bash
$ docker attach <yourContainerID>
```

Utilisez `docker ps -a` pour identifier l'ID d'un ancien conteneur basé sur `jpettazo/clock`, et testez ces commandes.

---

## S'attacher à un REPL

* REPL = "Lit (_Read_), Evalue (_Eval_), Affiche (_Print_), Boucle (_Loop_)"

* Shells, interpréteurs, TUI ...

* Symptôme: après un `docker attach`, rien ne se passe.

* Le _REPL_ ne sait pas que vous venez de vous attacher, et n'a rien à afficher.

* Essayez de taper `^L` ou `Entrée`

---

class: extra-details

## SIGWINCH


* Après un `docker attach`, le Docker Engine envoie un signal SIGWINCH au conteneur.

* SIGWINCH = WINdow CHange; indique un changement dans la taille de fenêtre.

* Cela provoque un rafraîchissement d'écran chez certains programmes textuels ou en ligne de commande.

* Mais pas tout le temps.
