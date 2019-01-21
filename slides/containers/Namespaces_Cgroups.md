# Plongée dans les entrailles des conteneurs

Dans ce chapitre, nous expliquerons certaines des briques fondatrices des conteneurs.

Cela vous donnera une solide assise pour pouvoir:

 - comprendre "ce qui se passe" dans certaines situations complexes,

 - anticiper le comportement de conteneurs (performance, sécurité, ...) dans de nouveaux scenari,

 - implémenter votre propre moteur de conteneur.

Ce dernier point est à but éducatif seulement!

---

## Pas de code de conteneur dans le noyau Linux

- Si on cherche _"container"_ dans le code du noyau Linux, on trouve:

  - du code générique pour manipuler les structures de données (comme des listes liées, etc.),

  - des concepts étrangers comme les "conteneurs ACPI",

  - *rien* qui concerne "nos" conteneurs!

- Un conteneur est un assemblage de plusieurs fonctionnalités indépendantes.

- Sur Linux, les conteneurs se basent sur les "namespaces, cgroups et de la magie de système de fichiers".

- Leur sécurité requiert par ailleurs d'autres fonctions telles que les _capabilities_, seccomp, les LSMs, etc.

---

# Espaces de nommage

- Fournissent aux processus leur propre vue du système.

- Un _namespace_ limite ce qui est visible (et donc, ce qui est utilisable).

- Tous ces _namespaces_ sont disponibles dans les noyaux modernes:

  - pid
  - net
  - mnt
  - uts
  - ipc
  - user

  (Nous allons les détailler un par un.)

- Chaque processus appartient à un _namespace_ de chaque type.

---

## Il existe toujours des _Namespaces_

- Les espaces de nommage sont actifs même hors des conteneurs.

- C'est un peu similaire au champ UID dans les processus UNIX:

  - tous les processus ont un champ UID, même si aucun utilisateur n'existe dans le système

  - ce champ a toujours une valeur / sa valeur est toujours définie
    <br/>
    (i.e. tout processus exécuté sur le système a un certain UID)

  - la valeur du champ UID est utile au moment de vérifier les permissions
    <br/>
    (le champ UID détermine à quelle ressource le processus peut accéder)

- Si on remplace "champ UID" par _"namespace"_ ci-dessus, tout est vrai!

- En d'autres termes: même quand vous n'utilisez pas de conteneurs,
  <br/>il existe un _namespace_ de chaque type, contenant tous les processus du système.

---

class: extra-details, deep-dive

## Manipuler les _namespaces_

- On crée un _namespace_ avec deux méthodes:

  - l'appel système `clone()` (utilisé lors de la création de nouveaux _threads_ et processus)

  - l'appel système `unshare()`.

- La comande Linux `unshare` permet de faire ça depuis un terminal.

- Un nouveau processus peut recycler tout ou partie des _namespaces_ de son parent.

- Il est possible de "pénétrer" dans un _namespace_ avec l'appel système `setns()`.

- La commande `nsenter` permet cette opération depuis un terminal.

---

class: extra-details, deep-dive

## Cycle de vie des _namespaces_

- Quand le dernier processus d'un espace de nommage s'arrête, ce dernier est détruit.

- Toutes les ressources associées sont alors supprimées.

- Les _namespaces_ sont matérialisés par des pseudo-fichiers dans `/proc/<pid>/ns`.

  ```bash
  ls -l /proc/self/ns
  ```

- Il est possible de comparer les _namespaces_ en vérifiant ces fichiers.

  (Cela peut aider à répondre à la question, "est-ce que ces deux processus sont dans le même _namespace_?")

- Il est possible de préserver un _namespace_ via un point de montage de son pseudo-fichier.

---

class: extra-details, deep-dive

## Utiliser les espaces de nommage indépendamment

- Comme mentionné plus haut:

  *Un nouveau processus peut recycler tout ou partie des _namespaces_ de son parent.*

- Nous allons exploiter cette propriété dans les exemples des diapos suivantes.

- Nous allons présenter chaque type de _namespace_.

- Pour chaque type, nous fournirons un exemple exploitant seulement ce _namespace_.

---

## _Namespace_ UTS

- gethostname / sethostname

- Permet de configurer un nom d'hôte spécifique pour un conteneur.

- C'est (à peu près) tout!

