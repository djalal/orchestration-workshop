# Limiter les ressources

- Jusqu'ici, nous avons utilisé les conteneurs comme des unités de déploiements assez pratiques.

- Que se passe-t-il quand un conteneur essaie d'utiliser plus de ressources que disponible?

  (RAM, CPU, disque, entrées/sortie réseau...)

- Que se passe-t-il quand plusieurs conteneurs entrent en concurrence pour la même ressource?

- Pouvons-nous limiter les ressources allouées à un conteneur?

  (Un indice: oui!)

---

## Processus de conteneur, processus normaux

- Les conteneurs sont plus proches de "processus spéciaux" que de "VMs légères".

- Un processus lancé dans un conteneur est, en fait, un processus s'exécutant sur l'hôte.

- Jetons un oeil à l'affichage de `ps` sur un hôte hébergeant 3 conteneurs:

  ```
       0  2662  0.2  0.3 /usr/bin/dockerd -H fd://
       0  2766  0.1  0.1  \_ docker-containerd --config /var/run/docker/containe
       0 23479  0.0  0.0      \_ docker-containerd-shim -namespace moby -workdir
       0 23497  0.0  0.0      |   \_ `nginx`: master process nginx -g daemon off;
     101 23543  0.0  0.0      |       \_ `nginx`: worker process
       0 23565  0.0  0.0      \_ docker-containerd-shim -namespace moby -workdir
     102 23584  9.4 11.3      |   \_ `/docker-java-home/jre/bin/java` -Xms2g -Xmx2
       0 23707  0.0  0.0      \_ docker-containerd-shim -namespace moby -workdir
       0 23725  0.0  0.0          \_ `/bin/sh`
  ```

- Les processus surlignés sont des processus conteneurisés.
  <br/>
  (Cet hôte fait tourner nginx, elasticsearch et alpine.)

---

## Par défaut: rien ne change

- Que se passe-t-il quand un processus utilise trop de mémoire sur un système Linux?

--

- Réponse simplifiée:

  - du _swap_ est consommé;

  - au cas où le _swap_ ne suffise pas, au final, le _out-of-memory killer_ est invoqué;

  - le _OOM killer_ exploite des heuristiques pour terminer les processus;

  - parfois, il tue un processus sans lien.

--

- Que se passe-t-il quand un conteneur utilise trop de mémoire?

- La même chose!

  (i.e. un processus finira par être supprimé, peut-être même dans un autre conteneur.)

---

## Limiter les ressources de conteneur

- Le noyau Linux offre de riches mécanismes pour limiter les ressources de conteneur.

- Pour l'usage mémoire, ce mécanisme fait partie du sous-système des *cgroups*.

- Ce sous-système permet de limiter la mémoire d'un processus ou d'un groupe entier.

- Un moteur de conteneur exploite ces mécanismes pour limiter la mémoire d'un conteneur.

- Le _OOM killer_ expose un nouveau comportement:

  - il se lance quand un conteneur dépasse la limite de mémoire autorisée;

  - dans ce cas, il supprime seulement les processus de ce conteneur.

---

## Limiter la mémoire en pratique

- Le Docker Engine offre bien des options pour limiter l'usage mémoire.

- Les deux plus utiles sont `--memory` et `--memory-swap`.

- `--memory` limite la quantité de RAM physique utilisée par un conteneur.

- `--memory-swap` limite la quantité de mémoire totale (RAM+_swap_) disponible par conteneur.

- La limite de mémoire peut être exprimée en octets, ou avec un suffixe d'unité.

  (par ex.: `--memory 100m` = 100 méga-octets.)

- Nous examinerons ici deux stratégies: limiter l'usage de la RAM, ou les deux (RAM+_swap_).

---

## Limiter l'usage de la RAM

Exemple:

```bash
docker run -ti --memory 100m python
```

Si le conteneur tente d'allouer plus de 100Mo de RAM, *et* que le _swap_ est disponible:

- le conteneur ne sera pas tué,

- la mémoire au dessus de 100Mo passera dans le _swap_,

- la plupart des cas, l'appli dans le conteneur sera ralentie (beaucoup).

Si nous saturons le _swap_, le _OOM killer_ global s'activera quand même.

---

## Limiter à la fois RAM et _swap_

Exemple:

```bash
docker run -ti --memory 100m --memory-swap 100m python
```

Si un conteneur essaie d'utiliser plus de 100Mo de mémoire, il sera tué.

D'un autre côté, l'application ne sera jamais ralentie à cause du _swap_.

---

## Quand adopter quelle stratégie?

- Les services à données persistentes (telles les bases de données) vont perdre leur données ou les corrompre si elles sont tuées.

- On préfère les autoriser à utiliser l'espace _swap_, mais en surveiller leur usage.

- Les services immuables peuvent normalement être tués avec un impact faible.

- On pourra limiter leur usage mémoire+_swap_, mais surveiller s'ils sont tués.

- Au final, cela revient à la question "ais-je besoin de _swap_, et combien?"

---

## Limiter l'usage CPU

- Il n'y a pas moins de trois moyens de limiter l'usage CPU:

  - régler la priorité relative avec `--cpu-shares`,

  - placer une limite en pourcentage de CPU avec `--cpus`,

  - épingler un conteneur à des CPUs spécifiques avec `--cpuset-cpus`.

- Ils peuvent être utilisés séparément ou ensemble.

---

## Régler une priorité relative

- Chaque conteneur a une priorité relative utilisée par l'ordonnanceur Linux.

- Par défaut, cette priorité est de 1024.

- Tant que l'usage du CPU n'est pas maximum, elle n'a pas d'effet.

- Dès que le CPU atteint sa limite, chaque conteneur reçoit des cycles CPU en proportion de sa priorité relative.

- Autrement dit: un conteneur avec `--cpu-shares 2018` en recevra deux fois plus que celui par défaut.

---

## Limiter en pourcentage de CPU

- Ce réglage s'assure qu'un conteneur n'utilise pas plus d'un certain pourcentage de CPU.

- La limite est exprimée en CPUs; par conséquent:

  `--cpus 0.1` signifie 10% d'un CPU,
  `--cpus 1.0` signifie 100% d'un CPU entier,
  `--cpus 10.0` signifie 10 CPUs entiers.

---

## Épingler des conteneurs aux CPUs

- Sur des machines multi-coeurs, il est possible de restreindre l'exécution à un ensemble de CPUs.

- Exemples:

  `--cpuset-cpus 0` force le conteneur à tourner sur le CPU 0;

  `--cpuset-cpus 3,5,7` limite le conteneur aux CPUs 3, 5, 7;

  `--cpuset-cpus 0-3,8-11` épingle le conteneur aux CPUs 0, 1, 2, 3, 8, 9, 10, 11.

- Cela ne réservera pas les CPUs correspondants!

  (Ils peuvent toujours être sollicités par d'autres conteneurs, ou des processus non-conteneurisés)

---

## Limiter l'usage du disque

- La plupart des pilotes de stockage ne supportent pas la limitation du disque pour conteneurs.

  (À l'exception de devicemapper, mais cette limite n'est pas simple à régler.)

- Cela signifie donc qu'un seul conteneur peut vider l'espace disponible pour tous.

- En pratique, toutefois, ce n'est pas un souci, car:

  - les fichiers de données (pour services persistents) devraient résider dans des volumes,

  - les _assets_ (par ex. images, contenu généré, etc.) devraient résider dans des banques de données ou des volumes,

  - les _logs_ sont écrits en sortie standard et collectés par le moteur à conteneur.

- L'usage du disque par les conteneurs peut être audité avec `docker ps -s` et `docker diff`.
