# SwarmKit

- [SwarmKit](https://github.com/docker/swarmkit) est un projet open source
  sous forme de boîte à outils pour monter des systèmes multi-noeud.

- C'est une bibliothèque réutilisable, comme libcontainer, libnetwork, vpnkit ...

- C'est un des composants qui font la plomberie de l'éco-système Docker

--

.footnote[.emoji[🐳] Saviez-vous que кит veut dire "baleine" en russe?]

---

## Fonctionnalités de SwarmKit

- Base de données distribuée, hautement disponible basée sur [Raft](
  https://en.wikipedia.org/wiki/Raft_%28computer_science%29)
  <br/>(évite la dépendance à une base externe, plus simple à déployer, meilleure performance)

- Reconfiguration dynamique de Raft sans interruption des opérations sur le cluster.

- *Services* gérés avec une *API déclarative*
  <br/>(implémentant l'*état cible* et une *boucle de réconciliation*)  @@@TRAD

- Intégré avec les réseaux superposés et la répartition de charge

- Accent important sur la sécurité:

  - génération automatique des clés et signatures TLS; rotation automatique des certificats
  - chiffrement complet du plan de données; rotation automatique des clés
  - architecture du privilège moindre (faille d'un noeud ≠ faille du cluster)
  - chiffrement sur disque avec phrase de passe optionnelle

---

class: extra-details

## Où est la base de données clé-valeur

- Bien des systèmes d'orchestration utilisent une base clé-valeur exploitée par un algorithme de consensus
  <br/>
  (k8s->etcs->Raft, mesos->zookeeper->ZAB, etc.)

- SwarmKit implémente l'algorithme Raft directement
 (Nomad est similaire en ce point, merci à [@cbednarski](https://twitter.com/@cbednarski),
  [@diptanu](https://twitter.com/diptanu) entre autres de l'avoir rappelé!)

- Analogie offert par [@aluzzardi](https://twitter.com/aluzzardi):

  *C'est comme les B-trees et les SGBD. Ce sont différentes couches,
  souvent associées. Mais on n'a pas besoin de lancer un serveur SQL
  complet, si on a juste besoin d'indexer quelques données.*

- Par conséquent, l'orchestrateur a directement accès à la donnée
  <br/>
  (l'original de la donnée est stocké dans la mémoire de l'orchestrateur)

- Plus simple, facile à déployer et administrer; et aussi plus rapide

---

## Concepts de SwarmKit (1/2)

- Un *cluster* est composé d'au moins une *node* (plus de préférence)

- Une *node* peut prendre le rôle de *manager* ou *worker*

- Un *manager* prend une part active dans le consensus Raft, et conserve le log du Raft

- On peut dialoguer avec un *manager* en utilisant l'API SwarmKit

- Un *manager* est élu en tant que *leader*; les autres managers ne font que lui transmettre les demandes

- Les *workers* prennet leurs ordres des *managers*

- Tous (*workers* et *managers*) peuvent faire tourner des conteneurs

---

## Illustration

Sur la prochaine diapo:

- baleines = noeuds (workers et managers)

- singes = managers

- singe violet = leader

- singes gris = suiveurs

- triangle en pointillés = protocole Raft

---

class: pic

![Illustration](images/swarm-mode.svg)

---

## Concepts de SwarmKit (2/2)

- Les *managers* exposent l'API SwarmKit

- Via cette API, on peut demander à lancer un *service*

- Un *service* est spécifié par son *état souhaité*: quelle image, combien d'instances, etc.

- Le *leader* utilise différent sous-systèmes pour décomposer le services en *tasks*:
  <br/>orchestrateur, ordonnanceur, allocateur, répartiteur

- Une *task* correspond à un conteneur spécifique, assigné à une *node* spécifique

- Les *Nodes* savent quelles *tasks* devraient tourner, et feront lancer et stopper leurs conteneurs en accord (via l'API du Docker Engine)

Vous pouvez vous référer à la [NOMENCLATURE](https://github.com/docker/swarmkit/blob/master/design/nomenclature.md) du dépôt SwarmKit pour plus de détails.