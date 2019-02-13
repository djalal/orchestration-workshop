# Collecter les métriques

- On veut rassembler des métriques dans sur un seul service

- On veut collecter les métriques de noeuds et de conteneurs

- On veut aussi une jolie interface pour les consulter (des graphes)

---

## Métriques de _nodes_

- CPU, RAM, usage disque pour toute la _node_

- Nombre total de processus en cours d'exécution, et leur état

- activité I/O (entrées/sorties sur disque et réseau), par opération ou par volume

- indicateurs physiques et matériels (si disponible): température, vitesse du ventilateur...

- ... et bien plus!

---

## Métriques de conteneurs

- Similaires aux métriques de nodes, sans être identiques

- Répartition de la RAM différente:

  - mémoire active vs inactive
  - une partie de la mémoire est *partagée* entre conteneurs, et comptabilisée à part

- l'activité I/O est aussi plus difficile à suivre

  - les écritures _async_ peuvent causer une "comptabilité" différée
  - quelques _pages-ins_ sont aussi partagées entre conteneurs

Pour plus de détails sur les métriques de conteneurs, voir:

https://jpetazzo.github.io/2013/10/08/docker-containers-metrics/

---

## Métriques applicatives

- Métriques arbitraires liées à notre applicatif et au métier

- Performance système: latence des requêtes, taux d'erreur ...

- Information de volume: nombres de lignes dans la base de données, taille de la file d'attente...

- Données métier: inventaire, articles vendus, chiffre d'affaire ...

---

class: snap, prom

## Outils

Nous allons monter *deux* collecteurs de métriques différents:

- Le premier basé sur Intel Snap,

- Le second sur Prometheus.

---

class: snap

## Premier collecteur de métriques

Nous allons utiliser trois projets open source en Go pour notre premier collecteur de métriques:

- Intel Snap

  Collecte, traite, et publie les métriques

- InfluxDB

  Stocke les métriques

- Grafana

  Présente les métriques visuellement

---

class: snap

## Snap

- [github.com/intelsdi-x/snap](https://github.com/intelsdi-x/snap)

- Peut collecter, traiter, et exposer les données de métriques

- Ne stocke aucune métrique

- Fonctionne en mode _daemon_, controllé par une ligne de commande (snapctl)

- Délègue la collecte, le traitement et la publication à des plugins

- Ne peut rien faire à l'installation; obligation de configurer!

- Documentation: https://github.com/intelsdi-x/snap/blob/master/docs/

---

class: snap

## InfluxDB

- Snap ne stocke aucune donnée de métrique

- InfluxDB est spécifiquement conçu pour les données basées sur le temps

  - CRud vs CRUD (on modifie rarement ou jamais ces données)

  - motifs de lecture/écriture orthogonaux

  - la clé est dans l'optimisation du format de stockage (pour l'usage et la performance du disque)

- Snap dispose d'un plugin permettant la *publication* vers InfluxDB

---

class: snap

## Grafana

- Snap ne peut pas afficher de graphes

- InfluxDB ne peut pas non plus

- Grafana va s'en occuper

- Grafana peut lire ses données depuis InfluxDB et l'afficher dans des graphes

---

class: snap

## Récupérer et installer Snap

- Nous installerons Snap directement sur chaque noeud

- Les versions publiées sous tarballs sont disponibles depuis Github

- Nous l'utiliserons comme *service global*
  <br/>(disponible sur chaque noeud, y compris les futurs arrivants)

- Ce service va télécharger et décompresser Snap dans /opt et /usr/local

- /opt et /usr/local sont des points de montage depuis l'hôte

- Ce service va concrètement installer Snap sur tous les hôtes

---

class: snap

## Le service Snap d'installation

- Ceci va installer Snap sur tous les noeuds

.exercise[

```bash
docker service create --restart-condition=none --mode global \
       --mount type=bind,source=/usr/local/bin,target=/usr/local/bin \
       --mount type=bind,source=/opt,target=/opt centos sh -c '
SNAPVER=v0.16.1-beta
RELEASEURL=https://github.com/intelsdi-x/snap/releases/download/$SNAPVER
curl -sSL $RELEASEURL/snap-$SNAPVER-linux-amd64.tar.gz |
     tar -C /opt -zxf-
curl -sSL $RELEASEURL/snap-plugins-$SNAPVER-linux-amd64.tar.gz |
     tar -C /opt -zxf-
ln -s snap-$SNAPVER /opt/snap
for BIN in snapd snapctl; do ln -s /opt/snap/bin/$BIN /usr/local/bin/$BIN; done
' # Si vous copier-coller ce block, n'oubliez pas l'apostrophe finale ☺
```

]

---

class: snap

## Premier contact avec `snapd`

- Le coeur de Snap est `snapd`, le _daemon_ Snap

- L'application est composée d'une API REST, un module de contrôle et un module d'ordonnancement

.exercise[

- Démarrer `snapd` sans vérification de plugin et en mode debug:
  ```bash
  snapd -t 0 -l 1
  ```

]