- Permet aussi de changer le domaine NIS.

  (si vous ne savez pas ce qu'est un domaine NIS, vous n'avez pas à vous en faire!)

- Au cas où vous vous poseriez la question: UTS = Unix time sharing.

- Ce type de _namespace_ tire son nom du code `struct utsname`,
  <br/>
  couramment utilisé pour obtenir d'une machine son nom, architecture, etc.

  (Plus on en apprend!)

---

class: extra-details, deep-dive

## Créer notre premier espace de nommage

Lançons la commande `unshare` pour créer un nouveau processus
qui aura son propre _namespace_ UTS:

```bash
$ sudo unshare --uts
```

- `sudo` est obligatoire pour la plupart des commandes `unshare`.

- On indique qu'on souhaite un nouveau _namespace_ UTS, et rien d'autre.

- si on ne précise pas de programme à lancer, un `$SHELL` est démarré.

---

class: extra-details, deep-dive

## Démonstration de notre _namespace_ UTS

Dans notre nouveau conteneur, vérifiez le nom d'hôte, changez le et vérifiez:

```bash
 # hostname
 nodeX
 # hostname tupperware
 # hostname
 tupperware
```

Dans un autre terminal, vérifiez que la machine principale a gardé son nom d'origine:

```bash
$ hostname
nodeX
```

Sortez du "conteneur" avec `exit` ou `Ctrl-D`.

---

## Aperçu général du _namespace_ Net

- Chaque _namespace_ de réseau possède sa propre pile réseau privée.

- On trouve dans cette pile réseau:

  - des interfaces réseau (y compris `lo`),

  - **des** tables de routage (comme sur `ip rule`, etc.)

  - des règles et chaines iptables

  - des sockets (comme sur `ss`, `netstat`).

- On peut déplacer une interface réseau d'un _namespace_ réseau à un autre:
  ```bash
  ip link set dev eth0 netns PID
  ```

---

## Usage typique du _namespace_ Net

- Chaque conteneur dispose de son propre espace de nommage réseau.

- Pour chacun de ces _namespaces_ réseau (i.e chaque conteneur), une paire de `veth` est créée.

  (Deux interfaces `veth` agissent comme si elle étaient connectées par un cable croisé.)

- Un `veth` est placé sur le _namespace_ réseau du conteneur (et nommé `eth0`).

- L'autre `veth` est placé sur un _bridge_ de l'hôte (par ex. le _bridge_ `docker0`).

---

class: extra-details

## Créer un _namespace_ réseau

Démarrons un nouveau processus dans son propre _namespace_ de type réseau:

```bash
$ sudo unshare --net
```

Constatons que ce _namespace_ réseau n'est pas configuré:

```bash
 # ping 1.1
 connect: Network is unreachable
 # ifconfig
 # ip link ls
 1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

---

class: extra-details

## Créer les interfaces `veth`

Dans un autre shell (sur l'hôte), créons une paire de `veth`:

```bash
$ sudo ip link add name in_host type veth peer name in_netns
```

Configurons la partie hôte (`in_host`):

```bash
$ sudo ip link set in_host master docker0 up
```

---

class: extra-details

## Déplacer l'interface `veth`

*Dans le processus créé par `unshare`*, vérifier le PID de notre "conteneur réseau":

```bash
 # echo $$
 533
```

*Sur l'hôte*, déplacer l'autre côté (`in_netns`) vers le _namespace_ réseau:

```bash
$ sudo ip link set in_netns netns 533
```

(Attention à bien remplacer "533" avec le PID réel obtenu précédemment!)

---

class: extra-details

## Configuration réseau basique

Installons `lo` (l'interface loopback):

```bash
 # ip link set lo up
```

Activons l'interface `veth` pour la renommer en `eth0`:

```bash
 # ip link set in_netns name eth0 up
```

---

class: extra-details

## Allouer l'adresse IP et la route par défaut

*Sur l'hôte*, vérifions l'adresse du _bridge_ Docker:

```bash
$ ip addr ls dev docker0
```

(Ça ressemblerait à quelque chose comme `172.17.0.1`.)

Choisissons une adresse IP dans le même sous-réseau, comme `172.17.0.99`.

*A l'intérieur du processus créé par `unshare`,* configurons l'interface:

```bash
 # ip addr add 172.17.0.99/24 dev eth0
 # ip route add default via 172.17.0.1
