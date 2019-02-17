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

- Montrer la capacité de toutes nos noeuds sous forme de flux d'objets JSON:
  ```bash
    kubectl get nodes -o json | 
            jq ".items[] | {name:.metadata.name} + .status.capacity"
  ```

]

---

## Qu'est-ce qui tourne?

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

Chaque fois, `type` peut être singulier, pluriel ou un nom abrégé

---

## Services

- A *service* is a stable endpoint to connect to "something"

  (In the initial proposal, they were called "portals")

.exercise[

- List the services on our cluster with one of these commands:
  ```bash
  kubectl get services
  kubectl get svc
  ```

]

--

There is already one service on our cluster: the Kubernetes API itself.

---

## ClusterIP services

- A `ClusterIP` service is internal, available from the cluster only

- This is useful for introspection from within containers

.exercise[

- Try to connect to the API:
  ```bash
  curl -k https://`10.96.0.1`
  ```
  
  - `-k` is used to skip certificate verification

  - Make sure to replace 10.96.0.1 with the CLUSTER-IP shown by `kubectl get svc`

]

--

The error that we see is expected: the Kubernetes API requires authentication.

---

## Listing running containers

- Containers are manipulated through *pods*

- A pod is a group of containers:

 - running together (on the same node)

 - sharing resources (RAM, CPU; but also network, volumes)

.exercise[

- List pods on our cluster:
  ```bash
  kubectl get pods
  ```

]

--

*These are not the pods you're looking for.* But where are they?!?

---

## Namespaces

- Namespaces allow us to segregate resources

.exercise[

- List the namespaces on our cluster with one of these commands:
  ```bash
  kubectl get namespaces
  kubectl get namespace
  kubectl get ns
  ```

]

--

*You know what ... This `kube-system` thing looks suspicious.*

---

## Accessing namespaces

- By default, `kubectl` uses the `default` namespace

- We can switch to a different namespace with the `-n` option

.exercise[

- List the pods in the `kube-system` namespace:
  ```bash
  kubectl -n kube-system get pods
  ```

]

--

*Ding ding ding ding ding!*

The `kube-system` namespace is used for the control plane.

---

## What are all these control plane pods?

- `etcd` is our etcd server

- `kube-apiserver` is the API server

- `kube-controller-manager` and `kube-scheduler` are other master components

- `coredns` provides DNS-based service discovery ([replacing kube-dns as of 1.11](https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/))

- `kube-proxy` is the (per-node) component managing port mappings and such

- `weave` is the (per-node) component managing the network overlay

- the `READY` column indicates the number of containers in each pod

- the pods with a name ending with `-node1` are the master components
  <br/>
  (they have been specifically "pinned" to the master node)

---

## What about `kube-public`?

.exercise[

- List the pods in the `kube-public` namespace:
  ```bash
  kubectl -n kube-public get pods
  ```

]

--

- Maybe it doesn't have pods, but what secrets is `kube-public` keeping?

--

.exercise[

- List the secrets in the `kube-public` namespace:
  ```bash
  kubectl -n kube-public get secrets
  ```

]
--

- `kube-public` is created by kubeadm & [used for security bootstrapping](https://kubernetes.io/blog/2017/01/stronger-foundation-for-creating-and-managing-kubernetes-clusters)
