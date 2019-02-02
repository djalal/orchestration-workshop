# Orchestration, aperçu général

Dans ce chapitre, nous allons:

* Expliquer ce qu'est l'orchestration et quand est-ce qu'on en a besoin.

* Quelques orchestrateurs modernes (d'une perspective générale)

* Faire la démonstration d'un orchestrateur en action.

---

class: pic

## Qu'est-ce que l'orchestration?

![Joana Carneiro (orchestra conductor)](images/conductor.jpg)

---

## Qu'est-ce que l'orchestration?

Selon Wikipedia:

*L'orchestration décrit le processus automatique d'organisation,
de coordination, et de gestion de systèmes informatiques complexes,
de middleware et de services.*

--

*[...] On parle souvent de cet usage de l'orchestration dans le contexte
de la __virtualisation__, de la __fourniture de services__
et des __centres de données dynamiques__.*

--

Qu'est-ce que cela veut dire en réalité?

---

## Exemple 1: instances de _cloud_ dynamiques

--

- Q: est-ce qu'on utilise toujours 100% de nos serveurs?

--

- R: évidemment non!

.center[![Variations quotidiennes de trafic](images/traffic-graph.png)]

---

## Exemple 1: instances de _cloud_ dynamiques

- Chaque nuit, diminuer la capacité

  (en éteignant les instances de réplication superflues)

- Chaque matin, augmenter la capacité

  (en déployant de nouvelles instances)

- "Payez selon l'usage"

  (ie. économiser un bon paquet de $$$)

---

## Exemple 1: instances de _cloud_ dynamiques

Comment implémenter ceci?

- Crontab
- Ajustement automatique de capacité (_autoscaling_), économiser un plus gros paquet de $$$.

C'est _relativement_ facile.

Maintenant, comment vont les choses chez notre founisseur IAAS?

---

## Exemple 2: _datacenter_ dynamique

- Q: quel est le coût n°1 d'un centre de données?

--

- R: l'électricité!

--

- Q: qui consomme l'électricité?

--

- R: les serveurs, évidemment

- R: ... et le refroidissement qui l'accompagne

--

- Q: est-ce qu'on utilise toujours 100% de nos serveurs?

--

- R: évidemment pas!

---

## Exemple 2: _datacenter_ dynamique

- Si seulement on pouvait éteindre les serveurs inutilisés la nuit...

- Problème: on ne peut éteindre un serveur que s'il est totalement vide!

  (ie. toutes ses VMs sont stoppées/déménagées)

- Solution: *migrer* les Vms et éteindre les serveurs vides

  (par ex. combiner deux hyperviseurs avec 40% de charge en 80%+0%)
  <br/>et éteindre celui à 0%)

---

## Exemple 2: _datacenter_ dynamique

Comment on implémente ceci?

- Éteindre les hôtes vides (tout en gardant de la capacité en réserve)

- Démarrer les hôtes à nouveau quand la capacité libre diminue trop.

- La possibilité de migrer à chaud les VMs

  (Xen pouvait faire ça il y a 10 ans et plus.)

- Ré-affecter les VMs de manière régulière

  - et si une VM est stoppée pendant son déménagement?
  - devons-nous autoriser la création sur des hôtes concernés par une migration?

Le *scheduling* (ordonnancement) devient encore plus complexe.

---

## Qu'est-ce que l'ordonnancement

Selon Wikipedia (encore):

*Dans les systèmes d'exploitation, l’ordonnanceur désigne le composant
du noyau du système d'exploitation choisissant l'ordre d'exécution
des processus sur les processeurs d'un ordinateur.*

L'ordonnanceur est principalement occupé par:
- le rythme et l'intensité (montant total de travail réalisé par unité de temps);
- le temps de complétion (entre la soumission et la complétion);
- le temps de réponse (entre la soumission et le début);
- le temps d'attente (entre le moment où le travail est prêt, et son exécution);
- l'équité (que le temps soit approprié et calé sur les priorités)

En pratique, ces objectifs se téléscopent souvent.

**"Ordonnancement" = décider quelles ressources utiliser.**

---

## Exercice 1

- Vous disposez de:

  - 5 hyperviseurs (machines physiques)

- Chaque serveur possède:

  - 16 Go RAM, 8 coeurs, 1 To de disque

- Chaque semaine, votre équipe exige:

  - une VM avec X RAM, Y CPU et Z disque

Ordonnancement = décider quel hyperviseur utiliser pour chaque VM.

Difficulté: facile!

---

<!-- Warning, two almost identical slides (for img effect) -->

## Exercice 2

- Vous disposez de:

  - 1000+ hyperviseurs (et plus!)

- Chaque serveur dispose de différentes ressources:

  - 8-500 Go de RAM, 4-64 coeurs, 1-100 To disque

