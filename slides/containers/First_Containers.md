
class: title

# Nos premiers conteneurs

![Colorful plastic tubs](images/title-our-first-containers.jpg)

---

## Objectifs

À la fin de cette leçon, vous aurez:

 * vu Docker en action;

 * démarré vos premiers conteneurs.

---

## Hello World

Depuis votre environnement Docker, lancez juste la commande suivante:

```bash
$ docker run busybox echo hello world
hello world
```

(Si votre installation Docker est vierge, quelques lignes en plus s'afficheront,
correspondant au téléchargement de l'image `busybox`.)

---

## C'était notre premier conteneur!

* Nous avons utilisé l'une des images les plus petites et simples: `busybox`.

* `busybox` est typiquement utilisée dans les systèmes embarqués (téléphones, routeurs, etc.)

* Nous avons lancé un seul processus pour afficher `hello world`.

---

## Un conteneur plus utile

Lançons un conteneur un peu plus excitant:

```bash
$ docker run -it ubuntu
root@04c0bb0a6c07:/#
```

* C'est un conteneur tout neuf.

* Il exécute un système `ubuntu` basique et sans fioritures.

* `-it` est le raccourci pour `-i -it`.

  * `-i` dit à Docker de nous connecter à l'entrée du conteneur.

  * `-t` dit à Docker que nous voulons un pseudo-terminal.

---

## Faire quelque chose dans notre conteneur

Essayez de lancer `figlet` dans notre conteneur.

```bash
root@04c0bb0a6c07:/# figlet hello
bash: figlet: command not found
```

D'accord, donc nous allons devoir l'installer.

---

## Installer un paquet dans notre conteneur

Nous voulons `figlet`, alors installons-le:

```bash
root@04c0bb0a6c07:/# apt-get update
...
Fetched 1514 kB in 14s (103 kB/s)
Reading package lists... Done
root@04c0bb0a6c07:/# apt-get install figlet
Reading package lists... Done
...
```

Une minute plus tard, `figlet` est installé!

---

## Essayons de lancer notre programme fraichement installé

Le programme `figlet` prend un message en paramètre.

```bash
root@04c0bb0a6c07:/# figlet hello
 _          _ _       
| |__   ___| | | ___  
| '_ \ / _ \ | |/ _ \ 
| | | |  __/ | | (_) |
|_| |_|\___|_|_|\___/ 
```

Magnifique! .emoji[😍]

---

class: in-person

## Compter les paquets dans le conteneur

Vérifions maintenant combien de paquets y sont installés.

```bash
root@04c0bb0a6c07:/# dpkg -l | wc -l
190
```

* `dpkg -l` liste les paquets installés dans notre conteneur

* `wc -l` va les compter

Combien de paquets avons-nous sur notre hôte?

---

class: in-person

## Compter les paquets sur l'hôte?

Quittez le conteneur en vous déconnectant du shell, comme d'habitude.

(i.e. avec `^D` ou `exit`)

```bash
root@04c0bb0a6c07:/# exit
```

Maintenant, essayons de:

* lancer `dpkg -l | wc -l`. Combien de paquets sont installés?

* lancer `figlet`. Est-ce que ça marche?

---

class: self-paced

## Comparaison du conteneur et de l'hôte

Sortez le conteneur en vous déconnectant du _shell_, avec `^D` ou `exit`.

Maintenant essayez de lancer `figlet`. Est-ce que ça marche?

(Cela ne devrait pas; sauf si, pas coïncidence, vous utilisez une machine où figlet était déjà installé.)

---

## Hôte et conteneurs sont deux systèmes indépendants

* Nous avons lancé un conteneur `ubuntu` sur un hôte Linux/Windows/macOS.

* Ils possèdent des paquets indépendants et différents.

* Installer quelque chose sur l'hôte ne l'expose pas dans le conteneur.

* Et vice-versa.

* Même si l'hôte et le conteneur ont tous deux la même distribution Linux.

* Nous pouvons lancer *n'importe quel conteneur* sur *n'importe quel hôte*.

  (Une exception: les conteneurs Windows ne peuvent tourner sur les machines Linux; par encore en tout cas.)

---

## Où est notre conteneur?

* Notre conteneur est maintenant en état *stopped*.

* Il existe encore sur le disque, mais toute ses ressources ont été libérées.

* Nous verrons plus tard comment récupérer ce conteneur.

---

## Démarrer un autre conteneur

Et si nous démarrions un nouveau conteneur, pour y lancer à nouveau `figlet`?
```bash
$ docker run -it ubuntu
root@b13c164401fb:/# figlet
bash: figlet: command not found
```

* Nous avons lancé un *tout nouveau conteneur*.

* Dans l'image de base Ubuntu utilisé ci-dessus, `figlet` est absent.

* Nous verrons dans les chapitres suivants comment préparer une image personnalisée avec `figlet`.
