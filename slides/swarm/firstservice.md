# Lancer notre premier service Swarm

- Comment lancer des services? Version courte:

  `docker run` → `docker service create`

.exercise[

- Créer un service basé sur un conteneur Alpine qui _ping_ les serveurs de Google:
  ```bash
  docker service create --name pingpong alpine ping 8.8.8.8
  ```

- Vérifier le résultat:
  ```bash
  docker service ps pingpong
  ```

]

---

## Consulter les logs de service

(Nouveau dans Docker Engine 17.05)

- Tout comme `docker logs` affiche la sortie d'un conteneur local spécifique...

- ... `docker service logs` montre les logs de tous les conteneurs d'un certain service

.exercise[

- Vérifier la sortie de notre commande ping:
  ```bash
  docker service logs pingpong
  ```

]

Les options `--follow` et `--tail` sont disponibles, ainsi que quelques autres.

Note: par défaut, quand un conteneur est détruit (par ex. en baisse de charge), ses logs sont perdus.

---

class: extra-details

## Chercher où tourne notre conteneur

- La commande `docker service ps` va nous dire où est placé notre conteneur

.exercise[

- Trouver quel `NODE` fait tourner notre conteneur:
  ```bash
  docker service ps pingpong
  ```

- Sur Play-With-Docker, cliquer sur l'onglet de cette node, ou passer par `DOCKER_HOST`

- Autrement, se connecter avec `ssh` sur cette ou lancer `$(eval docker-machine env node...)`

]

---

class: extra-details

## Afficher les logs du conteneur

.exercise[

- Constater que le conteneur tourne bien, et récupérer son ID:
  ```bash
  docker ps
  ```

- Afficher ses logs:
  ```bash
  docker logs containerID
  ```

  <!-- ```wait No such container: containerID``` -->

- Retourner sur `node1` après coup

]

---

## Dimensionner notre service

- Les services peuvent monter en charge avec une pincée de `docker service update`

.exercise[

- Escalader le service pour assurer 2 clones par node:
  ```bash
  docker service update pingpong --replicas 6
  ```

- Vérifier que nous avons bien 2 conteneurs sur la node en cours:
  ```bash
  docker ps
  ```

]

---

## Suivre le progrès du déploiement avec `--detach`

(Nouveauté du Docker Engine 17.10)

- La ligne de commande surveille les commandes qui créent/modifient/suppriment les services.

- En pratique, `--detach=false` est la valeur par défaut

  - opération synchrone
  - le ligne de commande affiche la progression de notre requête
  - elle sort uniquement  si l'opération est terminée
  - Ctrl-C permet de récupérer la main à tout moment

- `--detach=true`

  - opération asynchrone
  - la ligne de commande ne fait qu'envoyer notre requête
  - elle sort dès que la requête a été écrite dans Raft

---

## `--detach` ou ne pas `--detach`, là est la question