- Pour aller plus loin:

  https://github.com/intelsdi-x/snap/blob/master/docs/SNAPD.md
  https://github.com/intelsdi-x/snap/blob/master/docs/SNAPD_CONFIGURATION.md

---

class: snap

## Using `snapctl` to interact with `snapd`
## Utiliser `snapctl` pour intéragir avec `snapd`


- Chargeons des plugins de *collection* et de *publication*

.exercise[

- Ouvrir un nouveau terminal

- Charger le plugin de collection psutil:
  ```bash
  snapctl plugin load /opt/snap/plugin/snap-plugin-collector-psutil
  ```

- Charger le plugin de publication de fichier:
  ```bash
  snapctl plugin load /opt/snap/plugin/snap-plugin-publisher-mock-file
  ```

]

---

class: snap

## Vérifier ce qu'on a fait

- Bon à savoir: la CLI Docker utilise `ls`, celle de Snap préfère `list`

.exercise[

- Voir vos plugins chargés:
  ```bash
  snapctl plugin list
  ```

- Voir les métriques qu'on peut collecter:
  ```bash
  snapctl metric list
  ```

]

---

class: snap

## Réellement collecter des métriques: intro aux *tasks*

- Pour démarrer les phases de collecte/traitement/publication des données de métriques, on doit déclarer une nouvelle *task*

- Une tâche indique:

  - *quoi* collecter (quelles métriques)
  - *quand* collecter (à quelle fréquence)
  - *comment* les traiter (par ex. sous forme brute, ou après calcul de moyenne)
  - *où* les publier

- Les tâches peuvent être définies via des manifestes écrits en JSON ou YAML

- Quelques plugins, tels que le collecteur Docker, autorisent les jokers (\*) dans les "chemins" de métriques
  <br/>(voir snap/docker-influxdb.json)

- Plus de ressources:
  https://github.com/intelsdi-x/snap/blob/master/docs/TASKS.md

---

class: snap

## Notre premier manifeste de tâche

```yaml
  version: 1
  schedule:
    type: "simple" # collect on a set interval
    interval: "1s" # of every 1s
  max-failures: 10
  workflow:
    collect: # first collect
      metrics: # metrics to collect
        /intel/psutil/load/load1: {}
      config: # there is no configuration
      publish: # after collecting, publish
        -
            plugin_name: "file" # use the file publisher
            config:
                file: "/tmp/snap-psutil-file.log" # write to this file
```

---

class: snap

## Créer notre première tâche

- Le manifest de tâche montré dans la diapo précédente est stocké dans `snap/psutil-file.yml`.

.exercise[

- Déclarer une nouvelle tâche basée sur le manifeste:

  ```bash
  cd ~/container.training/snap
  snapctl task create -t psutil-file.yml
  ```

]

  L'affichage devrait ressembler à:
  ```
    Using task manifest to create task
    Task created
    ID: 240435e8-a250-4782-80d0-6fff541facba
    Name: Task-240435e8-a250-4782-80d0-6fff541facba
    State: Running
  ```

---

class: snap

## Vérifier les tâches existantes

.exercise[

- Cela va confirmer que notre tâche tourne correctement, et nous rappeler son ID de tâche.

  ```bash
  snapctl task list
  ```

]

L'affichage devrait ressembler à ce qui suit:
  ```
    ID           NAME              STATE     HIT MISS FAIL CREATED
    24043...acba Task-24043...acba Running   4   0    0    2:34PM   8-13-2016
  ```
---

class: snap

## Voir notre tâche à l'oeuvre

- La tâche utilise un éditeur très simple, `mock-file`

- Cet éditeur ne fait qu'écrire des lignes dans un fichier (une ligne par point de donnée)

.exercise[

- Vérifier que les données circulent vraiment:
  ```bash
  tail -f /tmp/snap-psutil-file.log
  ```

]

Pour sortir, taper `^C`

---

class: snap

## Diagnostiquer les tâches

- Quand une tâche n'écrit pas directement dans un fichier local, passez par `snapctl task watch`

- `snapctl task watch` va faire défiler les métriques collectées vers STDOUT

.exercise[

```bash
snapctl task watch <ID>
```

]

Pour sortir, taper `^C`

---

class: snap

## Arrêter snap

- Notre déploiement Snap garde quelques défauts:

  - snapd a été démarré à la main

  - il est lancé sur une seule _node_

  - la configuration est purement locale

--

class: snap

- On veut corriger tout ça!

--

class: snap

- Mais d'abord, retournons au terminal où tourne `snapd`, et tapons `^C`

- Toutes les tâches seront stoppées; tous les plugins déchargés; Snap va sortir

---

class: snap

## Snap en mode _Tribe_

- _Tribe_ (tribu en français), est le mécanisme de cluster chez Snap

- Quand le mode tribu est activé, les noeuds peuvent rejoindre des *agreements*

- Quand un noeud au sein d'un _agreement_ fait quelque chose (par ex. charger un plugin ou lancer une tâche),
les autres noeuds dans le même _agreement_ font de même.