- Plusieurs fois par jour, une équipe différente demande:

  - jusqu'à 50 VMs avec différentes caractéristiques

Ordonnancement = décider quel hyperviseur utiliser pour chaque VM.

Difficulté: ???

---

<!-- Warning, two almost identical slides (for img effect) -->

## Exercice 2

- Vous disposez de:

  - 1000+ hyperviseurs (et plus!)

- Chaque serveur dispose de différentes ressources:

  - 8-500 Go de RAM, 4-64 coeurs, 1-100 To disque

- Plusieurs fois par jour, une équipe différente demande:

  - jusqu'à 50 VMs avec différentes caractéristiques

Ordonnancement = décider quel hyperviseur utiliser pour chaque VM.

![Troll face](images/trollface.png)

---

## Exercice 3

- Vous disposez de machines (physiques et/ou virtuelles)

- Vous avez des conteneurs

- Vous essayez de placer les conteneurs sur les machines

- Ça vous rappelle quelque chose?

---

## Ordonnancement à 1 dimension

.center[![Not-so-good bin packing](images/binpacking-1d-1.gif)]

Peut-on faire mieux?

---

## Ordonnancement à 1 dimension

.center[![Better bin packing](images/binpacking-1d-2.gif)]

Ouais!

---

## Ordonnancement à 2 dimensions

.center[![2D bin packing](images/binpacking-2d.gif)]

---

class: pic

## Ordonnancement à 3 dimensions

.center[![3D bin packing](images/binpacking-3d.gif)]

---

class: pic

## Vous devez être bon à ce jeu

.center[![Tangram](images/tangram.gif)]

---

class: pic

## Mais pas que, il faut aussi être rapide!

.center[![Tetris](images/tetris-1.png)]

---

class: pic

## Et à l'échelle du web!

.center[![Big tetris](images/tetris-2.gif)]

---

class: pic

## Et penser hors (?) des sentiers battus!

.center[![3D tetris](images/tetris-3.png)]

---

class: pic

## Bon courage!

.center[![FUUUUUU face](images/fu-face.jpg)]

---

## TL;DR

* L'ordonnancement à plusieurs dimensions (les ressources) est difficile.

* Ne vous attendez pas à résoudre le problème avec un Petit Script Shell.

* Il y a littéralement des tonnes d'études scientifiques publiées à ce sujet.

---

## Mais notre orchestrateur a aussi besoin de gérer ...

* La connectivité réseau (ou le filtrage) entre conteneurs.

* La répartition de charge (externe et interne).

* La récupération sur incident (si un noeud ou un _datacenter_ entier tombe).

* Le déploiement de nouvelles versions de nos applications.

 (Déploiements _canary_, _blue/green_ ...)


---

## Quelques orchestrateurs

Nous allons brièvement présenter quelques orchestrateurs.

Il n'existe pas de meilleur orchestrateur dans l'absolu.

Cela dépend de:

 - vos applications,

 - vos contraintes,

 - vos compétences...

---

## Nomad

- Project open-source par Hashicorp.

- Ordonnanceur agnostique (pas juste des conteneurs).

- Très bien si vous avez des charges de travail diverses.

  (VMs, conteneurs, processus...)

- Moins d'intégration que le reste de l'écosystème des conteneurs.

---

## Mesos

- Projet open-source de la fondation Apache.

- Ordonnanceur agnostique (pas juste des conteneurs).

- Ordonnanceur à double niveau.

- Le niveau supérieur de l'ordonnanceur agit comme un intermédiaire en ressource.

- Les ordonnanceurs de second niveau (appelés "frameworks") obtiennent leurs ressources du niveau supérieur.

- Les frameworks implémentent des stratégies diverses.

  (Marathon = processus de longue durée; Chronos = lancement par intervalles; ...)

- Une offre commerciale existe à travers DC/OS par Mesosphere.

---

## Rancher

- Rancher 1 offrait une interface simple pour les hôtes Docker.

- Rancher 2 est une plate-forme de gestion complète pour Docker et Kubernetes.

- Techniquement, ce n'est pas un orchestrateur, mais cela reste une option populaire.

---

## Swarm

- Étroitement intégré au Docker Engine.

- Extrêmement simple à déployer et installer, y compris en mode multi-manager (HA).

- Sécurisé par défaut.

- Choix fortement orientés:

 - ensemble de fonctions plus réduit et concentré,

 - plus facile à administrer.

---

## Kubernetes

- Projet open source initié par Google.

- Contributions de la part de nombreux autres acteurs de l'industrie.

- le standard *de facto* pour l'orchestration de conteneurs.

- Nombreuses options de déploiement; dont certaines très complexes.

- Réputation: forte courbe d'apprentissage.

- En réalité:

  - c'est le cas, quand on essaie de *tout* comprendre;

  - ce n'est pas vrai, si on se concentre sur ce qui nous intéresse.

