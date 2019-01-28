## Ajouter plus de nodes manager

- Jusqu'ici, on a juste un *manager* (node1)

- Si on le perd, on perd le quorum, et c'est *très grave!*

- Les conteneurs sur les autres nodes n'auront pas de problème...

- Si le *manager* est parti pour de bon, on va devoir réparer à la main!

- Personne ne veut faire ça... donc passons en haute disponibilité

---

class: self-paced

## Ajouter plus de managers

Avec Play-With-Docker:

```bash
TOKEN=$(docker swarm join-token -q manager)
for N in $(seq 3 5); do
  export DOCKER_HOST=tcp://node$N:2375
  docker swarm join --token $TOKEN node1:2377
done
unset DOCKER_HOST
```

---

class: in-person

## Monter un cluster complet

- Récupérons le *token*, et lançons la commande sur la dernière node avec SSH

.exercise[

- Obtenir le jeton *manager*:
  ```bash
  TOKEN=$(docker swarm join-token -q manager)
  ```

- Ajouter la node qui reste:
  ```bash
    ssh node3 docker swarm join --token $TOKEN node1:2377
  ```

]

[C'était facile.](https://www.youtube.com/watch?v=3YmMNpbFjp0)

---

## Contrôler le Swarm depuis d'autres nodes

.exercise[

- Essayer la commande suivante sur les différentes nodes:
  ```bash
  docker node ls
  ```

]

Sur les noeuds *manager*:
<br/>vous verrez la liste des _nodes_, avec un `*`,
indiquant la _node_ qui répond.

Sur les _nodes_ non-manager:
<br/>un message d'erreur s'affichera vous disant que
cette node n'est pas un *manager*.

Comme vu plus haut, on ne peut contrôler le Swarm que depuis une node *manager*.

---

class: self-paced

## L'icône de statut des nodes sur Play-With-Docker

- Si vous passez via Play-With-Docker, vous verrez des icones de statut par node.

- Les icônes de statut sont affichées à gauche du nom de chaque node.

  - Sans icône = pas de mode Swarm détecté
  - Icône bleue remplie = *manager* Swarm
  - Icône blanche à bord bleu = *worker* Swarm

![Icône Play-With-Docker icons](images/pwd-icons.png)

---

## Changer le rôle d'un noeud à la volée

- On peut changer le rôle d'une node dynamiquement:

  `docker node promote nodeX` → passer nodeX en *manager*
  <br/>
  `docker node demote nodeX` → passer nodeX en *worker*

.exercise[

- Afficher la liste courante des noeuds:
  ```
  docker node ls
  ```

- Promouvoir tout *worker* en *manager*
  ```
  docker node promote <node_name_or_id>
  ```

]

---

## Combien de managers sont conseillés?

- 2N+1 noeuds peuvent (et vont) résister à N pannes
  <br/>(vous pouvez mettre un nombre pairs de *managers* mais ça n'a aucun intérêt)

--

- 1 manager = pas de tolérance de panne

- 3 managers = tolérance d'une panne

- 5 managers = tolérance de 2 panne (ou 1 panne pendant 1 maintenance)

- 7 managers ou plus = là vous forcez peut-être un peu sur l'archi

.footnote[

 voir [Docker's admin guide](https://docs.docker.com/engine/swarm/admin_guide/#add-manager-nodes-for-fault-tolerance)
 à propos des pannes de nodes et la redondance en centre de données

]

---

## Pourquoi ne pas mettre *toutes* les nodes en *manager*?

- Avec Raft, les écritures doivent atteindre (et être confirmés par) tous les noeuds.

- Par conséquent, c'est plus dur d'atteindre un consensus dans des groupes plus grands.

- Un seul *manager* est *Leader* (en écriture), donc "plus de managers ≠ plus de capacité"

- Les *managers* devraient être &#60; 10ms  de latence entre eux

- Ces facteurs de conceptions nous amènent à de meilleurs designs

---

## Que ferait McGyver à notre place?

- Garder les *managers* dans une région (ou multi-zone/centre de données/rack)

- Groupe de 3 à 5 noeuds: tous en *managers*. Au-delà de 5, séparer les *managers* et *workers*

- Groupe de 10-100 noeuds: prendre 5 noeuds "stables" pour être les *managers*

- Groupe de plus de 100 noeuds: surveiller le CPU et la RAM des managers

  - 16Go de mémoire ou plus, 4 CPUs au moins, disque SSD pour les E/S du Raft
  - autrement, répartir vos noeuds en plusieurs clusters plus petits

.footnote[

  Astuce de pro du cloud: utiliser des groupes *auto-scalings* distincts pour les *managers* et *workers*

  Voir le document chez Docker Inc. "[Running Docker at scale](http://success.docker.com/article/running-docker-ee-at-scale)"
]
---

## Quelle est la limite maximum?

- On n'en sait rien!

- Tests internes chez Docker Inc.: 1000 à 10000 noeuds sans problème

  - déployés sur une région de _cloud_

  - une des principales leçons était *"vous allez avoir besoin d'un plus gros manager"*

- Tests menés par la communauté: [4700 noeuds hétérogènes à travers le net](https://sematext.com/blog/2016/11/14/docker-swarm-lessons-from-swarm3k/)

  - ça marche et c'est tout, à condition d'avoir les ressources nécessaires

  - plus de nodes demandent plus de CPU et réseau pour le *manager*; plus de conteneurs demande plus de RAM

  - l'orchestration à très large échelle (70 000 conteneurs) est lente et difficile ([mais ça s'arrange](https://github.com/moby/moby/pull/37372)!)

---

## Méthodes de déploiements dans la vie réelle

--

Lancer les commandes à la main via SSH

--

  (mdr je blague)

--

- Exploiter votre outil de gestion de configuration préféré

- [Docker for AWS](https://docs.docker.com/docker-for-aws/#quickstart)

- [Docker for Azure](https://docs.docker.com/docker-for-azure/)