```

(Attention à indiquer les bonnes adresses IP si elles diffèrent.)

---

class: extra-details

## Valider l'installation

Vérifions que nous avons maintenant un accès réseau:

```bash
 # ping 1.1
```

Note: nous avons pu prendre un raccourci, car Docker tourne,
et nous fournit une passerelle `docker0` et un environnement `iptables` valide.

Si Docker n'était pas là, on aurait dû s'occuper de ça aussi!

---

class: extra-details

## Nettoyer les _namespaces_ réseau

- Arrêtez le processus créé par `unshare` (avec `exit` ou `Ctrl-D`).

- Puisque c'était le dernier processus dans l'espace de nommage réseau, ce dernier est détruit.

- Toutes les interfaces de cet espace de nommage sont aussi détruites.

- Quand une interface `veth` est détruite, elle supprime aussi son autre moitié.

- Ainsi nous n'avons plus rien d'autre à nettoyer!

---

## Autres cas d'usage des _namespaces_ réseau

- `--net none` crée un _namespace_ réseau vide pour un conteneur.

  (le rendant complètement isolé du réseau.)

- `--net host` se traduit par "ne pas conteneurisé le réseau".

  (Aucun _namespace_ réseau n'est créé; le conteneur utilise la pile réseau de l'hôte.)

- `--net container` signifie "réutilise le _namespace_ réseau d'un autre conteneur".

  (Il en résulte que les deux conteneurs partagent les mêmes interfaces, routes, etc.)

---

## _Namespace_ "Mnt"

- Les processus peuvent avoir leur propre racine de système de fichiers (à la chroot).

- Les processus peuvent avoir leurs propres montages "privés". Cela permet:

  - d'isoler `/tmp` (par utilisateur, par service, etc.)

  - de masquer `/proc`, `/sys` (pour les processus qui n'en veulent pas)

  - de monter des systèmes de fichier distants ou des données sensibles
    <br/>et les exposer uniquement aux processus autorisés

- Les points de montage peuvent être totalement privés, ou partagés.

- A ce jour, il n'existe pas de moyen simple de transmettre un montage
  depuis un _namespace_ à un autre.

---

class: extra-details, deep-dive

## Configurer un `/tmp` privé

Créer un nouveau _namespace_ de montage:

```bash
$ sudo unshare --mount
```

Dans ce nouveau _namespace_, monter un tout nouveau `/tmp`:

```bash
 # mount -t tmpfs none /tmp
```

Vérifier le contenu de `/tmp` dans le nouveau _namespace_, et le comparer à l'hôte.

Le montage est automatiquement supprimé quand vous quittez le processus.

---

## _Namespace_ PID

- Les processus à l'intérieur d'un _namespace_ PID ne peuvent "voir" que les processus dans le même espace de nommage PID.

- Chaque _namespace_ PID possède son propre compteur (démarrant à 1).

- Quand le PID 1 s'arrête, le _namespace_ complet disparaît.

  (Sur un système UNIX classique, l'arrêt du PID 1 provoque une panique du noyau!)

- Ces _namespaces_ peuvent être imbriqués les uns dans les autres.

- Au final, un processus aura plusieurs PIDs (un par _namespace_ où il est imbriqué).

---

class: extra-details, deep-dive

## Espace de nommage PID en action

Créer un nouveau _namespace_ PID:

```bash
$ sudo unshare --pid --fork
```

(On doit ajouter l'option `--fork` car le _namespace_ PID est spécial.)

Vérifier l'arborescence du processus dans le nouveau _namespace_:

```bash
 # ps faux
```

--

class: extra-details, deep-dive

🤔 Mais pourquoi on voit tous les processus alors ?!?

---

class: extra-details, deep-dive

## _Namespace_ PID et `/proc`

- Les commandes comme `ps` se basent sur le pseudo-dossier `/proc`.

- Notre _namespace_ a toujours accès au `/proc` original.

- Par conséquent, il voit tous les processus de l'hôte.

- Mais il ne peut pas y toucher.

  (Essayez de `kill` un processus et vous aurez `No such process`.)

---

class: extra-details, deep-dive

## Espace de nommage PID, deuxième prise

- On peut résoudre ce point en montant `/proc` dans le _namespace_.

- La commande `unshare` fournit une option `--mount-proc` bien pratique.

- Cette option va monter `/proc` dans le _namespace_.

- Il va aussi départager le _namespace_ de montage, pour qu'il soit uniquement local.

Essayez par vous-même:

```bash
 $ sudo unshare --pid --fork --mount-proc
 # ps faux
