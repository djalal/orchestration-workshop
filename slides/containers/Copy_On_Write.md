# Système de fichiers "Copy-on-write"

Les moteurs de conteneurs s'appuient sur _copy-on-write_
pour pouvoir lancer des conteneurs rapidement,
peut importe leur taille.

Nous allons expliquer comment cela fonctionne, et
passer en revue quelques systèmes de stockage _copy-on-write_
disponibles sur Linux.

---

## Qu'est-ce que _copy-on-write_?


- _Copy-on-write_ est un mécanisme permettant le partage de données.

- Les données semblent être une copie, mais sont juste en réalité un lien
(ou référence) à l'original.

- La copie véritable se fait uniquement quand
quelqu'un/quelque chose change les données partagées.

- Quiconque change les données partagées ne fait que
mettre à jour son propre exemplaire des données partagées.

---

## Quelques métaphores
--

- Première métaphore:
  <br/>tableau blanc et papier calque

--

- Deuxième métaphore:
  <br/>livres de magie et pages secrètes

--

- Troisième métaphore:
  <br/>construction de maison en flux tendu (_just-in-time_)

---

## _Copy-on-write_ est **partout**

- Création de processus avec `fork()`.

- _Snapshot_ de disque cohérent.

- Génération de VM efficace

- Et, bien sûr, les conteneurs.

---

## _Copy-on-write_ et conteneurs

_Copy-on-write_ est essentiel pour rendre "pratiques" les conteneurs.

