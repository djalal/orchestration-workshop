# Concepts Kubernetes

- Kubernetes est un système de gestion de conteneurs

- Il lance et gère des applications conteneurisées sur un _cluster_

--

- Qu'est-ce que ça signifie vraiment?

---

## Tâches de base qu'on peut demander à Kubernetes

--

- Démarrer 5 conteneurs basés sur l'image `atseashop/api:v1.3`

--

- Placer un _load balancer_ interne devant ces conteneurs

--

- Démarrer 10 conteneurs basés sur l'image `atseashop/webfront:v1.3`

--

- Placer un _load balancer_ public devant ces conteneurs

--

- C'est _Black Friday_ (ou Noël!), le trafic explose, agrandir notre cluster et ajouter des conteneurs

--

- Nouvelle version! Remplacer les conteneurs avec la nouvelle image `atseashop/webfront:v1.4`

--

- Continuer de traiter les requêtes pendant la mise à jour; renouveler mes conteneurs un à la fois

---

## D'autres choses que Kubernetes peut faire pour nous

- Montée en charge basique

- Déploiement _Blue/Green_, déploiement _canary_

- Services de longue durée, mais aussi des tâches par lots (batch)

- Surcharger notre cluster et *évincer* les tâches de basse priorité

- Lancer des services à données *persistentes* (bases de données, etc.)

- Contrôle d'accès assez fin, pour définir *quelle* action est autorisée *pour qui* sur *quelle* ressources.

- Intégrer les services tiers (*catalogue de services*)

- Automatiser des tâches complexes (*opérateurs*)

---

## Architecture Kubernetes

---

class: pic

![haha je plaisante](images/k8s-arch1.png)

---

## Architecture Kubernetes

- Ha ha ha ha

- OK, je voulais juste vous faire peur, c'est plus simple que ça ❤️

---

class: pic

![celui là est plus proche du vrai](images/k8s-arch2.png)

---

## Crédits

- Le premier schéma est un cluster Kubernetes avec du stockage sur l'_iSCSI multi-path_

  (Grâce à [Yongbok Kim](https://www.yongbok.net/blog/))

- Le second est une représentation simplifiée d'un cluster Kubernetes

  (Grâce à [Imesh Gunaratne](https://medium.com/containermind/a-reference-architecture-for-deploying-wso2-middleware-on-kubernetes-d4dee7601e8e))

---

## Architecture de Kubernetes: les _nodes_

- Les _nodes_ qui font tourner nos conteneurs ont aussi une collection de services:

  - un moteur de conteneurs (typiquement Docker)

  - kubelet (l'agent de _node_)

  - kube-proxy (un composant réseau nécessaire mais pas suffisant)

- Les _nodes_ étaient précédemment appelées des "minions"

  (On peut encore rencontrer ce terme dans d'anciens articles ou documentation)

---

## Architecture Kubernetes: le plan de contrôle

- La logique de Kubernetes (ses "méninges") est une collection de services:

  - Le serveur API (notre point d'entrée pour toute chose!)

  - des services principaux comme l'ordonnanceur et le contrôleur

  - `etcd` (une base clé-valeur hautement disponible; la "base de données" de Kubernetes)

- Ensemble, ces services forment le plan de contrôle de notre cluster

- Le plan de contrôle est aussi appelé le _"master"_

---

## Exécuter le plan de contrôle sur des _nodes_ spéciales

- Il est commun de réserver une _node_ dédiée au plan de contrôle

  (Excepté pour les cluster de développement à node unique, comme avec minikube)

- Cette _node_ est alors appelée un "_master_"

  (Oui, c'est ambigu: est-ce que le "master" est une _node_, ou tout le plan de contrôle?)

- Les applis normales sont interdites de tourner sur cette _node_

  (En utilisant un mécanisme appelé ["taints"](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/))

- Quand on cherche de la haute disponibilité, chaque service du plan de contrôle doit être résilient

- Le plan de contrôle est alors répliqué sur de multiples noeuds

  (On parle alors d'installation "_multi-master_")

---

## Lancer le plan de contrôle sans conteneurs

- Les services du plan de contrôle peuvent tourner avec ou sans conteneurs

- Par exemple: puisque `etcd` est un service critique, certains le
  déploient directement sur un cluster dédié (sans conteneurs)

  (C'est illustré dans le premier schéma "super compliqué")

- Dans certaines offres commerciales Kubernetes (par ex. AKS, GKE, EKS), le plan de contrôle est invisible

  (On "voit" juste un point d'entrée Kubernetes API)

- Dans ce cas, il n'y a pas de _node_ "master"

*Pour cette version, il est plus précis de parler de "plan de contrôle" plutôt que de "master".*

---

## Docker est-il obligatoire à tout prix?

Non!

--

- Par défaut, Kubernetes choisit le Docker Engine pour lancer les conteneurs

- On pourrait utiliser `rkt` ("Rocket") par CoreOS

- Ou exploiter d'autre moteurs via la *Container Runtime Interface*

  (comme CRI-O, ou containerd)

---

## Devrait-on utiliser Docker?

Oui!

--

- Dans cet atelier, on lancera d'abord notre appli sur un seul noeud

- On devra générer les images et les envoyer à la ronde

- On pourrait se débrouiller sans Docker
  <br/>
  (et être diagnostiqué du syndrome NIH¹)

- Docker est à ce jour le moteur de conteneurs le plus stable
  <br/>
  (mais les alternatives mûrissent rapidement)

.footnote[¹[Not Invented Here](https://en.wikipedia.org/wiki/Not_invented_here)]

---

## Devrait-on utiliser Docker?

- Sur nos environnements de développement, les pipelines CI ... :

  *Oui, très certainement*

- Sur nos serveurs de production:

  *Oui (pour aujourd'hui)*

  *Probablement pas (dans le futur)*

.footnote[Pour plus d'infos sur CRI [sur le blog Kubernetes](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes)]

---

## Ressources sur Kubernetes

- L'API Kubernetes définit un tas d'objets appelés *resources*

- Ces ressources sont organisées par type, ou `Kind` (dans l'API)

- Quelques types de ressources communs:

  - _node_ (une machine - physique ou virtuelle - de notre cluster)
  - _pod_ (groupe de conteneurs lancés ensemble sur une _node_)
  - _service_ (point d'entrée stable du réseau pour se connecter à un ou plusieurs conteneurs)
  - _namespace_ (groupe de choses plus-ou-moins isolée)
  - _secret_ (ensemble de données sensibles transmis à un conteneur)

  Et bien plus!

- On peut afficher la liste complète avec `kubectl api-resources`

  (Dans Kubernetes 1.10 et avant, la commande pour lister les ressources API étaient `kubectl get`)

---

class: pic

![Node, pod, container](images/k8s-arch3-thanks-weave.png)

---

class: pic

![Un des meilleurs diagrammes d'archi Kubernetes disponibles](images/k8s-arch4-thanks-luxas.png)

---

## Crédits

- Le premier diagramme est une grâcieuseté de Weave Works

  - un *pod* peut avoir plusieurs conteneurs qui travaillent ensemble

  - les adresses IP sont associées aux *pods*, pas aux conteneurs eux-mêmes

- Le second diagramme est une grâcieuseté de Lucas Käldström, dans [cette présentation](https://speakerdeck.com/luxas/kubeadm-cluster-creation-internals-from-self-hosting-to-upgradability-and-ha)

  - c'est l'un des meilleurs diagrammes d'architecture Kubernetes disponibles!

Les deux diagrammes sont utilisés avec la permission de leurs auteurs.