```

---

class: extra-details

## Bon, franchement, à quoi sert `--fork`?

*Il n'est pas nécessaire de se rappeler de tous ces détails.
<br/>
C'est juste une illustration de la complexité des* namespaces *!*

`unshare` lance un appel système `unshare()`, puis `exec` le nouveau binaire.
<br/>
Un processus appelant `unshare` pour créer de nouveaux _namespaces_ est placé dans ces _namespaces_... excepté pour le _namespace_ PID.
<br/>
(car cela changerait le PID du processus en cours de X à 1.)


Les processus créés par le nouveau binaire sont placés dans le nouveau _namespace_ PID.
<br/>
Le premier aura le PID 1.
<br/>
Si le PID 1 quitte, impossible de lancer de nouveaux processus dans ce _namespace_.
<br/>
(Toute tentative renverra l'erreur `ENOMEM`.)

Sans l'option `--fork`, la première commande à s'exétuer aura le PID 1 ...
<br/>
... et une fois qu'elle quitte, on ne pourra plus créer de processus dans ce _namespace_!

Pour plus de détails, vous pouvez consulter `man 2 unshare` et `man pid_namespaces`.

---

## _Namespace_ IPC

--

- Qui a déjà travaillé sur IPC?

--

- Qui se *soucie* d'IPC?

--

- Permet à un processus (ou un groupe) d'avoir leur propre:

  - sémaphores IPC
  - file d'attente IPC
  - mémoire partagée IPC

  ... sans risque de conflit avec les autres instances.

- Les anciennes versions de PostgreSQL l'utilisaient.

*Pas de démo pour celui-ci.*

---

## _Namespace_ user

- Permet des correspondances sur UID/GID, comme par ex.:

  - UID 0→1999 du conteneur C1 correspond à UID 10000→11999 sur l'hôte
  - UID 0→1999 in conteneur C2 correspond à UID 12000→13999 sur l'hôte
  - etc.

- L'UID 0 du conteneur peut quand même y mener des opérations privilégiées.

  (Par exemple: configurer les interfaces réseau.)

- Mais en dehors du conteneur, il n'est qu'un utilisateur non-privilégié.

- Cela veut aussi dire que l'UID dans les conteneurs devient moins important.

  (Prenez juste l'UID 0 du conteneur, car il sera rétrogradé en utilisateur
  lambda en dehors.)

- Rend finalement possible une meilleure séparation des privilèges dans les moteurs de conteneurs.

---

class: extra-details, deep-dive

## Défis des _namespace_ d'utilisateur

- L'UID doit être déjà associé au moment d'être transféré entre processus ou sous-systèmes du noyau.

- Les permissions du système de fichiers et la propriété de fichiers sont plus compliqués.

  .small[(Par ex. quand le même système de fichiers racine est partagé entre plusieurs conteneurs avec différents UIDs.)]

- Avec le Docker Engine:

  - certaines combinaisons ne sont pas autorisées.
    <br/>
    (par ex. _namespace_ utilisateur + partage du _namespace_ réseau de l'hôte)

  - les _namespaces_ utilisateur doivent être activés/désactivés globalement
    <br/>
    (au moment de démarrer le démon)

  - les images de conteneur sont stockées séparément.
    <br/>
    (donc la première fois que vous activez les _namespaces_ utilisateur, vous devez re-pull toutes les images.)

*Pas de démo pour celui-ci.*

---

# Groupes de contrôle

- Les groupes de contrôle s'occupent de *mesurer* et *limiter* les ressources.

- Cela couvre un certain nombre de "suspects habituels", tels que:

  - mémoire

  - CPU

  - block I/O

  - réseau (avec la coopération de tc/iptables)

- Et quelques autres exotiques:

  - _huge pages_ (une façon spéciale d'allouer la mémoire)

  - RDMA (ressources spécifiques à InfiniBand / transfert de mémoire distante)

---

## Contrôle de foules

- Les groupes de contrôle permettent aussi des opérations spéciales aux groupes de processus:

  - freezer (concept similaire à un "mass-SIGSTOP/SIGCONT")

  - perf_event (collecte les événements de performance sur plusieurs processus)

  - cpuset (limite ou épingle les processus à des CPUs spécifiques)

- Il y a un _cgroup_ "pids" qui limite le nombre de processus d'un groupe donné.

- IL y aussi un _cgroup_ "devices" pour contrôler les accès aux noeuds de périphériques.

  (i.e. tout ce qui est dans `/dev`.)

---

## Généralités

- Les _cgroups_ forment une hiérarchie (un arbre).

- Nous pouvons créer des noeuds dans cette hiérarchie.

- Nous pouvons associer des limites à un noeud.

- Le (ou les) processus vont ensuite respecter ces limites.

- On peut vérifier l'usage courant de chaque noeud.

- En d'autres mots: les limites sont optionnelles (si on veut juste la comptabilité).

- Quand un processus est créé, il est placé dans les groupes de son parent.

---

## Exemple

Les nombres sont des PIDs.

Les noms sont les noms des noeuds (choisi arbitrairement).

.small[
```bash
cpu                      memory
├── batch                ├── stateless
│   ├── cryptoscam       │   ├── 25
│   │   └── 52           │   ├── 26
│   └── ffmpeg           │   ├── 27
│       ├── 109          │   ├── 52
│       └── 88           │   ├── 109
└── realtime             │   └── 88
    ├── nginx            └── databases
    │   ├── 25               ├── 1008
    │   ├── 26               └── 524
    │   └── 27
    ├── postgres
    │   └── 524
    └── redis
        └── 1008