- Créer un nouveau conteneur (d'une image existante) est "gratuit".

  (Sans cela, nous devrions d'abord copier l'image en entier.)

- Mettre à jour un conteneur (en modifiant quelques fichiers) est bon marché.

  (Ajouter une configuration de 1Ko à un conteneur de 1Go prend 1Ko, pas 1Go.)

- On peut prendre des _snapshots_, i.e avoir des points de restauration, lors
de la génération d'images.

---

## Aperçu d'AUFS

- C'est le système originel (legacy) du _copy-on-write_ utilisé dans les premières versions de Docker.

- Il combine plusieurs *branches* dans un ordre spécifique.

- Chaque branche est juste un dossier normal.

- On a généralement:

  - au moins une branche en lecture seule (tout en bas);

  - exactement une seule branche en lecture/écriture (tout en haut).

 (Mais d'autres combinaisons sympa sont aussi possibles!)

---

## Opérations sur AUFS: ouvrir un fichier

- Avec `O_RDONLY` - accès lecture seule:

  - parcourir chaque branche, partan du haut

  - ouvrir la première occurence trouvée

- Avec `O_WRONLY` ou `O_RDWR` - accès écriture :

  - si le fichier existe dans la branche supérieure: l'ouvrir

  - si le fichier existe dans une autre branche: _"copy up"_
    <br/>
    (i.e. copier le fichier dans la branche supérieure et ouvrir la copie)

  - si le fichier n'existe dans aucune branche: le créer dans la branche supérieure

Cette opération de _copy-up_ peut prendre un moment si le fichier est énorme!

---

## Opérations sur AUFS: supprimer un fichier

- Un fichier *Tipp-Ex* est créé.

- Ceci est similaire au concept de "pierres tombales" utilisées dans certains systèmes de données.

```
 # docker run ubuntu rm /etc/shadow

 # ls -la /var/lib/docker/aufs/diff/$(docker ps --no-trunc -lq)/etc
 total 8
 drwxr-xr-x 2 root root 4096 Jan 27 15:36 .
 drwxr-xr-x 5 root root 4096 Jan 27 15:36 ..
 -r--r--r-- 2 root root    0 Jan 27 15:36 .wh.shadow
```

---

## AUFS et performance


- `mount()` en AUFS est rapide, donc la création de conteneurs est rapide.

- Les accès en lecture/écriture ont une vitesse native.

- Mais les opérations `open()` sont coûteuses dans deux scénarii:

  - quand on écrit de gros fichiers (fichier logs, bases de données, etc.),

  - quand on cherche dans de nombreux dossier (PATH, classpath, etc.) à travers plusieurs couches.

- Astuce: quand on a lancé dotCloud, on a fini par mettre toutes les données
importantes dans des *volumes*.

- En lançant le même conteneur plusieurs fois:

  - la donnée est chargée une seule fois depuis le disque, et mise en cache une seul fois en mémoire;
  - mais les `dentries` seront dupliquées

---

## Device Mapper


_Device Mapper_ est un sous-système riche en fonctionnalités variées.

Il peut être utilisé pour: RAID, appareils cryptés, snapshots, et plus.

Dans le contexte de conteneurs (et Docker en particulier), "Device Mapper"
signifie:

"le système Device Mapper + son *thin provisioning target*"

Si vous voyez l'abréviation "thinp", il faut lire "thin provisioning".

---

## Principes de Device Mapper

- Copy-on-write agit au niveau du *bloc*, contrairement au niveau *fichier*

- Chaque conteneur et chaque image dispose de son propre descripteur de bloc.

- A tout moment, il est possible de prendre un _snapshot_:

  - d'un conteneur existant (pour créer une image)

  - d'une image existante (comme base d'un nouveau conteneur)

- Si un bloc n'a jamais reçu d'écriture:

  - on suppose qu'il est à zéro.

  - il n'est pas alloué sur le disque.

(Cette dernière propriété est l'explication du nom _"thin" provisioning_.)

---

## Détails opérationnels de Device Mapper

- Deux zones de stockage sont nécessaires:
  une pour la *donnée*, l'autre pour les *méta-données*.

- la "donnée", aussi appelée _"pool"_; qui est en fait un gros ensemble de blocs.

  (Docker utilise la plus petite taille de bloc possible, 64 Ko.)

- les "méta-données" contiennent le mappage entre l'adressage virtuel (dans les _snapshots_) et l'adressage physique (dans le _pool_).

- chaque fois qu'un nouveau bloc (ou un block _copy-on-write_) est écrit, un bloc
provenant du _pool_ lui est alloué.

- quand il n'y a plus aucun bloc dans le _pool_, les tentatives d'écriture vont
être suspendues jusqu'à ce que la taille du  _pool_ augmente (ou que l'opération d'écriture soit annulée).

- En d'autres termes: sans espace de stockage, les conteneurs sont gelés, mais
les opérations repartent dès que l'espace est à nouveau disponible.

---

## Device Mapper et performance

- Par défaut, Docker place les données et méta-données dans un *loop device*, stocké sur un *sparse file*.

- C'est super du point de vue utilisabilité, car ça demande zero configuration.

- Mais c'est moche du point de vue performance:

  - chaque fois qu'un conteneur écrit dans un nouveau bloc,
  - un bloc doit être alloué depuis le _pool_,
  - et quand on écrit dedans,
  - un bloc dans être alloué depuis le *sparse file*,
  - et la performance d'un *sparse file* n'est pas terrible du tout.

- Si vous utilisez Device Mapper, assurez-vous de placer les données (et méta-données) sur un périphérique (*device*)!

---

## Principes de BTRFS

- BTRFS est un système de fichiers (comme ext4, xfs, NTFS, etc.) avec un support natif des _snapshots_.

- Le "copy-on-write" est pris en charge au niveau du système de fichiers.

- BTRFS intègre les fonctions de _snapshot_ et gestion de _pool_ de blocs au niveau du système de fichiers.

  (au lieu du niveau de block pour Device Mapper)

- En pratique, on déclare un "sous-volume" et on en prend un _snapshot_ plus tard.

  Imaginez: `mkdir` avec des Super Pouvoirs et `cp -a` avec des Super Pouvoirs.

- Ces opérations peuvent être réalisées avec l'outil en ligne de commande `btrfs`

---

## BTRFS en pratique avec Docker

- Docker peut utiliser BTRFS et ses fonctions de _snapshot_ pour stocker les images de conteneur.

- Le seul pré-requis est que `/var/lib/docker` soit sur un système de fichiers BTRFS.

  (ou, le dossier spécifié avec l'option `--data-root` au démarrage du moteur Docker)

---

class: extra-details

## BTRFS et pièges

- BTRFS fonctionne en partagean sont stockage en fragments (*chunk*).

- Un fragment peut contenir soit des données ou des méta-données.

- On peut être à court de fragments (et avoir un `No space left on device`)
 même si `df` affiche de l'espace disponible.

 (Car les fragments sont partiellement alloués)

- Correctif:

```
 # btrfs filesys balance start -dusage=1 /var/lib/docker
```

---

## Overlay2

- Overlay2 est très similaire à AUFS.

- Sauf qu'il a été inclus dans le noyau Linux de référence (_upstream_).

- Il est donc disponible dans tous les noyaux modernes.

  (AUFS était disponible sur Debian et Ubuntu, mais exigeait des noyaux spécifiques sur d'autres distributions.)

- Il est plus simple qu'AUFS (il ne peut y avoir que deux branches, appelés "layers").

- Le moteur de conteneur cache ce détail d'implémentation, ce n'est donc pas un souci.

- Les pilotes de stockage Overlay2 utilisent généralement des liens durs entre couches.

- Cela améliore la performance de `stat()` et `open()`, au prix de l'usage d'inodes.

---

## ZFS

- ZFS est similaire à BTRFS (au moins du point de vue d'un utilisateur de conteneur).

- Avantages:

  - haute performnce
  - haute résilience (grâce entre autres au _checksum_ sur les données)
  - avec en options: compression et déduplication de la donnée

- Inconvénients:

  - usage mémoire supérieur
  - non disponible dans le noyau Linux de référence (_upstream_)

- Il est disponible sous forme de module de noyau ou via FUSE.

---

## Quel est le meilleur?

- Finalement, overlay2 devrait être la meilleure option.

- Il est disponible sur tous les systèmes modernes.

- Son usage mémoire est meilleur que Device Mapper, BTRFS ou ZFS.

- Les réserves sur la *performance d'écriture* ne devraient pas vous freiner:
  <br/>
  les données devraient toujours être stockées dans des volumes de toute façon!
