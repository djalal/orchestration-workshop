# Exposer des conteneurs

- `kubectl expose` crée un *service* pour des _pods_ existant

- Un *service* est une adresse stable pour un (ou plusieurs) _pods_

- Si on veut se connecter à nos _pods_, on doit déclarer un nouveau *service*

- Une fois que le service est créé, CoreDNS va nous permettre d'y accéder par son nom

  (i.e après avoir créé le service `hello`, le nom `hello` va pointer quelque part)

- Il y a différents types de services, détaillé dans les diapos suivantes:

  `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`

---

## Types de service de base

- `ClusterIP` (type par défaut)

  - une adresse IP virtuelle est allouée au service (dans un sous-réseau privé interne)
  - cette adresse IP est accessible uniquement de l'intérieur du cluster (noeuds et _pods_)
  - notre code peut se connecter au service par le numéro de port d'origine.

- `NodePort`

  - un port est alloué pour le service (par défaut, entre 30000 et 32768)
  - ce port est exposé sur *toutes les nodes* et quiconque peut s'y connecter
  - notre code doit être modifié pour pouvoir s'y connecter

Ces types de service sont toujours disponibles.

Sous le capot: `kube-proxy` passe par un proxy utilisateur et un tas de règles `iptables`.

---

## Autres types de service

- `LoadBalancer`

  - un répartiteur de charge externe est alloué pour le service
  - le répartiteur de charge est configuré en accord
    <br/>(par ex.: un service `NodePort` est créé, et le répartiteur y envoit le traffic vers son port)
  - disponible seulement quand l'infrastructure sous-jacente fournit une sorte de "load balancer as a service"
    <br/>(e.g. AWS, Azure, GCE, OpenStack...)

- `ExternalName`

  - l'entrée DNS gérée par CoreDNS est juste un  enregistrement `CNAME`
  - ni port, ni adresse IP, ni rien d'autre n'est alloué

---

## Lancer des conteneurs avec ouverture de port

- Puisque `ping` n'a nulle part où se connecter, nous allons lancer quelque chose d'autre

- On pourrait utiliser l'image officielle `nginx`, mais...

  ... comment distinguer un backend d'un autre!

- On va plutôt passer par `jpetazzo/httpenv`, un petit serveur HTTP écrit en Go

- `jpetazzo/httpenv` écoute sur le port 8888

- Il renvoie ses variables d'environnement au format JSON

- Les variables d'environnement vont inclure `HOSTNAME`, qui aura pour valeur le nom du _pod_

  (et de ce fait, elle aura une valeur différente pour chaque backend)

---

## Créer un déploiement pour notre serveur HTTP

- On *pourrait* lancer `kubectl run httpenv --image=jpetazzo/httpenv` ...

- Mais puisque `kubectl run` est bientôt obsolète, voyons voir comment utiliser `kubectl create` à sa place.

.exercise[

- Dans une autre fenêtre, surveiller les pods (pour voir quand ils seront créés):
  ```bash
  kubectl get pods -w
  ```

<!-- ```keys ^C``` -->

- Créer un déploiement pour ce serveur HTTP super-léger:
server:
  ```bash
  kubectl create deployment httpenv --image=jpetazzo/httpenv
  ```

- Escalader le déploiement à 10 replicas:
  ```bash
  kubectl scale deployment httpenv --replicas=10
  ```

]

---

## Exposer notre déploiement

- Nous allons déclarer un service `ClusterIP` par défaut

.exercise[

- Exposer le port HTTP de notre serveur:
  ```bash
  kubectl expose deployment httpenv --port 8888
  ```

- Rechercher quelles adresses IP ont été alloués:
  ```bash
  kubectl get service
  ```

]

---

## Services: constructions de 4e couche

- On peut assigner des adresses IP aux services, mais elles restent dans la *couche 4*

  (i.e un service n'est pas une adresse IP; c'est une IP+ protocole + port)

- La raison en est l'implémentation actuelle de `kube-proxy`

  (qui se base sur des mécanismes qui ne supportent pas la couche n°3)

- Il en résulte que: vous *devez* indiquer le numéro de port de votre service