```
]

---

class: extra-details, deep-dive

## _Cgroups_ v1 contre v2

- Les _Cgroups_ v1 sont disponibles sur tous les systèmes (et amplement utilisé).

- Les _Cgroups_ v2 sont une grosse ré-écriture.

  (Développement commencé dans Linux 3.10, publié en 4.5.)

- Les _Cgroups_ v2 ont un nombre de différences:

  - hiérarchie unique (au lieu d'un arbre par contrôleur),

  - les processus peuvent juste être des noeuds finaux (les feuilles, pas de noeuds internes),

  - et bien sûr de nombreuses améliorations / correctifs.

---

## _cgroup_ mémoire: comptabilité

- Suivi des pages utilisées par chaque groupe:

  - fichier (lire/écriture/mmap des blocs de périphériques),
  - anonyme (pile, _heap_, mmap anonyme),
  - actif (récemment accédé),
  - inactif (candidat à l'éviction).

- Chaque page est "facturé" à un groupe.

- Les pages peuvent être partagées à travers plusieurs groupes.

  (Exemple: plusieurs processus lisant les mêmes fichiers.)

- Pour voir les compteurs conservés par ce _cgroup_:

  ```bash
  $ cat /sys/fs/cgroup/memory/memory.stat
  ```

---

## _cgroup_ mémoire: limites

- Chaque groupe peut avoir (en option) des limites _hard_ et _soft_.

- Des limites peuvent être placées pour différents types de mémoire:

  - mémoire physique,

  - mémoire du noyau,

  - mémoire totale (swap y compris).

---

## Limites _soft_ et _hard_

- Les limites _soft_ ne sont pas appliquées.

  (mais elles influencent la récupération sous la pression de mémoire.)

- Les limites _hards_ ne peuvent **pas** être dépassées:

  - si un groupe de processus dépasse une limite _hard_,

  - et si le noyau ne peut pas récupérér la mémoire,

  - alors le _killer_ OOM (out-of-memory) est déclenché,

  - et les processus sont tués jusqu'à ce que la mémoire passe sous la limite à nouveau.

---

class: extra-details, deep-dive

## Éviter le _killer_ OOM

- Pour certaines taches (bases de données et services à données persistentes),
  tuer les processus à cause d'un manque de mémoire n'est pas acceptable.

- Le mécanisme "oom-notifier" peut nous aider à ce sujet.

- Quand "oom-notifier" est activé et qu'une limite _hard_ est dépassée:

  - tous les processus de ce _cgroup_ sont gelés,

  - une notification est envoyée à l'espace utilisateur (au lieu de supprimer les processus),

  - une fois que la mémoire s'est rétablie sous la limite _hard_, il dégèle le _cgroup_.

---

class: extra-details, deep-dive

## Surcharge du _cgroup_ mémoire

- Chaque fois qu'un processus réserve ou libère une page, le noyau met à jour les compteurs.

- Cela ajoute un délai supplémentaire.

- Hélas, on ne peut pas l'activer/désactiver par processus.

- C'est une configuration au niveau du système, effectuée au démarrage.

- De même, quand plusieurs groupes utilisent la même page:

  - seul le premier groupe est "facturé",

  - mais s'il arrête de l'utiliser, la "facture" est déplacée sur un autre groupe.

---

class: extra-details, deep-dive

## Placer une limite sur le _cgroup_ "mémoire"

Créer un nouveau _cgroup_ mémoire:

```bash
$ CG=/sys/fs/cgroup/memory/onehundredmegs
$ sudo mkdir $CG
```

Le limiter à approximativement 100Mo d'usage mémoire:

```bash
$ sudo tee $CG/memory.memsw.limit_in_bytes <<< 100000000
```

Déplacer le processus en cours dans ce _cgroup_:

```bash
$ sudo tee $CG/tasks <<< $$
```

Le processus en cours *et tous ses futurs enfants* sont maintenant limités.

(Troublé(e) par `<<<`? On en parle dans la diapo suivante!)

---

class: extra-details, deep-dive

## Qu'est-ce que `<<<`?

- C'est une _"here string_". (C'est une extension du _shell_ non-POSIX.)

- Les commandes suivantes sont équivalentes:

  ```bash
  foo <<< hello
  ```

  ```bash
  echo hello | foo
  ```

  ```bash
  foo <<EOF
  hello
  EOF
  ```

- Pourquoi l'utiliser ici?

---

class: extra-details, deep-dive

## Écrire dans les pseudo-ficheirs _cgroups_ exige d'être _"root"_

Au lieu de:

```bash
sudo tee $CG/tasks <<< $$
```

On aurait pu écrire:

```bash
sudo sh -c "echo $$ > $CG/tasks"
```

Les commandes suivantes, toutefois, auraient été invalides:

```bash
sudo echo $$ > $CG/tasks
```

```bash
sudo -i # (or su)
echo $$ > $CG/tasks
```

---

class: extra-details, deep-dive

## Tester la limite mémoire

Démarrer l'interpréteur Python:

```bash
$ python
Python 3.6.4 (default, Jan  5 2018, 02:35:40)
[GCC 7.2.1 20171224] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

