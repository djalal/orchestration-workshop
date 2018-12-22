
class: title

# Le _Container Network Model_

![A denser graph network](images/title-the-container-network-model.jpg)

---

## Objectifs

Nous aborderons le CNM (Modèle de Réseau pour Container)

A la fin de la leçon, vous serez capable de:

* Créer un réseau privé pour un groupe de _containers_;

* Utiliser le nommage de _container_ pour connecter les services ensemble;

* Connecter et déconnecter dynamiquement des containers à des réseaux;

* Affecter l'adresse IP à un container.

Nous expliquerons aussi le principe des réseaux _overlay_ et des plugins de réseau.

---

## Le _Container Network Model_

Le CNM a été introduit dans Engine 1.9.0 (Novembre 2015).

Le CNM ajoute la notion de *network*, et une commande principale pour manipuler et inspecter ces réseaux: `docker network`.

```bash
$ docker network ls
NETWORK ID          NAME                DRIVER
6bde79dfcf70        bridge              bridge
8d9c78725538        none                null
eb0eeab782f4        host                host
4c1ff84d6d3f        blog-dev            overlay
228a4355d548        blog-prod           overlay
```

---

## Qu'est-ce qu'il y a dans un réseau?

* Dans le concept, un réseau est un switch virtuel;

* Il peut être local (dans un Engine simple) ou global (transversal à plusieurs hôtes);

* Un réseau possède un sous-réseau IP associé;

* Docker va affecter de nouvelles adresses IP aux _containers_ connectés à ce réseau;

* Des _containers_ peuvent être connectés à plusieurs réseaux;

* Des _containers_ peuvent se voir affectés des noms et alias par réseau;

* Les noms et alias sont résolus via un serveur DNS embarqué.

---

## Détails d'implémentation de réseau

* Un réseau est géré par un _driver_.

* Les *drivers* inclus par défaut:

  * `bridge` (par défaut)
  * `none`
  * `host`
  * `macvlan`

* Un *driver* multi-hôte, *overlay*, est inclus sans installation supplémentaire (pour les clusters Swarm).

* Des *drivers* supplémentaires sont disponibles sous forme de _plugins_ (OVS, VLAN, etc)

