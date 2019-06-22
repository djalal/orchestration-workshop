# Premier contact avec `kubectl`


- `kubectl` est (presque) le seul outil dont nous aurons besoin pour parler à Kubernetes

- C'est un outil en ligne de commande très riche, autour de l'API Kubernetes

  (Tout ce qu'on peut faire avec `kubectl`, est directement exécutable via l'API)

- Sur nos machines, on trouvera un fichier `~/.kube/config` avec:

  - l'adresse de l'API Kubernetes

  - le chemin vers nos certificats TLS d'identification

- On peut aussi utiliser l'option `--kubeconfig` pour forcer un fichier de config

- Ou passer directement `--server`, `--user`, etc.

- `kubectl` se prononce "Cube Cé Té Elle", "Cube coeuteule", "Cube coeudeule"

---

## `kubectl get`

- Jetons un oeil aux ressources `Node` avec `kubectl get`!

.exercise[

- Examiner la composition de notre cluster:
  ```bash
  kubectl get node
  ```

- Ces commandes sont équivalentes:
  ```bash
  kubectl get no
  kubectl get node
  kubectl get nodes
  ```

]

---

## Obtenir un affichage version "machine"

- `kubectl get` peut afficher du JSON, YAML ou un format personnalisé

.exercise[

- Sortir plus d'info sur les nodes
  ```bash
  kubectl get nodes -o wide
  ```

- Récupérons du YAML:
  ```bash
  kubectl get no -o yaml
  ```

  Ce bout de `kind: List` tout à la fin? C'est le type de notre résultat!

]


---

## User et abuser de `kubectl` et `jq`

- C'est super facile d'afficher ses propres rapports

.exercise[

- Montrer la capacité de tous nos noeuds sous forme de flux d'objets JSON:
  ```bash
    kubectl get nodes -o json | 
            jq ".items[] | {name:.metadata.name} + .status.capacity"
  ```

]

---

class: extra-details

## Qu'est-ce qui tourne là-dessous?

- `kubectl` dispose de capacité d'introspection solides

- On peut lister les types de ressources en lançant `kubectl api-resources`
  <br/>
  (Sur Kubernetes 1.10 et les versions précédentes, il fallait taper `kubectl get`)

- Pour détailler une ressource, c'est:
  ```bash
  kubectl explain type
  ```

- La définition d'un type de ressource s'affiche avec:
  ```bash
  kubectl explain node.spec
  ```
- ou afficher la définition complète de tous les champs et sous-champs:
  ```bash
  kubectl explain node --recursive
  ```

---

class: extra-details

## Introspection vs. documentation