Allouer 80 méga-octets:

```python
>>> s = "!" * 1000000 * 80
```

Ajouter 20 méga-octets:

```python
>>> t = "!" * 1000000 * 20
Killed
```

---

## _cgroup_ CPU

- Comptabilise le temps CPU utilisé par un groupe de processus.

  (C'est plus facile et précis que `getrusage` et `/proc`.)

- Trace de la même manière l'usage par CPU.

  (ie. "ce groups de processus a utilisé X secondes du CPU0 et Y secs. du CPU1".)

- Autorise la configuration de facteurs de pondération à l'usage de l'ordonnanceur.

---

## _cgroup_ Cpuset

- Épingle des groupes à certains CPU(s).

- Cas d'usage: réserver des CPUs pour des applications spécifiques.

- Avertissement: assurez-vous que les processus par défaut n'utilisent pas tous les CPUs!

- Épingler un CPU peut éviter les pertes de performance dûes au vidage de cache.

- Cela concerne aussi les systèmes NUMA.

- Fournit des boutons et manettes supplémentaires.

  (pression mémoire par zone, coûts de migration des processus...)

---

## _cgroup_ Blkio

- Opère le suivi des E/S pour chaque groupe:

  - par bloc de périphérique
  - lecture vs écriture
  - synchrone vs asynchrone

- Placer des régulateurs (limites) pour chaque groupe:

  - par bloc de périphérique
  - lecture vs écriture
  - opérations vs octets

- Indiquer des pondérations relatives pour chaque groupe.

- Note: la plupart des écritures passent par le cache de page.
  <br/>(Donc les écritures classiques apparaîtront d'abord comme non régulées.)

---

## _cgroup_ Net_cls et net_prio

- Fonctionne uniquement pour le trafic _egress_ (sortant).

- Règle automatiquement la classe ou priorité du trafic pour le
  trafic généré par les processus dans le groupe.

- Net_cls va assigner un trafic à une classe.

- Les classes doivent correspondre à celles dans tc ou iptables, ou bien tout se passera comme si le trafic n'était pas limité.

- Net_prio va assigner une priorité au trafic.

- Les priorités sont utilisées par les _queuing disciplines_ (cf. QoS)

---

## _cgroup_ de périphériques

- Contrôle ce que le groupe peut faire sur les noeuds de périphérique.

- On retrouve des permissions de type read/write/mknod.

- Usage typique:

  - autoriser `/dev/{tty,zero,random,null}` ...
  - interdire tout le reste

- Quelques noeuds intéressants:

  - `/dev/net/tun` (manipulation de l'interface réseau)
  - `/dev/fuse` (systèmes de fichiers dans pour utilisateur simple)
  - `/dev/kvm` (des VMs dans des conteneurs, chouette l'inception!)
  - `/dev/dri` (GPU)

---

# Fonctions de sécurité

- Espaces de nommage et _cgroups_ ne sont pas suffisants pour garantir une sécurité forte.

- Nous avons besoin de mécanismes supplémentaires: capacités, seccomps, LSMs.

- Ces mécanismes étaient déjà utilisés avant les conteneurs pour renforcer la sécurité.

- Ils peuvent être combinés aux conteneurs.

- De bons moteurs de conteneurs vont automatiquement exploiter ces fonctions.

  (Pour que vous n'ayez pas à vous en inquiéter.)

---

## Capacités

- En UNIX standard, bien des opérations sont possibles si et seulement si UID=0 (root).

- Quelques unes des opérations sont très puissantes:

  - changer la propriété des fichiers, accéder à tout fichier ...

- Parmi ces opérations, certaines traitent de la config. système, mais peuvent être abusées:

  - installer des interfaces réseau, monter des systèmes de fichier ...

- Certaines de ces opérations ne sont pas dangereuses en soi, mais requises par les serveurs:

  - ouvrir un port inférieur à 1024.

- Les capacités sont des options réglables par processus pour permettre ces opérations individuellement.

---

## Quelques capacités

- `CAP_CHOWN`: pour changer arbitrairement le propriétaire de fichiers et leurs permissions.

- `CAP_DAC_OVERRIDE`: contourne arbitrairement les accès et propriétaire de fichiers.

- `CAP_NET_ADMIN`: autorise la configuration d'interface réseau, de règles iptables, etc.

- `CAP_NET_BIND_SERVICE`: pour réserver un port inférieur à 1024.

Voir `man capabilities` pour une liste complète et détaillée.

---

## Usage des capacités

- Les moteurs de conteneurs vont typiquement bloquer toute capacité "dangereuse".

- Vous pouvez les ré-activer selon le conteneur, selon les besoins.

- Avec le Docker Engine: `docker run --cap-add ...`

- Si vous écrivez votre propre code pour gérer les capacités:

  - assurez-vous de comprendre ce que fait chaque capacité;

  - informez-vous aussi sur les capacités *ambiantes*.

---

## Seccomp

- Seccomp signifie _"secure computing"_.

- On obtient un haut niveau de sécurité via une restriction drastique des appels système possibles.

- Le seccomp de base autorise uniquement `read()`, `write()`, `exit()`, `sigreturn()`.

- L'extension seccomp-bpf permet de spécifier des filtres spéciaux via des règles BPF.

- Cela se traduit par un filtre sur les appels système, et leurs paramètres.

- Du code BPF est capable d'exécuter des vérifications complexes, rapidement et en sécurité.

- Les moteurs de conteneurs s'occupent de cet aspect pour que vous n'ayez pas à le faire.

---

## Modules de Sécurité Linux

- Les plus populaires sont SELinux et AppArmor.

- Les distros Red Hat embarquent généralement SELinux.

- Les distros Debian (dont Ubuntu) utilisent plutôt AppArmor.

- Les LSMs ajoutent une couche de contrôle d'accès à toutes les opérations sur processus.

- Les moteurs de conteneurs s'occupent de cet aspect pour que vous n'ayez pas à le faire.