- Nous allons l'exploiter pour charger le collecteur Docker et l'éditeur InfluxDB sur toutes les _nodes_,
puis lancer une tâche pour les activer.

- Sans le mode _Tribe_, nous aurions du charger les plugins et lancer les tâches à la main sur chaque noeud.

- Pour en savoir plus:
  https://github.com/intelsdi-x/snap/blob/master/docs/TRIBE.md

---

class: snap

## Lancer Snap lui-même sur chaque _node_

- Snap tourne en avant-plan, vous devez donc utiliser `&` ou le démarrer dans un _tmux_

.exercise[

- Lancer la commande suivante *sur chaque noeud*:
  ```bash
  snapd -t 0 -l 1 --tribe --tribe-seed node1:6000
  ```

]

Si vous n'utilisez *pas* Play-With-Docker, il y a une autre manière de lancer Snap!

---

class: snap

## Démarrer un _daemon_ par SSH

.warning[Grosse bidouille en vue!]

- Nous allons créer un *service global*

- Ce service global va installer un client SSH

- Avec ce client SSH, le service va se connecter sur sa _node_ locale
  <br/>(i.e "s'échapper" du conteneur, grâce à la clé SSH fournie)

- Une fois connecté à la _node_, le service démarre snapd avec le mode _Tribe_

---

class: snap

## Lancer Snap lui-même sur chaque noeud

- Je pourrais aller en prison en vous montrant ça, mais c'est parti ...

.exercise[

- Démarrer Snap sur toute la longueur:
  ```bash
    docker service create --name snapd --mode global \
           --mount type=bind,source=$HOME/.ssh/id_rsa,target=/sshkey \
           alpine sh -c "
                  apk add --no-cache openssh-client &&
                  ssh -o StrictHostKeyChecking=no -i /sshkey root@172.17.0.1 \
                      /usr/local/bin/snapd -t 0 -l 1 --tribe --tribe-seed node1:6000
           " # Si vous copier-coller ce bloc, n'oubliez pas l'apostrophe finale :-)
   ```

]

Rappel : ceci *ne fonctionne pas* si vous êtes sur Play-With-Docker (à cause de SSH).

---

class: snap

## Afficher les membres de notre tribu

- Si tout se passe bien, Snap est maintenant lancé en mode tribu

.exercise[

- Afficher les membres de notre _Tribe_:
  ```bash
  snapctl member list
  ```

]

Vous devriez voir les 5 noeuds et leurs noms d'hôtes.

---

class: snap

## Déclarer un nouvel _agreement_

- Un _agreement_ est un pacte entre membres d'un cluster Snap qui garantit le même comportement.

- Nous pouvons désormais déclarer un _agreement_ pour nos plugins et tâches.

.exercise[

- Créer un _agreement_; s'assurer de bien utiliser le même nom tout au long:
  ```bash
  snapctl agreement create docker-influxdb
  ```

]

La sortie d'écran devrait ressembler à ceci:

```
  Name             Number of Members       plugins      tasks
  docker-influxdb  0                       0            0
```

---

class: snap

## Ordonner à tous les noeuds de rejoindre cet _agreeement_

- Pas besoin d'un autre service global superflu!

- On peut ajouter des noeuds depuis n'importe quel noeud du cluster

.exercise[

- Ajouter toutes les _nodes_ au nouvel _agreement_
  ```bash
    snapctl member list | tail -n +2 |
      xargs -n1 snapctl agreement join docker-influxdb
  ```

]

Le dernier bout d'affichage devrait ressembler à ceci:
```
  Name             Number of Members       plugins         tasks
  docker-influxdb  5                       0               0
```

---

class: snap

## Démarrer un conteneur sur chaque _noeud_

- Le plugin Docker exige au moins un conteneur pour être démarré

- Normalement, à ce niveau de la procédure, vous devriez disposer d'au moins un conteneur sur chaque _node_

- Mais, juste au cas où quelque chose aurait divergé, déclarons un service global de démo.

.exercise[

- Déclarer un conteneur alpine à travers le cluster:
  ```bash
    docker service create --name ping --mode global alpine ping 8.8.8.8
  ```

]

---

class: snap

## Faire tourner InfluxDB

- Nous allons créer un service pour InfluxDB

- Nous utiliserons pour cela l'image officielle