* Un réseau peut avoir son propre IPAM (allocation d'IP)

---

class: extra-details

## Différences avec le CNI

* CNI = Container Network Interface

* CNI est utilisé en particulier par Kubernetes

* Dans CNI, toutes les _nodes_ et _containers_ sont sur un seul et même réseau IP

* CNI et CNM offrent les mêmes fonctions, mais via des méthodes très différentes

---

class: pic

## _Container_ simple dans un réseau Docker

![bridge0](images/bridge1.png)

---

class: pic

## Deux _containers_ sur un seul réseau Docker

![bridge2](images/bridge2.png)

---

class: pic

## Deux _containers_ sur deux réseaux Docker

![bridge3](images/bridge3.png)

---

## Créer un réseau

Essayons de déclarer un nouveau réseau appelé `dev`.

```bash
$ docker network create dev
4c1ff84d6d3f1733d3e233ee039cac276f425a9d5228a4355d54878293a889ba
```

Le réseau est maintenant visible avec la commande `network ls`;

```bash
$ docker network ls
NETWORK ID          NAME                DRIVER
6bde79dfcf70        bridge              bridge
8d9c78725538        none                null
eb0eeab782f4        host                host
4c1ff84d6d3f        dev                 bridge
```

---

## Placer des _containers_ sur un réseau

Nous allons créer un *container* nommé sur ce réseau.

Il sera disponible via son nom, `es`.

```bash
$ docker run -d --name es --net dev elasticsearch:2
8abb80e229ce8926c7223beb69699f5f34d6f1d438bfc5682db893e798046863
```

---

## Communication entre _containers_

Et maintenant, ajoutons un autre _container_ sur ce réseau.

.small[
```bash
$ docker run -ti --net dev alpine sh
root@0ecccdfa45ef:/#
```
]

Depuis ce nouveau _container_, nous pouvons résoudre et ping l'autre, en utilisant son nom:

.small[
```bash
/ # ping es
PING es (172.18.0.2) 56(84) bytes of data.
64 bytes from es.dev (172.18.0.2): icmp_seq=1 ttl=64 time=0.221 ms
64 bytes from es.dev (172.18.0.2): icmp_seq=2 ttl=64 time=0.114 ms
64 bytes from es.dev (172.18.0.2): icmp_seq=3 ttl=64 time=0.114 ms
^C
--- es ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.114/0.149/0.221/0.052 ms
root@0ecccdfa45ef:/#
```
]

---

class: extra-details

## Résoudre des adresses de *container*

Dans le Docker Engine 1.9, la résolution de nom est implémentée avec `/etc/hosts`, et mise à jour chaque fois que les containers sont ajoutés/supprimés.

.small[
```bash
[root@0ecccdfa45ef /]# cat /etc/hosts
172.18.0.3  0ecccdfa45ef
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.18.0.2      es
172.18.0.2      es.dev
```
]

Dans le Docker Engine 1.10, ceci a été remplacé par une résolution dynamique.

(Cela résoud les _race conditions_ lors de la mise à jour de `/etc/hosts`)

---

# _Service discovery_ avec les _containers_

* Essayons de lancer une application reposant sur deux _containers_;

* Le premier _container_ est un serveur web;

* L'autre est une base de données redis;

* Nous les placerons tous deux sur le réseau `dev` créé auparavant;


---

## Lancer le serveur web

* L'application est fournie par l'image `jpetazzo/trainingwheels`.

* Nous en savons peu sur elle, donc nous la lançons et on verra ce qui arrivera!

Démarrer le _container_, en publiant tous ses ports:

```bash
$ docker run --net dev -d -P jpetazzo/trainingwheels
```

Vérifier quel port lui a été alloué:

```bash
$ docker ps -l
```

---

## Tester le serveur web

* Si nous ouvrons l'application à ce stage, nous verrons une page d'erreur:

![Trainingwheels error](images/trainingwheels-error.png)

* C'est parce que le service Redis n'est pas lancé.

* Ce *container* essaie de résoudre le nom `redis`.


Note: nous n'utilisons pas de FQDN ou une adresse IP ici; juste `redis`.

---

## Démarrer la base de données

* Nous devons démarrer un _container_ Redis.

* Ce *container* doit être sur le même réseau que le serveur web.

* Il doit porter le nom correct (`redis`) pour que l'application le trouve.

Démarrer le _container_;

```bash
$ docker run --net dev --name redis -d redis
```

---

## Tester à nouveau le serveur web

* Si nous ouvrons l'application à présent, nous devrions voir que l'appli fonctionne correctement:

![Trainingwheels OK](images/trainingwheels-ok.png)

* Quand l'appli essaie de résoudre `redis`, au lieu d'avoir une erreur DNS, on récupère l'adresse IP de notre _container_ Redis.


---

## A propos du _scope_

* Et si nous voulions lancer plusieurs clones de notre application?

* Puisque les noms sont uniques, il ne peut y avoir qu'un seul _container_ nommé `redis`.

* Toutefois, nous pouvons forcer un nom de réseau de notre _container_ avec `--net-alias`.

* `--net-alias` a une portée par réseau, et indépendant du nom de _container_ d'origine.

---

class: extra-details

## Utiliser un alias de réseau au lieu d'un nom

Supprimons le _container_ `redis`:

```bash
$ docker rm -f redis
```

Et ajoutons un nouveau qui ne bloque pas le nom `redis`:

```bash
$ docker run --net dev --net-alias redis -d redis
```

Vérifier que l'appli fonctionne toujours (mais le compteur est revenu à 1,
car on a dégagé l'ancien _container_ Redis).

---

class: extra-details

## Tout nom est *spécifique* à un seul réseau

Essayons de _ping_ notre _container_ `es` depuis un autre _container_, dans le cas où l'autre _container_ n'est *pas* sur le réseau `dev`

```bash
$ docker run --rm alpine ping es
ping: bad address 'es'
```

Un nom est résolu uniquement quand les _containers_ sont sur le même réseau.

Les containers peuvent se contacter les uns les autres seulement quand ils sont sur le même réseau (vous pouvez essayer de _ping_ avec l'adresse IP pour vérifier).

---

class: extra-details

## Alias de réseau

Nous aimerions avoir un autre réseau, `prod` avec son propre _container_ `es`. Mais il ne peut y avoir qu'un seul _container_ nommé `es`!

Nous utiliserons les *alias de réseau*.

Un _container_ peut avoir plusieurs alias de réseau.

Les alias de réseau sont *locaux* à un réseau donné (qui existent juste sur ce réseau).

Plusieurs _containers_ peuvent avoir le même alias de réseau (y compris sur le même réseau). Dans Docker Engine 1.11, la résolution d'un alias de réseau renvoie l'adresse IP de tous les _containers_ disposant de cet alias.

---

class: extra-details

## Créer des _containers_ sur un autre réseau

Créez un réseau `prod`.

```bash
$ docker network create prod
5a41562fecf2d8f115bedc16865f7336232a04268bdf2bd816aecca01b68d50c
```

Nous pouvons maintenant créer plusieurs _containers_ avec un alias `es` sur le nouveau réseau `prod`.

```bash
$ docker run -d --name prod-es-1 --net-alias es --net prod elasticsearch:2
38079d21caf0c5533a391700d9e9e920724e89200083df73211081c8a356d771
$ docker run -d --name prod-es-2 --net-alias es --net prod elasticsearch:2
1820087a9c600f43159688050dcc164c298183e1d2e62d5694fd46b10ac3bc3d
```

---

class: extra-details

## Résoudre les alias de réseau

Essayons la résolution DNS, en utilisant l'outil `nslookup` livré dans l'image `alpine`.


```bash
$ docker run --net prod --rm alpine nslookup es
Name:      es
Address 1: 172.23.0.3 prod-es-2.prod
Address 2: 172.23.0.2 prod-es-1.prod
```

(On peut ignorer les erreurs `can't resolve '(null)'`)

---

class: extra-details

## Se connecter aux _containers_ avec alias

Chaque instance ElasticSearch a un nom (généré au démarrage). Ce nom est visible quand on lance une simple requête HTTP sur le point d'accès de l'API ElasticSearch.

Essayons de lancer la commande suivante plusieurs fois:

.small[
```bash
$ docker run --rm --net dev centos curl -s es:9200
{
  "name" : "Tarot",
...
}
```
]

Puis essayons la à nouveau plusierus fois en remplaçant `--net dev` par `--net prod`:

.small[
```bash
$ docker run --rm --net prod centos curl -s es:9200
{
  "name" : "The Symbiote",
...
}
```
]

---

## Bon à savoir...

* Docker ne peut créer des noms de réseau et alias sur le réseau par défaut `bridge`.

* Sachant ceci, pour utiliser ces fonctions, vous devez créer un réseau spécifique d'abord.

* Les alias de réseau ne sont *pas* uniques au sein d'un réseau donné.

* i.e plusieurs _containers_ peuvent porter le même alias sur le même réseau.

* Dans ce scénario, le serveur DNS Docker retournera plusieurs enregistrements.
  <br/>
  (i.e, vous aurez un "DNS round robin" prêt à l'emploi)

* Activer le *Mode Swarm* donne accès au traitement distribué (_clustering_) et la répartition de charge (_load balancing_) via IPVS.

* Créer les réseaux et les alias de réseau est en général automatisé par des outils comme Compose.

---

class: extra-details

## Quelques mots à propos du DNS round robin

Ne comptez pas exclusivement sur le DNS round robin pour de la répartition de charge.

Plusieurs facteurs peuvent affecter la réolution DNS, et vous pourriez avoir:

- tout le trafic dirigé vers une seule instance;
- le trafic réparti inégalement entre quelques instances;
- comportement différent selon le langage de votre application;
- comportement différent selon votre distribution de base;
- comportement différent selon d'autres facteurs (sic).


Aucun problème à utiliser le DNS pour explorer les points d'accès disponibles, mais prenez bien soin de les re-résoudre de temps à autre pour trouver les nouveaux points d'accès.


---

class: extra-details

## Réseaux spécifiques

Lors de la création de réseaux, plusieurs options peuvent être fournies:

When creating a network, extra options can be provided.

* `--internal` désactive tout trafic sortant (le réseau n'aura pas de passerelle par défaut).

* `--gateway` indique quelle adresse utiliser pour la passerelle (quand le trafic sortant est autorisé).

* `--subnet` (en notation CIDR) indique le sous-réseau à utiliser.

* `--ip-range` (en notation CIDR) indique le sous-réseau pour l'allocation.

* `--aux-address` permet de spécifier une liste d'adresse réservées (qui ne seront jamais affectées aux _containers_).

---

class: extra-details

## Choisir l'adresse IP des _containers_

* Il est possible de forcer l'addrese IP du _container_ avec `--ip`.
* L'adresse IP doit respecter le sous-réseau utilisé par le _container_

Voici ci-dessous un exemple complet.

```bash
$ docker network create --subnet 10.66.0.0/16 pubnet
42fb16ec412383db6289a3e39c3c0224f395d7f85bcb1859b279e7a564d4e135
$ docker run --net pubnet --ip 10.66.66.66 -d nginx
b2887adeb5578a01fd9c55c435cad56bbbe802350711d2743691f95743680b09
```

*Note: ne forcez pas d'adresse IP explicite de _container_ dans votre code!*

*Je répète: ne forcez pas d'adresse IP de _container_  dans votre code!*

---

## Réseaux superposés

* Les caractéristiques vues jusqu'ici fonctionnent uniquement quand les _containers_ sont sur un seul hôte.

* Si les _containers_ sont répartis sur plusieurs hôtes, nous aurons besoin d'un réseau *overlay* pour les connecter ensemble.

* Docker est livré avec un plugin de réseau par défaut, `overlay`, qui implémente un réseau superposé exploitant le concept de VXLAN, *qui s'active via le Mode Swarm*.

* D'autres plugins (Weave, Calico...) peuvent aussi fournir des réseaux superposés.

* Une fois que vous avez un réseau superposé, *toutes les fonctions utilisées dans ce chapitre fonctionne de la même manière à travers plusieurs hôtes*.

---

class: extra-details

## Réseau multi-hôtes (_overlay_)

Hors-sujet pour cet atelier d'introduction!

Instructions très rapides:
- activer le Mode Swarm (`docker swarm init` puis `docker swarm join` sur les autres noeuds)
- `docker network create mynet --driver overlay`
- `docker service create --network mynet myimage`

Voir https://jpetazzo.github.io/container.training  pour tous les détails sur les _clusters_!

---

class: extra-details

## Réseau multi-hôtes (_plugins_)

Hors-sujet pour cet atelier d'introduction!

Idée générale:

- installer le _plugin_ (souvent livré dans des _containers_)

- lancer le _plugin_ ( si c'est dans un _container_, il y a souvent besoin de paramètres supplémentaires; n'allez pas `docker run` à l'aveugle!)

- certains _plugins_ exigent une configuration ou une activation (en créant un fichier spécial qui dit à Docker "utilise le _plugin_ dont la _socket_ est au chemin suivant)

- vous pouvez ensuite `docker network create --driver plugingname`

---

## Connexion et déconnexion dynamique

* Jusqu'ici, nous avons choisi quel réseau utiliser au démarrage du _container_.

* Le Docker Engine permets aussi de la connexion/déconnexion pendant que le container tourne.

* Cette fonction est exposée via l'API Docker, et à travers deux commandes:

  * `docker network connect <network> <container>`

  * `docker network disconnect <network> <container>`


---

## Connexion dynamique à un réseau

* Nous avons un _container_ nommé `es` connecté à un réseau nommé `dev`.

* Démarrons un simple _container_ alpine sur le réseau par défaut:

  ```bash
  $ docker run -ti alpine sh
  / #
  ```

* Dans ce _container_, essayons de _ping_ le _container_ `es`:

  ```bash
  / # ping es
  ping: bad address 'es'
  ```

Cela ne fonctionne pas, mais nous allons corriger cela en connectant le _container_.

---

## Trouver l'ID du _container_ et le connecter

* Extraire l'ID de notre _container_ alpine; voici deux méthodes:

  * jeter un oeil à `/etc/hostname` dans le _container_,

  * exécuter sur le hôte `docker ps -lq`.

* Lancer la commande suivant sur l'hôte:

  ```bash
  $ docker network connect dev `<container_id>`
  ```

---

## Vérifier nos actions


* Essoayez encore `ping es` depuis le _container_.

* Cela devrait fonctionner correctement normalement:

  ```bash
  / # ping es
  PING es (172.20.0.3): 56 data bytes
  64 bytes from 172.20.0.3: seq=0 ttl=64 time=0.376 ms
  64 bytes from 172.20.0.3: seq=1 ttl=64 time=0.130 ms
  ^C
  ```

* Stoppez-le avec Ctrl-C.

---

## Examen du réseau dans le _container_

Nous pouvons lister les interfaces réseau avec `ifconfig`, `ip a`, ou `ip l`:

.small[
```bash
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
18: eth0@if19: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
20: eth1@if21: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:14:00:04 brd ff:ff:ff:ff:ff:ff
    inet 172.20.0.4/16 brd 172.20.255.255 scope global eth1
       valid_lft forever preferred_lft forever
/ #
```
]

Chaque connexion réseau est matérialisée via une interface réseau virtuelle.

Comme nous pouvons le voir, nous pouvons être connecté à plusieurs réseaux en même temps.

---

## Disconnecting from a network
## Se déconnecter d'un réseau

* Essayons ce que donne la commande symétrique pour déconnecter le _container_:

  ```bash
  $ docker network disconnect dev <container_id>
  ```


* A partir de maintenant, si on cherche à _ping_ `es`, ce ne sera pas résolu:

  ```bash
  / # ping es
  ping: bad address 'es'
  ```


* Si on essaie de _ping_ l'adresse IP directement, cela ne fonctionne plus non plus:

  ```bash
  / # ping 172.20.0.3
  ... (rien ne se passe jusqu'à ce qu'on tape Ctrl-C)
  ```

---

class: extra-details

## Network aliases are scoped per network
## Visibilité des alias de réseau par réseau


* Chaque réseau possède sa propre liste d'alias réseau.

* Comme vu précédemment: `es` est résolu avec différentes adresses selon les réseaux `dev` et `prod`.

* Si nous sommes connectés à plusieurs réseaux, la résolution passe les noms en revue dans chaque réseau (dans Docker Engine 18.03, par ordre de connexion), et arrête dès que le nom a été trouvé.

* Par conséquent, en étant connecté aux réseaux `dev` et `prod`, la résolution de `es` ne nous donnera **pas** tous les noms des services `es`, mais seulement ceux dans `dev` ou `prod`.

* Toutefois, on peut interroger `es.dev` ou `es.prod` si on a besoin.


---

class: extra-details

## En apprendre plus sur nos réseaux et noms

* Nous pouvons lancer des requêtes DNS inverses sur les adresses IP des _containers_.

* Si l'adresse IP appartient à un réseau (autre que le _bridge_ par défaut), le résultat sera:

  ```
  nom-du-premier-alias-ou-id-container.nom-reseau
  ```

* Exemple:

.small[
```bash
$ docker run -ti --net prod --net-alias hello alpine
/ # apk add --no-cache drill
...
OK: 5 MiB in 13 packages
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:AC:15:00:03
          inet addr:`172.21.0.3`  Bcast:172.21.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
...
/ # drill -t ptr `3.0.21.172`.in-addr.arpa
...
;; ANSWER SECTION:
3.0.21.172.in-addr.arpa.	600	IN	PTR	`hello.prod`.
...
```
]

---

class: extra-details

## Building with a custom network

* We can build a Dockerfile with a custom network with `docker build --network NAME`.

* This can be used to check that a build doesn't access the network.

  (But keep in mind that most Dockerfiles will fail,
  <br/>because they need to install remote packages and dependencies!)

* This may be used to access an internal package repository.

  (But try to use a multi-stage build instead, if possible!)
