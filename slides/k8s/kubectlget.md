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

## Qu'est-ce qui tourne là-dessous?

- `kubectl` dispose de capacité d'introspection solides

- On peut lister les types de ressources en lançant `kubectl api-resources`
  <br/>
  (Sur Kubernetes 1.10 et les versions précédentes, il fallait taper `kubectl get`)

- Pour détailler une ressource, c'est:
  ```bash
  kubectl describe type/name
  kubectl describe type name
  ```

- La définition d'un type de ressource s'affiche avec:
  ```bash
  kubectl explain type
  ```

Chaque fois, `type` peut être un nom au singulier, au pluriel ou sous forme abrégée

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

---

## Accéder aux _namespaces_

- Par défaut, `kubectl` utilise le _namespace_... `default`

- On peut basculer sur un _namespace_ différent avec l'option `-n`

.exercise[

- Lister les _pods_ dans le _namespace_ `kube-system`:
  ```bash
  kubectl -n kube-system get pods
  ```

]

--

*Alerte Alerte Alerte Alerte Alerte Alerte*

Le _namespace_ `kube-system` est utilisé pour le plan de contrôle.

---

## A quoi servent ces _pods_ du plan de contrôle?

- `etcd` est notre serveur etcd

- `kube-apiserver` est le serveur API

- `kube-controller-manager` et `kube-scheduler` sont d'autres composants maître

- `coredns` fournit une découverte de services basé sur le DNS ([il remplace kube-dns depuis 1.11](https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/))

- `kube-proxy` est tourne sur chaque _node_ et gère le _mapping_ de ports etc.

- `weave` est le composant qui gère les réseaux superposés sur chaque noeud

- la colonne `READY` indique le nombre de conteneurs dans chaque _pod_

- les _pods_ avec un nom qui finit en `-node1` sont les composants maître
  <br/>
  ils sont spécifiquement "scotchés" au noeud maître.


---

## Qu'en est-il de `kube-public`?

.exercise[

- Lister les _pods_ dans le _namespace_ `kube-public`:
  ```bash
  kubectl -n kube-public get pods
  ```

]

--

- Peut-être qu'il n'a pas de _pods_, mais quels secrets nous cache `kube-public`?

--

.exercise[

- Lister les secrets dans le _namespace_ `kube-public`:
  ```bash
  kubectl -n kube-public get secrets
  ```

]
--

- `kube-public` est créé par kubeadm et [utilisé pour établir une sécurité de base](https://kubernetes.io/blog/2017/01/stronger-foundation-for-creating-and-managing-kubernetes-clusters)