- InfluxDB expose plusieurs ports:

  - 8086 (HTTP API; nous en avons besoin)

  - 8083 (l'interface admin; il nous la faut)

  - 8088 (communication de cluster; superflu ici)

  - d'autres ports pour d'autres protocoles (graphite, collectd, etc.)

- On se suffira des deux premiers ports pour la suite.

---

class: snap

## Initialiser le service InfluxDB

.exercise[

- Lancer un service InfluxDB, tout en ouvrant les ports 8083 et 80806:
  ```bash
    docker service create --name influxdb \
           --publish 8083:8083 \
           --publish 8086:8086 \
           influxdb:0.13
  ```

]

Note: Cela va autoriser n'importe quel noeud à publier des métriques sur `localhost:80806`,
et par la même, ouvrir l'interface admin depuis n'importe quel noeud sur le port 8083.

.warning[Assurez-vous bien d'utiliser la version 0.13 d'InfluxDB; quelques petits trucs
ont changé en version 1.0 (comme le nom de la politique de rétention par défaut, qui est
maintenant "autogen"), ce qui casserait notre démo.]

---

class: snap

## Configurer InfluxDB

- On devrait y créer notre base de données "snap"

.exercise[

- Ouvrir le port 8083 sur navigateur

- Entrer la requête suivante dans le champ de saisie:
  ```
  CREATE DATABASE "snap"
  ```

- En haut à droite, sélectionner "Database: snap"

]

Note: le langage de requête InfluxDB *ressemble* à SQL, mais il n'en est rien.

---

class:snap

## Régler la politique de rétention

- En passant à la version 1.0, InfluxDB a changé le nom de la politique par défaut.

- A l'origine baptisée "default", elle s'appelle désormais "autogen"

- Au grand dam de Snap qui ne connait que "default", nous occasionnant des erreurs potentielles.

.exercise[

- Déclarer une politique de rétention "default", en lançant la requête suivante:
  ```
  CREATE RETENTION POLICY "default" ON "snap" DURATION 1w REPLICATION 1
  ```

]

---

class: snap

## Lancer le collecteur Docker et l'éditeur InfluxDB

- Nous allons charger les plugins depuis la _node_ locale

- Puisque notre _node_ locale est un membre d'_agreement_, toutes
les autres _nodes_ de ce même _agreement_ vont agir en miroir.

.exercise[

- Charger le collecteur Docker:

  ```bash
  snapctl plugin load /opt/snap/plugin/snap-plugin-collector-docker
  ```

- Charger l'éditeur InfluxDB:

  ```bash
  snapctl plugin load /opt/snap/plugin/snap-plugin-publisher-influxdb
  ```

]

---

class: snap

## Démarrer une simple tâche de collecte

- Comme tout à l'heure, nous allons déclarer une nouvelle tâche sur la _node_ locale

- Ladite tâche va être répliquée sur les _nodes_ membres du même _agreement_

.exercise[

- Charge le fichier du manifeste de tâche, pour collecter une ou deux métriques
  <br/>sur tous les conteneurs, et les envoyer à InfluxDB:
  ```bash
  cd ~/container.training/snap
  snapctl task create -t docker-influxdb.json
  ```

]

Note: la description de tâche envoie les métriques au point d'entrée de
l'API InfluxDB, écoutant sur 127.0.0.1:8086. Puisque le conteneur InfluxDB
est publié sur le port 8086, 127.0.0.1:8086 va toujours router le trafic
vers le conteneur InfluxDB.

---

class: snap

## Si quelque chose dérape...

Note:  si une tâche tombe en panne (par ex. en essayant de publier
des données vers une base de métrique inaccessible), la tâche va
se mettre à l'arrêt.

Vous devrez la redémarrer à la main en lançant:

```bash
snapctl task enable <ID>
snapctl task start <ID>
```

C'est une procédure à lancer sur *chaque noeud*. L'alternative serait de
supprimer+re-déclarer la tâche (commandes à l'effet global sur tout le cluster)

---

class: snap

## Voir si les métriques remontent dans InfluxDB

- Vérifions les données existantes avec ces requêtes manuelles dans l'admin InfluxDB

.exercise[

- Lister les _"measurements"_:
  ```
  SHOW MEASUREMENTS
  ```
  (Vous devriez voir deux entrées génériques correspondant aux deux métriques collectées.)

- Afficher les données séries-temps pour une des métriques:
  ```
  SELECT * FROM "intel/docker/stats/cgroups/cpu_stats/cpu_usage/total_usage"
  ```
  (Vous devriez voir une liste de points de données avec **time**, **docker_id**, **source**, et **value**.)

]

---

class: snap

## Déployer Grafana

- Vous pouvez utiliser une image quasi-officielle, `grafana/grafana`

- Vous pouvez rendre publique l'interface web de Grafana sur son port par défaut (3000)

.exercise[

- Créer un service Grafana:
  ```bash
  docker service create --name grafana --publish 3000:3000 grafana/grafana:3.1.1
  ```

]

---

class: snap

## Configurer Grafana

.exercise[

- Ouvrir le port 3000 avec le navigateur

- Se connecter en "admin" en identifiant/mot de passe

- Cliquer sur le logo Grafana (la spirale orange dans le coin en haut à gauche)

- Cliquer sur les "Data sources"

- Cliquer sur "Add data source" (le bouton vert à droite)

]

---

class: snap

## Ajouter InfluxDB comme source dans Grafana

.small[

Remplir le formulaire exactmeent comme suit:
- Name = "snap"
- Type = "InfluxDB"

Dans les paramètres HTTP, renseigner comme suit:
- Url = "http://(adresse.IP.de.votre.noeud.prefere):8086"
- Access = "direct"
- Laisser "HTTP Auth" vide

Dans les détails pour InfluxDB, écrire comme suit:
- Database = "snap"
- Laisser l'utilisateur et le mot de passe vierges

Pour finir, cliquer sur "add", vous devriez voir un message vert affirmant "Success - Data source is working".
Si vous voyez un encart orange (parfois sans message), cela veut dire que quelque chose s'est mal passé. Vérifier bien à nouveau.

]

---

class: snap

![Copie d'écran montrant comment remplir le formulaire](images/grafana-add-source.png)

---

class: snap

## Déclarer un tableau de bord dans Grafana

.exercise[

- Cliquer sur le logo Grafana encore (la spirale orange dans le coin en haut à gauche)

- Passer sur "Dashboards"

- Cliquer sur "+ New"

- Cliquer sur le petit rectangle vert qui apparait en haut à gauche

- Passer sur "Add panel"

- Cliquer sur "Graph"

]

A ce moment précis, vous devriez voir un graphe d'exemple s'afficher.

---

class: snap

## Configurer un graphe dans Grafana

.exercise[

- Panel data source: choisir "snap"
- Cliquer sur les requêtes de métriques SELECT pour les agrandir
- Cliquer sur "select measurement" et choisir "CPU usage"
- Cliquer sur le "+" juste à côté de "WHERE"
- Choisir "docker_id"
- Choisir l'ID d'un conteneur de votre choix (par ex. celui qui fait tourner InfluxDB)
- Cliquer sur le "+" à droite right de la ligne "SELECT"
- Ajouter "derivative"
- Dans l'option "derivative", choisir "1s"
- Dans le coin en haut à droite, cliquer sur la montre, et choisir "last 5 minutes"

]

Félicitations, vous avez sous les yeux l'usage CPU d'un seul conteneur!

---

class: snap

![Copie d'écran affichant le résultat final](images/grafana-add-graph.png)

---

class: snap, prom

## Avant de poursuivre ...

- Laissez cet onglet ouvert!

- Nous allons installer un *autre* système de métrique

- ... Puis comparer les 2 graphes côte-à-côte

---

class: snap, prom

## Prometheus vs. Snap

- Prometheus est un autre système de collecte de métriques

- Snap *pousse* les métriques, là où Prometheus les *aspire*

---

class: prom

## Composants de Prometheus

- Le *serveur Prometheus* aspire, stocke et affiche les métriques

- Sa configuration définit une liste de points *exportateurs*
  <br/>(cette liste peut être dynamique, via par ex. Consul, DNS, etcd ...)

- Les *exportateurs* exposent des métriques via HTTP dans un simple format ligne à ligne

  (Un format optimisé usant de protobuf existe aussi)

---

class: prom

## Tout est dans les `/metrics`

- Voici à quoi ressemble un *exportateur de noeud*:

  http://demo.robustperception.io:9100/metrics

- Prometheus lui-même expose aussi ses propres métriques internes:

  http://demo.robustperception.io:9090/metrics

- Un *serveur Prometheus* va *aspirer* les URLs telles que celles-ci

  (On passera plutôt par protobuf pour éviter le supplément de traitement des formats ligne-à-ligne!)

---

class: prom-manual

## Collecter les métriques avec Prometheus sur Swarm

- Nous allons lancer deux *services globaux* (i.e. planifiés sur toutes les _nodes_):

  - Un *exportateur de noeud* Prometheus pour lire les métriques de _node_

  - Le cAdvisor de Google pour lire les métriques de conteneurs.

- C'est un serveur Prometheus qui va interroger ces exportateurs.

- Ce serveur Prometheus sera configuré pour la découverte de services par DNS

- Nous utiliserons `tasks.<nom_du_service>` pour cette découverte de services.

- Tous ces services seront placés dans un réseau privé interne.

---

class: prom-manual

## Ajouter un réseau _overlay_ pour Prometheus

- C'est l'étape la plus facile ☺

.exercise[

- Déclarer un réseau superposé:
  ```bash
  docker network create --driver overlay prom
  ```

]

---

class: prom-manual

## Lancer l'exportateur pour _node_

- L'exportateur de _node_ *devrait* tourner directement sur les hôtes
- Toutefois, il peut tourner dans un conteneur, si correctement configuré
  <br/>
  (il devra quand même avoir accès aux système de fichier hôte, particulièrement à /proc et /sys)

.exercise[

- Démarrer l'exportateur de noeud:
  ```bash
    docker service create --name node --mode global --network prom \
     --mount type=bind,source=/proc,target=/host/proc \
     --mount type=bind,source=/sys,target=/host/sys \
     --mount type=bind,source=/,target=/rootfs \
     prom/node-exporter \
      --path.procfs /host/proc \
      --path.sysfs /host/proc \
      --collector.filesystem.ignored-mount-points "^/(sys|proc|dev|host|etc)($|/)"
   ```

]

---

class: prom-manual

## Installer cAdvisor

- Dans la même veine, cAdvisor *devrait* tourner directement sur nos hôtes.

- Mais on peut le lancer dans des conteneurs configurés correctement.

.exercise[

- Démarrer le collecteur cAdvisor:
  ```bash
    docker service create --name cadvisor --network prom --mode global \
      --mount type=bind,source=/,target=/rootfs \
      --mount type=bind,source=/var/run,target=/var/run \
      --mount type=bind,source=/sys,target=/sys \
      --mount type=bind,source=/var/lib/docker,target=/var/lib/docker \
      google/cadvisor:latest
  ```

]

---

class: prom-manual

## Configuration de serveur Prometheus

Voici notre fichier de configuration pour Prometheus:

.small[
```yaml
global:
  scrape_interval: 10s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node'
    dns_sd_configs:
      - names: ['tasks.node']
        type: 'A'
        port: 9100
  - job_name: 'cadvisor'
    dns_sd_configs:
      - names: ['tasks.cadvisor']
        type: 'A'
        port: 8080
```
]

---

class: prom-manual

## Transmettre la configuration à Prometheus

- Le plus simple serait de générer une image spécifique, incluant cette config.

- On va utiliser un Dockerfile très simple:
  ```dockerfile
  FROM prom/prometheus:v1.4.1
  COPY prometheus.yml /etc/prometheus/prometheus.yml
  ```

  (Le fichier de configuraiton et le Dockerfile sont tous deux dans le dossier `prom`)

- On va lancer un _build_, puis pousser cette image dans notre _Registry_ locale

- On terminera en créant un service invoquant cette image

Note: il est aussi possible d'utiliser un objet `config` pour injecter ce fichier de configuration
sans avoir à créer une image spéciale.

---

class: prom-manual

## Générer notre image Prometheus sur-mesure

- Nous allons utiliser le registre local démarré précédemment sur 127.0.0.1:5000

.exercise[

- Générer l'image grâce au Dockerfile fourni:
  ```bash
  docker build -t 127.0.0.1:5000/prometheus ~/container.training/prom
  ```

- Pousser l'image sur notre registre local:
  ```bash
  docker push 127.0.0.1:5000/prometheus
  ```

]

---

class: prom-manual

## Lancer notre image Prometheus sur-mesure

- C'est le seul service qu'on devra rendre public

  (Si on veut pouvoir accéder à Prometheus de l'extérieur!)

.exercise[

- Démarrer notre serveur Prometheus:
  ```bash
    docker service create --network prom --name prom \
           --publish 9090:9090 127.0.0.1:5000/prometheus
  ```

]

---

class: prom-auto

## Déployer Prometheus sur notre cluster

- Nous allons (encore une fois) utiliser une définition de _stack_

.exercise[

- S'assurer que nous sommes dans le dossier `stacks`:
  ```bash
  cd ~/container.training/stacks
  ```

- Générer, envoyer et lancer la _stack_ Prometheus:
  ```bash
  docker-compose -f prometheus.yml build
  docker-compose -f prometheus.yml push
  docker stack deploy -c prometheus.yml prometheus
  ```

]

---

class: prom

## Vérifier notre serveur Prometheus

- D'abord, assurons-nous que Prometheus aspire correctement toutes les métriques

.exercise[

- Ouvrir le port 9090 avec le navigateur

- Cliquer sur "status", puis "targets"

]

Vous devriez voir sept points d'entrées (3 cadvisor, 3 node, 1 prometheus)

Leur statut devrait être "UP".

---

class: prom-auto, config

## Injecter un fichier de configuration

(Nouveau dans Docker Engine 17.06)

- Nous générons une image sur-mesure *juste pour injecter un fichier de configuration*

- Au lieu de cela, nous pourrions rester sur l'image Prometheus officielle + une `config`

- Une `config` est un _blob_ (habituellement, un fichier de conf) qui:

  - est créé et géré à travers l'API Docker (dont la ligne de commande)

  - est stocké dans le log Raft (synonyme de sécurité)

  - peut être associé à un service
    <br/>
    (cette opération consistant à injecter le _blob_ sous forme de fichier classique dans les conteneurs du service)

---

class: prom-auto, config

## Différences entre `configs` et `secrets`

Les deux se ressemblent vraiment, à ceci près que:

- `configs`:

  - peut être injecté à n'importe quel endroit du système de fichiers

  - peut être affiché et extrait à l'aide de l'API Docker ou la CLI

- `secrets`

  - peut uniquement être injecté dans `/run/secrets`

  - n'est jamais stocké en clair sur le disque

  - ne pourra jamais être affiché ou extrait avec l'API Docker ou la CLI

---

class: prom-auto, config

## Déployer Prometheus avec un `config`

Le fichier Compose qui suit (`prometheus+config.yml`) accomplit
la même tâche, mais en utilisant un `config` au lieu de cuisiner
une nouvelle image "farcie" de configuration.

.small[
```yaml
version: "3.3"

services:

prometheus:
  image: prom/prometheus:v1.4.1
  ports:
    - "9090:9090"
  configs:
    - source: prometheus
      target: /etc/prometheus/prometheus.yml

...

configs:
  prometheus:
    file: ../prom/prometheus.yml
```
]

---

class: prom-auto, config

## Spécifier un `config` dans un fichier Compose

- Dans chaque service, une section `configs` optionnelle peut lister autant de configuration que nécessaire.

- Chaque config peut préciser:

  - un champ `target` optionnel (chemin où injecter la config; par défaut: à la racine du conteneur)

  - les permissions et/ou propriété (par défaut, le fichier appartient à l'UID 0, i.e. `root`)

- Ces configs pointent vers la section principale de `configs`

- Cette section principale peut déclarer une ou plusieurs configs telles que:

  - *external*, à savoir qu'elle est supposée pré-exister avant de déployer la _stack_

  - le référencement d'un fichier, dont le contenu est utilisé pour initialiser la config

---

class: prom-auto, config

## Re-déployer Prometheus avec une config

- Nous allons mettre à jour la _stack_ existante grâce à `prometheus+config.yml`

.exercise[

- Re-déployer la _stack_ `prometheus`:
  ```bash
  docker stack deploy -c prometheus+config.yml prometheus
  ```

- Vérifier que Prometheus fonctionne encore comme attendu:

  (En se connectant à n'importe quel noeud du cluster, sur le port 9090)

]

---

class: prom-auto, config

## Accéder à l'objet de config depuis la CLI

- Les objets de config peuvent être consultés depuis la CLI Docker (ou l'API)

.exercise[

- Lister les objets de config existant:
  ```bash
  docker config ls
  ```

- Afficher les détails sur notre objet de config:
  ```bash
  docker config inspect prometheus_prometheus
  ```

]

Note: le contenu du blob de configuration est affiché en encodate BASE64
<br/>
(En effet, cela peut ne pas être du texte; par exemple une image ou n'importe quel binaire!)


---

class: prom-auto, config

## Extraire un _blob_ de config

- Récupérons cette configuration Prometheus!

.exercise[

- Extraire le contenu en BASE64 avec `jq`:
  ```bash
  docker config inspect prometheus_prometheus | jq -r .[0].Spec.Data
  ```

- Le décoder avec `base64 -d`:
  ```bash
  docker config inspect prometheus_prometheus | jq -r .[0].Spec.Data | base64 -d
  ```

]

---

class: prom

## Afficher les métriques directement depuis Prometheus

- C'est facile ... si vous êtes familier avec PromQL

.exercise[

- Cliquer sur "Graph", et dans "expression", coller ce qui suit:
  ```
    sum by (container_label_com_docker_swarm_node_id) (
      irate(
        container_cpu_usage_seconds_total{
          container_label_com_docker_swarm_service_name="dockercoins_worker"
          }[1m]
      )
    )
  ```

- Cliquer sur le bouton bleu "Execute" et sur l'onglet "Graph" juste en dessous.

]

---

class: prom

## Construire le requête de zéro

- Nous allons monter la même requête de zéro

- Le but n'est pas de remplacer un vrai cours détaillé sur PromQL

- C'est juste suffisant pour que vous (et moi) faisions semblant de comprendre
la requête précédente et pour impressioner vos collègues au bureau (ou pas)

  (ou, pour construire d'autres requêtes si nécessaire, ou les adapter si cAdvisor,
  Prometheus, ou n'importe quoi demande des changements, et exige de changer la requête!)

---

class: prom

## Voir les métriques brutes pour *tout* conteneur

- Cliquer sur l'onglet "Graph" au dessus

  *On arrive dans un tableau de bord vierge*

- Cliquer sur la liste "Insert metric at cursor", et choisir `container_cpu_usage_seconds_total`

  *Ça va placer le nom de la métrique dans le champ de requête*

- Cliquer sur "Execute"

  *La table des mesures du dessous va se remplir*

- Cliquer sur "Graph" (à côté de "Console")

  *La table des mesures est remplacée par une série de graphes (après quelques secondes)*

---

class: prom

## Choisir les métriques pour un service spécifique

- Passer sur les lignes du graphe

  (Essayer de repérer ceux qui ont des labels comme `container_label_com_docker_...`)

- Changer la requête, en ajoutant une condition entre accolades:

  .small[`container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name="dockercoins_worker"}`]

- Cliquer sur "Execute"

  *On devrait voir maintenant une ligne par CPU par conteneur*

- Si vous voulez limiter à un conteneur précis, ajouter une expression régulière: `id=~"/docker/c4bf.*"`

- Vous pouvez aussi cumuler les conditions, en les séparant par virgule.

---

class: prom

## Transformer les compteurs en taux

- Ce qu'on voit, c'est le montant total de CPU utilisé (en secondes)

- On voudrait afficher un *taux* (temps de CPU utilisé / temps réel)

- Pour avoir une moyenne mobile sur 1 minute, encapsulez l'expression en cours dans:

  ```
  rate ( ... { ... } [1m] )
  ```

  *Cela devrait convertir notre compteur CPU qui grimpe en courbe gracieuse*

- Pour afficher plutôt un taux instantané, choisir `irate` au lieu de `rate`

  (La fenêtre de temps sert ensuite à filtrer la quantité de données dans le passé à récupérer,
  dans le cas où des points sont manquants à cause de collecte défaillante; [voir ici](https://www.robustperception.io/irate-graphs-are-better-graphs/) pour plus de détails!)

  *On devrait voir des pics, qui étaient restés cachés, à cause du lissage sur le temps*

---

class: prom

## Agréger des séries de données multiples

- On a une courbe par CPU par conteneur; on voudrait les cumuler

- Encapsulez toute l'expression dans:

  ```
  sum ( ... )
  ```

  *On peut voir maintenant une seule courbe*

---

class: prom

## Eclatement de dimensions

- Avec plusieurs conteneurs, on peut juste éclater la dimension "CPU":

  ```
  sum without (cpu) ( ... )
  ```

  *On affichera la même courbe, en préservant les autres labels*

- Fécilitations, vous venez d'écrire votre première expression PromQL de zéro!

  (Merci à [Johannes Ziemke](https://twitter.com/discordianfish) et
  [Julius Volz](https://twitter.com/juliusvolz) pour leur aide avec Prometheus!)

---

class: prom, snap

## Comparer les données de Snap et Prometheus

- Si vous n'avez pas monté Snap, InfluxDB et Grafana, sautez cette section

- Si vous avez fermé l'onglet Grafana, il faudra peut-être ré-installer un nouveau tableau de bord

  (sauf si vous l'avez enregistré avant de quitter)

- Pour tout récupérer, il suffit de suivre les instructions du chapitre précédent

---

class: prom, snap

## Ajouter Prometheus comme source de données dans Grafana

.exercise[

- Dans un nouvel onglet, ouvrir Grafana (port 3000)

- Cliquer sur le logo Grafana (la spirale Orange dans le coin en haut à gauche)

- Cliquer sur "Data sources"

- Cliquer sur le bouton vert "Add data source"

]

On voit le même formulaire qu'on a rempli la dernière fois pour InfluxDB.

---

class: prom, snap

## Connecter Prometheus à Grafana

.exercise[

- Entrer "prom" dans le champ "name"

- Choisir "Prometheus" comme le type de source

- Entrer http://(IP.address.of.any.node):9090 dans le champ Url

- Choisir "direct" dans la méthode d'accès

- Cliquer sur "Save and rest"

]

Encore une fois, on devrait voir une boîte verte disant "Data source is working".

Autrement, réviser chaque étape de la procédure!

---

class: prom, snap

## Ajouter les données de Prometheus au tableau de bord

.exercise[

- Retourner à l'onglet de notre premier tableau de bord Grafana

- Cliquer sur le bouton bleu "Add row" dans le coin en bas à droite

- Cliquer sur l'onglet vert à gauche; choisir "Add panel" et "Graph"

]

On atterrit alors sur l'éditeur de graphe vu précédemment.

---

class: prom, snap

## Interroger Prometheus depuis Grafana

L'éditeur est un peu moins sympa que celui pour InfluxDB.

.exercise[

- Choisir "prom" comme source de données du panneau

- Coller la requête dans le champ "requête":
  ```
    sum without (cpu, id) ( irate (
      container_cpu_usage_seconds_total{
        container_label_com_docker_swarm_service_name="influxdb"}[1m] ) )
  ```

- Cliquer hors du champ de requête pour confirmer

- Fermer l'éditeur de ligne en cliquant "X" dans le coin en haut à droite.

]

---

class: prom, snap

## Interpréter les résultats

- Les deux courbes *devraient* se ressembler

- Astuce de pro: alignez les légendes de temps!

.exercise[

- Cliquer sur l'horloge dans le coin haut-droit

- Choisir "last 30 minutes"

- Cliquer sur "Zoom out"

- Maintenant taper sur la touche "flèche droite" (rester appuyé pour faire monter le CPU!)

]

*Ajuster les unités est un exercice laissé au lecteur.*

---

## Pour aller plus loin avec les métriques de conteneur

- [Prometheus, a Whirlwind Tour](https://speakerdeck.com/copyconstructor/prometheus-a-whirlwind-tour),
  an original overview of Prometheus

- [Docker Swarm & Container Overview](https://grafana.net/dashboards/609),
  a custom dashboard for Grafana

- [Gathering Container Metrics](http://jpetazzo.github.io/2013/10/08/docker-containers-metrics/),
  a blog post about cgroups

- [The Prometheus Time Series Database](https://www.youtube.com/watch?v=HbnGSNEjhUc),
  a talk explaining why custom data storage is necessary for metrics

.blackbelt[DC17US: Monitoring, the Prometheus Way
([video](https://www.youtube.com/watch?v=PDxcEzu62jk&list=PLkA60AVN3hh-biQ6SCtBJ-WVTyBmmYho8&index=5))]

.blackbelt[DC17EU: Prometheus 2.0 Storage Engine
([video](https://dockercon.docker.com/watch/NNZ8GXHGomouwSXtXnxb8P))]
