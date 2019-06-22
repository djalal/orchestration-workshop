
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

* `-it` est le raccourci pour `-i -t`.

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

* Il existe encore sur le disque, mais toutes ses ressources ont été libérées.

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

* Dans l'image de base Ubuntu utilisée ci-dessus, `figlet` est absent.

---

## Où est mon conteneur?

* Pouvons nous réutiliser ce conteneur que nous avons pris le soin de personnaliser?

  *On pourrait, mais ce n'est pas le mode de production par défaut avec Docker.*

* Quel est le processus général, alos?

  *Toujours démarrer avec un conteneur tout nouveau.*
  <br/>
  *Si on a besoin d'installer quoique ce soit dans notre conteneur, générer une nouvelle image.*

* Ça a l'air compliqué!

  *Nous allons voir que c'est en fait assez simple!*

* Et tout ça pour quoi?

  *Tout ça pour appuyer sur l'automatisation et la répétabilité. Voyons voir pourquoi ...*

---

## Animaux de compagnie et bétail

* Dans la métaphore *"pets vs cattle"*, il existe deux genres de serveurs.

* Les animaux de compagnie (*Pets*):

  * ont un petit nom et une configuration unique

  * quand ils défaillent, on fait tout ce qu'on peut pour les soigner.

* Le bétail (*Cattle*):

  * ont des noms génériques (par ex. contenant des numéros) et une configuration générique

  * leur configuration est générée par une couche de gestion de configuration, et des templates ...

  * quand une panne advient, on peut les remplacer immédiatement par un nouveau serveur

* Quelle est la relation avec Docker et les conteneurs?

---

## Environnement de développement locaux

* Avec l'usage de VMs locales (comme par ex. Virtualbox ou VMware), notre flux de travail ressemble à ce qui suit:

  * créer une VM à partir d'un gabarit de base (Ubuntu, CentOS...)

  * installer les paquets, configurer l'environnement

  * travail sur le projet en tant que tel

  * finalement, éteindre la VM

  * la prochaine fois qu'on aborde ce projet, redémarrer la VM dans l'état où on l'a laissée

  * si on a besoin de retoucher l'environnement, on le fait en direct.

* Au fil du temps, la configuration de la VM évolue et diverge.

* Il nous manque une procédure propre, fiable et déterministe de provisionner cet environnement.

---

## Développement local avec Docker

* Avec Docker, la démarche est la suivante:

  * créer une image de conteneur représentant notre environnement de dév.

  * lancer un conteneur basé sur cette image

  * travailler sur notre projet proprement dit

  * finalement, stopper le conteneur

  * la prochaine fois qu'on aborde le projet, démarrer un nouveau contneeur

  * en cas de changement de l'environnement, on créé une nouvelle image.

* Nous avons une définition claire de notre environnement, qu'on peut partager de manière fiable avec les autres.

* Nous verrons dans les chapitres suivants comment préparer une image personnalisée avec `figlet`.

