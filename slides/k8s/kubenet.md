# Modèle réseau de Kubernetes

- En un mot comme en cent:

  *Notre cluster (nodes et pods) est un grand réseau IP tout plat.*

--

- Dans le détail:

  - toutes les _nodes_ doivent être accessibles les unes aux autres, sans NAT

  - tous les _pods_ doivent être accessibles les uns aux autres, sans NAT

  - _pods_ et _nodes_ doivent être accessibles les uns aux autres, sans NAT

  - chaque _pod_ connait sa propore adresse IP (sans NAT)

  - les adresses IP sont assignées par l'implémentation du réseau (le plugin)

- Kubernetes ne force pas une implémentation particulière

---

## Modèle réseau de Kubernetes: le bon

- Tout peut se connecter à tout

- Pas de traduction d'adresse

- Pas de traduction de port

- Pas de nouveau protocole

- L'implémentation réseau peut décider comment allouer les adresses

- Les adresses IP n'ont pas à être "portables" d'une node à une autre.

  (On peut avoir par ex. un sous-réseau par _node_ et utiliser une topologie simple)

- La spécification est assez simple pour permettre différentes implémentations variées

---

## Modèle réseau de Kubernetes: le moins bon

- Tout peut se connecter à tout

  - si on cherche de la sécurité, on devra rajouter des règles réseau

  - l'implémentation réseau que vous choisirez devra offrir cette fonction

- Il y a littéralement des dizaines d'implémentations dans le monde

  (Pas moins de 15 sont mentionnées dans la documentation Kubernetes)

- Les _pods_ ont une connectivité de niveau 3 (IP), et les *services* de niveau 4 (TCP ou UDP)

  (Les services sont associés à un seul port TCP ou UDP; pas de groupe de ports ou de paquets IP arbitraires)

- `kube-proxy` est sur le chemin de données quand il se connecte à un _pod_ ou conteneur,
  <br/>et ce n'est pas particulièrement rapide (il s'appuie sur du proxy utilisateur ou iptables)

---

## Modèle réseau de Kubernetes: en pratique

- Les nodes que nous avons à notre disposition utilisent [Weave](https://github.com/weaveworks/weave)

- On ne recommande pas Weave plus que ça, c'est juste que "Ca Marche Pour Nous"

- Pas d'inquiétude à propos des réserves sur la performance `kube-proxy`

- Sauf si vous:

  - saturez régulièrement des interfaces réseaux 10Gbps
  - comptez les flux de paquets par millions à la seconde
  - lancez des plate-formes VOIP ou de jeu de haut trafic
  - faites des trucs bizarres qui lancent des millions de connexions simultanées
    <br/>(auquel cas vous êtes déjà familier avec l'optimisation du noyau)

- Si nécessaire, des alternatives à `kube-proxy` existent, comme:
  [`kube-router`](https://www.kube-router.io)

---

class: extra-details

## La CNI (_Container Network Interface_)

- La CNI est une [spécification](https://github.com/containernetworking/cni/blob/master/SPEC.md#network-configuration) complète à destination des _plugins_ réseau.

- Quand un nouveau _pod_ est créé, Kubernetes délègue la config réseau aux _plugins_ CNI.

  (ça peut être un seul plugin, ou une combinaison de plugins, chacun spécialisé dans une tache)

- Généralement, un _plugin_ CNI va:

  - allouer une adresse IP (en appelant un _plugin_ IPAM)

  - ajouter une interface réseau dans le _namespace_ réseau du _pod_

  - configurer l'interface ainsi que les routes minimum, etc.

- Tous les _plugins_ CNI ne naissent pas égaux

  (par ex. il ne supportent pas tous les politiques de réseau, obligatoires pour isoler les _pods_)

---

class: extra-details

## Plusieurs cibles mouvantes

- Le "réseau pod-à-pod" ou "réseau pod":

  - fournit la communication entre pods et nodes

  - est généralement implémenté via des plugins CNI

- Le "réseau pod-à-service":

  - fournit la communication interne et la répartition de charge

  - est généralement implémenté avec kube-proxy (ou par ex. kube-router)

- _Network policies_ :

  - jouent le rôle de firewall et de couche d'isolation

  - peuvent être livrées avec le "réseau pod" ou fournit par un autre composant

---

class: extra-details

## Encore plus de cibles mouvantes

- Le trafic entrant peut être géré par plusieurs composants:

  - quelque chose comme kube-proxy ou kube-router (pour les services NodePort)

  - les _load balancers_ (idéalement, connectés au réseau _pod_)

- En théorie, il est possible d'utiliser plusieurs réseaux _pods_ en parallèle

  (avec des "meta-plugins" comme CNI-Genie ou Multus)

- Quelques solutions peuvent remplir plusieurs de ces rôles

  (par ex. kube-router peut être installé pour implémenter le réseau _pod_ et/ou les _network policies_ et/ou remplacer kube-proxy)