- Lancer des services avec un (ou plusieurs) ports au hasard demandent des bidouilles

  (comme passer le mode réseau au niveau hôte)

---

## Tester notre service

- Nous allons maintenant envoyer quelques requêtes HTTP à nos _pods_

.exercise[

- Obtenir l'adresse IP qui a été allouée à notre service, *sous forme de script*:
  ```bash
  IP=$(kubectl get svc httpenv -o go-template --template '{{ .spec.clusterIP }}')
  ```

<!--
```hide kubectl wait deploy httpenv --for condition=available```
-->

- Envoyer quelques requêtes:
  ```bash
  curl http://$IP:8888/
  ```

- Trop de lignes? Filtrer avec `jq`:
  ```bash
  curl -s http://$IP:8888/ | jq .HOSTNAME
  ```

]

--

Essayez-le plusieurs fois! Nos requêtes sont réparties à travers plusieurs _pods_.

---

class: extra-details

## Si on n'a pas besoin d'un répartiteur de charge

- Parfois, on voudrait accéder à nos services directement:

  - si on veut économiser un petit bout de latence (typiquement < 1ms)

  - si on a besoin de se connecter à n'importe quel port (au lieu de quelques ports fixes)

  - si on a besoin de communiquer sur un autre protocole qu'UDP ou TCP

  - si on veut décider comment répartir la charge depuis le client

  - ...

- Dans ce cas, on peut utiliser un "headless service"

---

class: extra-details

## Services Headless

- On obtient un service _headless_ en assignant la valeur `None` au champ `clusterIP`

  (Soit avec `--cluster-ip=None`, ou via un bout de YAML)

- Puisqu'il n'y a pas d'adresse IP virtuelle, il n'y pas non plus de répartiteur de charge

- CoreDNS va retourner les adresses IP des _pods_ comme autant d'enregistrements `A`

- C'est un moyen facile de recenser tous les réplicas d'un deploiement.

---

class: extra-details

## Services et points d'entrée

- Un service dispose d'un certain nombre de "points d'entrée" (_endpoint_)

- Chaque _endpoint_ est une combinaison "hôte + port" qui pointe vers le service

- Les points d'entrée sont maintenus et mis à jour automatiquement par Kubernetes

.exercise[

- Vérifier les _endpoints_ que Kubernetes a associé au service `httpenv`:
  ```bash
  kubectl describe service httpenv
  ```

]

Dans l'affichage, il y aura une ligne commençant par `Endpoints:`.

Cette ligne liste un tas d'adresses au format `host:port`.

---

class: extra-details

## Afficher les détails d'un _endpoint_

- Dans le cas de nombreux _endpoints_, les commandes d'affichage tronquent la liste
  ```bash
  kubectl get endpoints
  ```

- Pour sortir la liste complète, on peut passer par la commande suivante:
  ```bash
  kubectl describe endpoints httpenv
  kubectl get endpoints httpenv -o yaml
  ```

- Ces commandes vont nous montrer une liste d'adresses IP

- On devrait retrouver ces mêmes adresses IP dans les _pods_ correspondants:
  ```bash
  kubectl get pods -l app=httpenv -o wide
  ```

---

class: extra-details

## `endpoints`, pas `endpoint`

- `endpoints` est la seule ressource qui ne s'écrit jamais au singulier
```bash
$ kubectl get endpoint
error: the server doesn't have a resource type "endpoint"
```

- C'est parce que le type lui-même est pluriel (contrairement à toutes les autres ressources)

- Il n'existe aucun objet `endpoint`: `type Endpoints struct`

- Le type ne représente pas un seul _endpoint_, mais une liste d'_endpoints_

---

## Exposer des services au monde extérieur

- Le type par défaut (ClusterIP) ne fonctionne que pour le trafic interne

- Si nous voulons accepter du trafic depuis l'extene, on devra utiliser soit:

  - NodePort (exposer un service sur un port TCP entre 30000 et 32768)

  - LoadBalancer (si notre fournisseur de cloud est compatible)

  - ExternalIP (passer par l'adresse IP externe d'une node)

  - Ingress (mécanisme spécial pour les services HTTP)

*Nous détaillerons l'usage des NodePorts et Ingresses plus loin.*