- On peut accéder à la même information en lisant [la documentation d'API](https://kubernetes.io/docs/reference/#api-reference)

- La doc est habituellement plus facile à lire, mais:

  - elle ne montrera par les types (comme les Custom Resource Definitions)
  - attention à bien utiliser la version correcte

- `kubectl api-resources` and `kubectl explain` font de l'*introspection*

 (en s'appuyant sur le serveur API, pour récupérer des définitions de types exactes)

---

## Nommage de types

- Les ressources les plus communes ont jusqu'à 3 formes de noms:

 - singulier (par ex. `node`, `service`, `deployment`)

 - pluriel (par ex.  `nodes`, `services`, `deployments`)

 - court (par ex. `no`, `svc`, `deploy`)

- Certaines ressources n'ont pas de nom court

- `Endpoints` n'ont qu'une forme au pluriel

  (parce que même une seule ressource `Endpoints` est en fait une liste d'_endpoints_)

---

## Détailler l'affichage

- On peut taper `kubectl get -o yaml` pour un détail complet d'une ressource

- Toutefois, le format YAML peut être à la fois trop verbeux et incomplet

- Par exemple,  `kubectl get node node1 -o yaml` est:

  - trop verbeux (par ex. la liste des images disponibles sur cette node)

  - incomplet (car on ne voit pas les pods qui y tournent)

  - difficile à lire pour un administrateur humain

- Pour une vue complète, on peut utiliser `kubectl describe` en alternative.

---

## `kubectl describe`

- `kubectl describe` requiert un type de ressource et (en option) un nom de ressource

- Il est possible de fournir un préfixe de nom de ressource 

  (tous les objets contenant ce nom seront affichés)

- `kubectl describe` va récupérer quelques infos de plus sur une ressource

.exercise[

- Jeter un oeil aux infos de `node1` avec une de ces commandes:

  ```bash
  kubectl describe node/node1
  kubectl describe node node1
  ```

]

(On devrait voir un tas de pods du plan de contrôle)

---

## Services

- Un *service* est un point d'entrée stable pour se connecter à "quelque chose"

  (Dans la proposition initiale, on appelait ça un "portail")

.exercise[

- Lister les services sur notre cluster avec une de ces commandes:
  ```bash
  kubectl get services
  kubectl get svc
  ```

]

--

Il y a déjà un service sur notre cluster: l'API Kubernetes elle-même.

---

## services *ClusterIP*

- Un service `ClusterIP` est interne, disponible uniquement depuis le cluster

- C'est utile pour faire l'introspection depuis l'intérieur de conteneurs.

.exercise[

- Essayer de se connecter à l'API:
  ```bash
  curl -k https://`10.96.0.1`
  ```
  - `-k` est spécifié pour désactiver la vérification de certificat

  - Attention à bien remplacer 10.96.0.1 avec l'IP CLUSTER affichée par `kubectl get svc`

]

NB :sur Docker for Desktop, l'API n'est accessible que sur `https://localhost:6443/`

--

L'erreur que vous voyez était attendue: l'API Kubernetes exige une identification.

---

## Lister les conteneurs qui tournent

- Les conteneurs existent à travers des *pods*.

- Un _pod_ est un groupe de conteneurs:

  - qui tournent ensemble (sur le même noeud)

  - qui partagent des ressources (RAM, CPU; mais aussi réseau et volumes)

.exercise[

- Lister les _pods_ de notre cluster:
  ```bash
  kubectl get pods
  ```

]

--

*Ce ne sont pas là les _pods_ que nous cherchons.* Mais où sont-ils alors?!?

---

## Namespaces

- Les espaces de nommage (_namespaces_) nous permettent de cloisonner des ressources.

.exercise[

- Lister les _namespaces_ de notre cluster avec une de ces commandes:
  ```bash
  kubectl get namespaces
  kubectl get namespace
  kubectl get ns
  ```

]

--

*Vous savez quoi... Ce machin `kube-system` m'a l'air suspect.*

*En fait, je suis plutôt sûr de l'avoir vu tout à l'heure, quand on a tapé:*

`kubectl describe node node1`

---

## Accéder aux _namespaces_

- Par défaut, `kubectl` utilise le _namespace_... `default`

- On peut montrer toutes les ressources avec `--all-namespaces`

.exercise[

- Lister les _pods_ à travers tous les _namespaces_:

  ```bash
  kubectl get pods --all-namespaces
  ```

- Depuis Kubernetes 1.14, on peut aussi taper `-A` pour faire plus court:
  ```bash
  kubectl get pods -A
  ```

*Et voici nos pods système!*

---

## A quoi servent ces _pods_ du plan de contrôle?

- `etcd` est notre serveur etcd

- `kube-apiserver` est le serveur API

- `kube-controller-manager` et `kube-scheduler` sont d'autres composants maître

- `coredns` fournit une découverte de services basé sur le DNS ([il remplace kube-dns depuis 1.11](https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/))

- `kube-proxy` tourne sur chaque _node_ et gère le _mapping_ de ports etc.

- `weave` est le composant qui gère les réseaux superposés sur chaque noeud

- la colonne `READY` indique le nombre de conteneurs dans chaque _pod_

- les _pods_ avec un nom qui finit en `-node1` sont les composants maître
  <br/>
  ils sont spécifiquement "scotchés" au noeud maître.

---

## Viser un autre _namespace_

- On peut aussi examiner un autre namespace (que `default`)

.exercise[

- Lister uniquement les pods du namespace `kube-system`:
  ```bash
  kubectl get pods --namespace=kube-system
  kubectl get pods -n kube-system
  ```

]

---

## _Namespaces_ selon les commandes `kubectl`

- On peut combiner `-n`/`--namespace` avec presque toute commande

- Exemple:

  - `kubectl create --namespace=X` pour créer quelque chose dans le _namespace_ X

- On peut utiliser `-A`/`--all-namespaces` avec la plupart des commandes qui manipulent plein d'objets à la fois

- Exemples:

  - `kubectl delete` supprime des ressources à travers plusieurs _namespaces_

  - `kubectl label` ajoute/supprime des labels à travers plusieurs _namespaces_

---

class: extra-details

## Qu'en est-il de ce `kube-public`?

.exercise[

- Lister les _pods_ dans le _namespace_ `kube-public`:
  ```bash
  kubectl -n kube-public get pods
  ```

]

Rien!

`kube-public` est créé par kubeadm et [utilisé pour établie une sécurité de base](https://kubernetes.io/blog/2017/01/stronger-foundation-for-creating-and-managing-kubernetes-clusters)

---

class: extra-details

## Explorer `kube-public`

- Le seul objet intéressant dans `kube-public` est un `ConfigMap` nommé `cluster-info`

.exercise[

- Lister les ConfigMaps dans le _namespace_ `kube-public`:
  ```bash
  kubectl -n kube-public get configmaps
  ```

- Inspecter `cluster-info`:
  ```bash
  kubectl -n kube-public get configmap cluster-info -o yaml
  ```

]

Noter l'URI `selfLink`: `/api/v1/namespaces/kube-public/configmaps/cluster-info`

On pourrait en avoir besoin!

---

class: extra-details

## Accéder à `cluster-info`

- Plus tôt, en interrogeant le serveur API, on a reçu une réponse `Forbidden`

- Mais `cluster-info` est lisible par tous (y compris sans authentification)

.exercise[

- Récupérer `cluster-info`:
  ```bash
  curl -k https://10.96.0.1/api/v1/namespaces/kube-public/configmaps/cluster-info
  ```

]

- Nous sommes capables d'accéder à `cluster-info` (sans auth)

- Il contient un fichier `kubeconfig`

---

class: extra-details

## Récupérer `kubeconfig`

- On peut facilement extraire le conenu du fichier `kubeconfig` de cette ConfigMap

.exercise[

- Afficher le contenu de `kubeconfig`:
  ```bash
    curl -sk https://10.96.0.1/api/v1/namespaces/kube-public/configmaps/cluster-info \
         | jq -r .data.kubeconfig
  ```

]

- Ce fichier contient l'adresse canonique du serveur d'API, et la clé publique du CA.

- Ce fichier *ne contient pas* les clés client ou tokens

- Ce ne sont pas des infos sensibles, mais c'est essentiel pour établir une connexion sécurisée.

---

class: extra-details

## Qu'en est-il de `kube-node-lease`?

- Depuis Kubernetes 1.14, il y a un namespace `kube-node-lease`

  (ou dès la version 1.13 si la fonction NodeLease était activée)

- Ce namespace contient un objet Lease par node

- Un *Node lease* est une nouvelle manière d'implémenter les _heartbeat_ de _node_

  (c'est-à-dire qu'une node va contacter le _master_  de temps à autre et dire "Je suis vivant!")

- Pour plus de détails, voir [KEP-0009] ou la [doc de contrôleur de node]

[KEP-0009]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/0009-node-heartbeat.md
[node controller documentation]: https://kubernetes.io/docs/concepts/architecture/nodes/#node-controller
