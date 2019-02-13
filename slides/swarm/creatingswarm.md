# Créer notre premier Swarm

- Le cluster est initialisé avec `docker swarm init`

- Cette commande devrait être lancée depuis la première _node_ d'amorçage.

- .warning[NE PAS exécuter `docker swarm init` sur d'autres _nodes_!]

  Vous auriez plusieurs cluster disjoints.

.exercise[

- Créer notre cluster depuis node1:
  ```bash
  docker swarm init
  ```

]

--

class: advertise-addr

Si Docker vous dit `could not choose an IP address to advertise`, regardez la prochaine diapo!

---

class: advertise-addr

## Adresse IP à annoncer

- En lançant le mode Swarm, chaque noeud *annonce* son adresse aux autres.
  <br/>
  (i.e. il leur dit *"vous pouvez me contacter sur 10.1.2.3:2377"*)

- Si le noeud a une seule adresse IP, c'est activé automatiquement
  <br/>
  (Les adresses de l'interface _loopback_ et Docker bridge sont ignorées)

- Si le noeud à plusieurs adresses IP, vous **devez** spécifier laquelle utiliser
  <br/>
  (Docker refusera d'en choisir une au hasard)

- On peut indiquer une adresse IP ou un nom d'interface
  <br/>
  (Dans ce dernier cas, Docker va lire l'adresse IP de l'interface et l'utiliser)

- On peut aussi spécifier un numéro de port
  <br/>
  (autrement, le port par défaut 2377 sera utilisé)

---

class: advertise-addr

## Utiliser un numéro de port non standard

- Changer le port *annoncé* ne change pas le port *d'écoute*

- Si on passe uniquement `--advertise-addr eth0:7777`, Swarm va quand même écouter sur 2377

- Vous devrez problablement aussi passer l'option `--listen-addr eth0:7777`

- C'est utile dans le cas où il faut s'adapter à des scénarios où les ports *doivent* être différents
  <br/>
  (mapping de ports, répartiteurs de charge...)

Exemple pour lancer Swarm sur un port différent:

```bash
docker swarm init --advertise-addr eth0:7777 --listen-addr eth0:7777
```

---

class: advertise-addr

## Quelle adresse IP devrait-on annoncer?

- Si vos noeuds ont une seule adresse IP, il est plus sûr de laisser l'auto-détection agir.

  .small[(Sauf si vos instances ont des adresses ip publiques et privées différentes, par ex.
  sur EC2, et que vous montez un Swarm impliquant des noeurs à l'intérieur et à l'extérieur
  du réseau privé: alors vous devriez annoncer l'adresse publique.)]

- Si vos noeuds ont plusieurs adresses IP, choisissez une adresse qui est visible
  *par tous les autres noeuds* du Swarm.

- Si vous êtes sur [play-with-docker](http://play-with-docker.com/), indiquez l'adresse
  IP affichée à coté du nom de la _node_.

  .small[(C'est l'adresse de votre noeud sur votre réseau privé interne superposé.
  L'autre adresse que vous pourriez voir est l'adresse de votre noeud sur le réseau
  `docker_gwbridge`, qui est utilisée pour le trafic sortant.)]

Exemples:

```bash
docker swarm init --advertise-addr 172.24.0.2
docker swarm init --advertise-addr eth0
```

---

class: extra-details

## Utiliser une interface séparée pour le circuit de données

- Vous pouvez indiquer différentes interfaces (ou adresses IP) pour le contrôle et la donnée.

- On précisera le _circuit du plan de contrôle_ avec `--advertise-addr` et `--listen-addr`

  (Cela sera utile  pour la communication manager/worker dans SwarmKit, l'élection du leader, etc.)

- On précisera le _circuit du plan de données_ avec `--data-path-addr`

  (Cela sera utilisé pour le trafic entre conteneurs)

- Les deux options acceptent soit une adresse IP, ou un nom d'interface

  (En indiquant un nom d'interface, Docker choisira sa première adresse IP)

---

## Génération de jeton

- Dans la réponse à `docker swarm init`, nous avons un message
  confirmant que notre noeud est maintenant le (seul) manager:

  ```
  Swarm initialized: current node (8jud...) is now a manager.
  ```

- Docker a généré deux jetons de sécurité (comme une phrase de passe, ou un mot de passe) pour notre cluster

- La ligne de commande nous montre la commande à lancer sur les autres _nodes_ pour les ajouter au cluster
  sous forme d'un jeton de sécurité:

  ```
    To add a worker to this swarm, run the following command:
      docker swarm join \
      --token SWMTKN-1-59fl4ak4nqjmao1ofttrc4eprhrola2l87... \
      172.31.4.182:2377
  ```

---

class: extra-details

## Vérifier que le mode Swarm est activé

.exercise[

- Lancer la commande classique `docker info`:
  ```bash
  docker info
  ```

]

L'affichage devrait comporter:

```
Swarm: active
 NodeID: 8jud7o8dax3zxbags3f8yox4b
 Is Manager: true
 ClusterID: 2vcw2oa9rjps3a24m91xhvv0c
 ...
```

---

## Notre première commande en mode Swarm

- Essayons exactement la même commande que précédemment

.exercise[

- Lister les noeuds (enfin, le seul) de notre cluster:
  ```bash
  docker node ls
  ```

]

L'affichage devrait ressembler à ce qui suit:
```
ID             HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
8jud...ox4b *  node1     Ready   Active        Leader
```

---

## Ajouter des noeuds au Swarm

- Un cluster avec une seule node n'est pas marrant

- Ajoutons `node2`!

- On a besoin du _token_ qu'on a vu plus tôt

--

- Vous l'avez noté quelque part, pas vrai?

--

- Pas de panique, on peut le retrouver facilement .emoji[😏]

---

## Ajouter des noeuds au Swarm

.exercise[

- Afficher le _token_ à nouveau:
  ```bash
  docker swarm join-token worker
  ```

- Se connecter à `node2`:
  ```bash
  ssh node2
  ```

- Copier-coller la commande `docker swarm join ...`
  <br/>(celle qui a été affichée juste avant)

<!-- ```copypaste docker swarm join --token SWMTKN.*?:2377``` -->

]

---

class: extra-details

## Vérifier que la node a été vraiment ajoutée

- Restez sur `node2` pour l'instant!

.exercise[

- On peut encore lancer `docker info` pour vérifier que la node participe au Swarm:
  ```bash
  docker info | grep ^Swarm
  ```

]

- Toutefois, les commandes Swarm ne passeront pas; comme, par ex.:
  ```bash
  docker node ls
  ```

<!-- Ignore errors: .dummy[```wait not a swarm manager```] -->

- C'est parce que le noeud nouvellement ajouté est un *worker*
- Seuls les *managers* peuvent répondre à des commandes spécial Swarm.

---

## Afficher notre cluster de 2 noeuds

- Retournons sur `node1` et voyons quelle tête a notre cluster

.exercise[

- Basculer vers `node1` (avec `exit`, `Ctrl-D` ...)

<!-- ```keys ^D``` -->

- Afficher le cluster depuis `node1`, qui est un *manager*:
  ```bash
  docker node ls
  ```

]

L'affichage devrait être similaire à ce qui suit:
```
ID             HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
8jud...ox4b *  node1     Ready   Active        Leader
ehb0...4fvx    node2     Ready   Active
```

---

class: under-the-hood

## Sous le capot: docker swarm init

Quand on lance `docker swarm init`:

- une paire de clés est créée pour le CA racine de notre Swarm

- une paire de clés est créée sur la première node

- un certificat est émis pour cette node

- les _tokens_ d'entrée sont créés

---

class: under-the-hood

## Sous le capot: tokens d'entrée

Il existe un jeton pour *entrer en tant que worker*, et un autre pour *entrer en tant que manager*.

Les _tokens_ d'entrée ont deux parties:

 - une clé secrète (empêchant les nodes non autorisées d'entrer)

 - une empreinte digitale du certificat racine du CA (empêchant les attaques _MITM_)

Si un _token_ est compromis, on peut en changer instantanément avec:
```
docker swarm join-token --rotate <worker|manager>
```

---

class: under-the-hood

## Sous le capot: docker swarm join

Quand une _node_ rejoint le Swarm:

- on lui délivre sa propre paire de clés, signée par le CA racine

- si cette node est un _manager_:

  - elle rejoint le consensus Raft
  - elle se connecte au _leader_ en cours
  - elle accepte des connexions de la part des *workers*

- si cette node est un *worker*:

  - elle se connecte à un des managers (_leader_ ou _follower_)

---

class: under-the-hood

## Sous le capot: communication de cluster

- Le *plan de contrôle* est chiffré avec AES-GCM; une rotation de clés intervient toutes les 12 heures

- L'identification est implémentée via un TLS mutuel; la rotation de certificats se fait tous les 90 jours

  (`docker swarm update` permet de changer ce délai, ou d'utiliser un CA externe)

- Le *plan de données* (communication entre conteneurs) n'est pas chiffré par défaut

  (mais on peut l'activer au niveau de chaque réseau, avec IPSEC, exploitant un cryptage
  matériel si disponible)

---

class: under-the-hood

## Sous le capot: je veux en savoir plus!

Revisitez les concepts de SwarmKit:

- Docker 1.12 Swarm Mode Deep Dive Part 1: Topology
  ([video](https://www.youtube.com/watch?v=dooPhkXT9yI))

- Docker 1.12 Swarm Mode Deep Dive Part 2: Orchestration
  ([video](https://www.youtube.com/watch?v=_F6PSP-qhdA))

Quelques présentations du Docker Distributed Systems Summit à Berlin:

- Heart of the SwarmKit: Topology Management
  ([slides](https://speakerdeck.com/aluzzardi/heart-of-the-swarmkit-topology-management))

- Heart of the SwarmKit: Store, Topology & Object Model
  ([slides](http://www.slideshare.net/Docker/heart-of-the-swarmkit-store-topology-object-model))
  ([video](https://www.youtube.com/watch?v=EmePhjGnCXY))

Et les présentations _Black Belt_ à DockerCon

.blackbelt[DC17US: Everything You Thought You Already Knew About Orchestration
 ([video](https://www.youtube.com/watch?v=Qsv-q8WbIZY&list=PLkA60AVN3hh-biQ6SCtBJ-WVTyBmmYho8&index=6))]

.blackbelt[DC17EU: Container Orchestration from Theory to Practice
 ([video](https://dockercon.docker.com/watch/5fhwnQxW8on1TKxPwwXZ5r))]