- `--detach=false`

  - super en apprentissage, pour voir ce qui se passe
  - pas mal aussi lors de déploiements complexes à orchestrer
    <br/>(quand on veut attendre qu'un service se lance, avant de démarrer le suivant)

- `--detach=true`

  - super pour des opérations indépendantes qui peuvent être parallélisées.

  - super pour des scripts non-interactifs (où personne ne regarde de toute façon)

.warning[`--detach=true` ne va *pas plus vite*. C'est juste qu'il *n'attend pas* la fin d'exécution.]

---

class: extra-details

## Évolutions de `--detach`

- Docker Engine 17.10 et plus: par défaut en `--detach=false`

- A partir de Docker Engine 17.05 à 17.09: par défaut en `--detach=true`

- Avant Docker 17.05: `--detach` n'existait pas.

 (Vous pouvez le remplacer par ex. avec `watch docker service ps <serviceID>`)

---

## `--detach` en action

.exercise[

- Escalader le service pour garantir 3 conteneurs par node:
  ```bash
  docker service update pingpong --replicas 9 --detach=false
  ```

- Et monter ensuite à 4 replicas par node:
  ```bash
  docker service update pingpong --replicas 12 --detach=true
  ```

]

---

## Exposer un service

- Exposer un service est possible, avec deux propriétés spéciales:

  - le port public est disponible sur *chaque node du Swarm*,

  - les requêtes provenant du port public sont réparties entre toutes les instances.

- Techniquement, on utilise l'option `-p/--publish`; pour faire vite:

  `docker run -p → docker service create -p`

- Si vous indiquer un seul numéro de port, il sera mappé sur un port démarrant
  à 30000
  <br/>(vs. 32768 pour un mappage de conteneur unique)

- On peut indiquer deux numéros de port pour configurer le numéro de port public
  <br/>(tout comme avec `docker run -p`)

---

## Exposer ElasticSearch sur son port par défaut

.exercise[

- Créer un service ElasticSearch (et lui donner un nom tant qu'on y est):
  ```bash
  docker service create --name search --publish 9200:9200 --replicas 5 \
         elasticsearch`:2`
  ```

]

Note: ne pas oublier le _tag_ **:2**!

La dernière version de l'image ElasticSearch ne peut démarrer sans une configuration obligatoire.

---

## Cycle de vie des tâches

- Pendant un déploiement, vous pourrez voir les étapes suivantes:

  - _assigned_, la _task_ a été assignée à un noeud spécifique

  - _preparing_, qui se résume à "téléchargement de l'image"

  - _starting_

  - _running_

- Quand une tâche est terminée (_stopped_, _killed_, etc.) elle ne peut être redémarrée

  (Une tâche de remplacement sera créée)

---

class: extra-details, pic

![diagramme affichant les évenements durant docker service create, par @aluzzardi](images/docker-service-create.svg)

---

## Tester notre service

- Nous avons attaché le port 9200 sur les _nodes_ au port 9200 des conteneurs.

- Essayons de communiquer avec ce port!

.exercise[

<!-- Give it a few seconds to be ready ```bash sleep 5``` -->

- Lancer la commande suivante:
  ```bash
  curl 127.0.0.1:9200
  ```

]

(Si vous recevez un `Connection refused`: félicitations, vous êtes vraiment rapide! Essayez encore.)

ElasticSearch renvoie un petit doc. JSON avec des informations de base
sur cette instance; y compris un nom de super-héros aléatoire.

---

## Tester la répartition de charge

- Si on répète notre commande `curl` encore et encore, on lire plusieurs noms.

.exercise[

- Envoyer 10 requêtes, et voir quelles instances répondent:
  ```bash
    for N in $(seq 1 10); do
      curl -s localhost:9200 | jq .name
    done
  ```

]

Note: si vous n'avez pas `jq` sur votre instance PWD, il suffit de l'installer:
```
apk add --no-cache jq
```

---

## Résultats du répartiteur de charge

Le trafic est géré par le [maillage de routage](
https://docs.docker.com/engine/swarm/ingress/) de notre cluster

Chaque requête est tour à tour transférée à une des instances.

Note: si vous essayez d'accéder au service depuis un navigateur,
vous verrez probablement la même instance encore et encore,
c'est parce que votre navigateur (contrairement à curl) essaiera
de ré-utiliser la même connexion.

---

class: pic

![routing mesh](images/ingress-routing-mesh.png)

---

## Sous le capot du _routing mesh_

- La répartition de charge est réalisée avec IPVS

- IPVS est un répartiteur de charge de haute performance, interne au noyau

- Il existe depuis quelque temps déjà (introduit dans la version 2.4)

- Chaque noeud exécute un répartiteur de charge local

  (Ce qui permet aux connections d'être routées directement à leur
  destination, sans sauts superflus)

---

## Gérer le trafic entrant (ingress)

Il y a bien des manières de s'occuper du trafic entrant dans un cluster SWarm.

- Placer tout (ou partie) des noeuds dans un champ `A` du DNS (marche bien pour les clients web)

- Assigner tout ou partie des nodes à un répartiteur de charge externe (ELB, etc.)

- Utiliser une IP virtuelle et s'assurer qu'elle est assignée à une node "vivante"

- etc.

---

class: pic

![LB externe](images/ingress-lb.png)

---

## Gérer le trafic HTTP

- Le _routing mesh_ TCP n'interprète par les en-tête HTTP

- Si on veut placer plusieurs services HTTP sur le port 80/443, il nous manque un truc.

- On peut installer NGINX ou HAProxy sur le port 80/443 pour router les requêtes vers le bon service,
mais ils auraient besoin d'écouter le Swarm pour ajuster leur config.

--

- Docker EE fournit son propre [routeur de niveau 7](https://docs.docker.com/ee/ucp/interlock/)

  - Les labels de service comme `com.docker.lb.hosts=<FQDN>` sont détectés automatiquement via l'API Docker et mettent à jour leur configuration à la volée.

--

- Deux options open source populaires:

  - [Traefik](https://traefik.io/) - reconnu, riche de fonctions, requiert de tourner sur les *managers* (par défaut), nécessite une DB clé-valeur pour la haute disponibilité.

  - [Docker Flow Proxy](http://proxy.dockerflow.com/) - utilise HAProxy, orienté Swarm, par [@vfarcic](https://twitter.com/vfarcic)

---

class: btw-labels

## Vous devriez utiliser les labels

- "Labelliser": verbe, par ex. attacher des informations arbitraires aux services

- Exemples:

  - le vhost HTTP d'une web app ou d'un service web

  - planifier la sauvegarde de service à données persistentes

  - propriétaire d'un service (pour la facturation, l'astreinte, etc.)

  - grouper les objets Swarm entre eux (services, volumes, configs, secrets, etc.)

---

## Astuce de pro pour gérer le trafic _ingress_

- Il est possible d'utiliser un réseau *local* avec les services Swarm

- Cela signifie qu'on peut faire quelque chose comme:
  ```bash
  docker service create --network host --mode global traefik ...
  ```

  (Ça va lancer le _load balancer_ `traefik` sur chaque noeud de votre cluster, sur le reseau `host`)

- On y gagne une performance native (pas de iptables, ni proxy, ni rien!)

- Le _répartiteur de charge_ "verra" les adresses IP des clients

- Mais: le conteneur ne peut être en même temps dans le réseau `host`et dans un autre.

  (Vous devrez router le trafic aux conteneurs via des ports exposés ou des sockets UNIX)

---

class: extra-details

## Utiliser les réseaux locaux (`host`, `macvlan`...)

- Il est possible de connecter les services aux réseaux locaux

- Passer par le réseau `host` est plutôt simple

  (Avec les réserves décrites dans la diapo précédente)

- Pour d'autres pilotes réseaux, c'est un poil plus compliqué

  (l'allocation d'IP peut nécessiter une coordination entre les nodes)

- Voir par exemple [ce guide](
  https://docs.docker.com/engine/userguide/networking/get-started-macvlan/
  ) pour bien démarrer avec `macvlan`

- Voir [cette PR](https://github.com/moby/moby/pull/32981) pour plus d'information sur les pilotes réseaux locaux dans le mode Swarm

---

## Visualiser le placement de conteneurs

- Jouons avec l'API Docker!

.exercise[

- Lancer cette appli simple-mais-sympa de visualisation:
  ```bash
  cd ~/container.training/stacks
  docker-compose -f visualizer.yml up -d
  ```

  <!-- ```longwait Creating dockerswarmvisualizer_viz_1``` -->

]

---

## Se connecter à la web app de visualisation

- Elle fait tourner un serveur web sur le port 8080

.exercise[

- Faire pointer le navigateur sur le port 8080 de votre node1 (son adresse IP)

  (Sur Play-With-Docker, cliquez sur le bouton (8080))

  <!-- ```open http://node1:8080``` -->

]

- L'appli web met à jour l'affichage à la volée (pas besoin de recharger la page)

- Elle affiche juste les services Swarm (pas les conteneurs indépendants)

- Elle indique quand les noeuds sont disponibles ou pas.

- Il y reste quelques couacs (ce n'est pas du logiciel de Classe-Entreprise, ISO-9001, à résistance thermo-nucléaire)

---

## Pourquoi c'est plus important que ça

- Le visualiseur accède à l'API Docker *de l'intérieur du conteneur*

- C'est un motif courant: lancer des outils de managements *dans un conteneur*

- Au lieu d'afficher notre cluster, on pourrait traiter les logs, les métriques, la montée en charge automatique...

- On peut le lancer en tant que service, aussi! On ne le fera pas tout de suite, mais la commande ressemblerait à:

  ```bash
    docker service create \
      --mount source=/var/run/docker.sock,type=bind,target=/var/run/docker.sock \
      --name viz --constraint node.role==manager ...
  ```

.footnote[

Crédits: le code de visualization code a été écrit par
[Francisco Miranda](https://github.com/maroshii).

[Mano Marks](https://twitter.com/manomarks) l'a adapté
au Swarm et le maintient.

]

---

## Nettoyer nos services

- Avant de poursuivre, on va supprimer ces services

- `docker service rm` accepte plusieurs noms ou IDs de services

- `docker service ls` accepte l'option `-q`

- Un bout de code Shell par jour éloigne la dette technique pour toujours.

.exercise[

- Supprimer tous les services avec cette commande:
  ```bash
  docker service ls -q | xargs docker service rm
  ```

]
