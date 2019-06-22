name: logging

# _Logs_ centralisés

- On veut pouvoir envoyer tous nos _logs_ de conteneur à un service central

- Si ce service pouvait offrir une jolie interface web, ce serait bien.

--

- Nous allons déployer la suite ELK.

- Elle acceptera les _logs_ via une socket GELF.

- Nous allons configurer nos services avec le pilote de log `gelf`.

---

# Installer ELK pour stocker les _logs_ de conteneur

*Avant-propos important: ce n'est pas une installation "officielle" ou
"recommandée"; juste un exemple. Nous avons choisi ELK pour cette
démo par sa popularité et les demandes qu'il suscite; mais vous serez
aussi gagnant avec Fluent ou d'autres solutions de journalisation!*

Ce qu'on va faire:

- Lancer une suite ELK via des services

- Admirer le chic de l'interface Kibana

- Envoyer quelques logs à la main avec des conteneurs temporaires

- Configurer nos conteneurs pour envoyer leurs logs à Logstash

---

## Qu'est-ce qu'il y a dans la solution ELK?

- ELK, c'est trois composants:

  - ElasticSearch, pour stocker et indexer les messages de _log_;

  - Logstash, qui reçoit les messages de diverses sources, les traite,
    et les transmets à diverses destinations;

  - Kibana, pour afficher/chercher les messages dans une jolie interface.

- Le seul composant que nous allons configurer est Logstash.

- Nous accepterons des messages de _log_ au format GELF.

- Les messages seront stockés dans ElasticSearch,
  <br/> et affichés dans la sortie standard de Logstash pour débogage.

---

class: elk-manual

## Installer ELK

- On aura besoin de trois conteneurs: ElasticSearch, Logstash, Kibana

- On les placera dans un réseau commun, `logging`

.exercise[

- Déclarer le réseau:
  ```bash
  docker network create --driver overlay logging
  ```

- Déclarer le service ElasticSearch:
  ```bash
  docker service create --network logging --name elasticsearch elasticsearch:2.4
  ```

]

---

class: elk-manual

## Installer Kibana

- Kibana expose une interface web

- Son port par défaut (5601) doit être publié.

- Il a besoin d'une touche de config: l'adresse du service ES

- On ne voudrait pas des logs Kibana dans l'interface (cela ajouterait de la pollution)
  <br/>on va donc dir à Logstash de les ignorer

.exercise[

- Déclarer le service Kibana:
  ```bash
  docker service create --network logging --name kibana --publish 5601:5601 \
         -e ELASTICSEARCH_URL=http://elasticsearch:9200 kibana:4.6
  ```

]

---

class: elk-manual

## Installer Logstash

- Logstash exige une config pour recevoir les messages GELF et les envoyer dans ES.

- On pourrait générer notre propre image avec la bonne configuration.

- On peut aussi passer la [configuration](https://@@GITREPO@@/blob/master/elk/logstash.conf) en ligne de commande

.exercise[

- Déclarer le service Logstash:
  ```bash
    docker service create --network logging --name logstash -p 12201:12201/udp \
           logstash:2.4 -e "$(cat ~/container.training/elk/logstash.conf)"
  ```

]

---

class: elk-manual

## Vérifier Logstash

- Avant de continuer, assurons-nous que Logstash est bien démarré

.exercise[

- Trouver la _node_ qui exécute le conteneur Logstash:
  ```bash
  docker service ps logstash
  ```

- Se connecter à cette _node_

]

---

class: elk-manual

## Voir les logs de Logstash

.exercise[

- Afficher les logs du service Logstash:
  ```bash
  docker service logs logstash --follow
  ```

  <!-- ```wait "message" => "ok"``` -->
  <!-- ```keys ^C``` -->

]

Vous devriez voir le message indiquant le "pouls" du service:
.small[
```json
{      "message" => "ok",
          "host" => "1a4cfb063d13",
      "@version" => "1",
    "@timestamp" => "2016-06-19T00:45:45.273Z"
}
```
]

---

class: elk-auto

## Déployer notre cluster ELK

- Nous allons utiliser le fichier _stack_

.exercise[

- Générer, livrer et lancer notre suite ELK:
  ```bash
  docker-compose -f elk.yml build
  docker-compose -f elk.yml push
  docker stack deploy -c elk.yml elk
  ```

]

Note: les étapes de _build_ et _push_ ne sont pas strictement nécessaires, c'est juste une bonne habitude!

Jetons un oeil au [fichier Compose](
https://@@GITREPO@@/blob/master/stacks/elk.yml).

---

class: elk-auto

## Vérifier que notre suite ELK tourne correctement

- Affichons les logs de Logstash

  (_Qui gardera les gardiens?_ version log)

.exercise[

- Faire défiler les _logs_ de Logstash:
  ```bash
  docker service logs --follow --tail 1 elk_logstash
  ```

]

Vous devriez voir passer les messages de "pouls":

.small[
```json
{      "message" => "ok",
          "host" => "1a4cfb063d13",
      "@version" => "1",
    "@timestamp" => "2016-06-19T00:45:45.273Z"
}
```
]

---

## Tester le receveur GELF

- Dans une nouvelle fenêtre, nous allons générer un message de log.

- Nous utiliserons une conteneur éphémère, et le pilote de log GELF de Docker.

.exercise[

- Envoyer un message de test:
  ```bash
    docker run --log-driver gelf --log-opt gelf-address=udp://127.0.0.1:12201 \
           --rm alpine echo hello
  ```
]

Ce message de test devrait s'afficher dans les logs du conteneur Logstash.

---

## Envoyer des logs depuis un service

- Jusqu'ici, nos logs partaient d'un conteneur "classique"; allons faire la même chose au niveau d'un service.

- C'est notre jour de chance: les options `--log-driver` et `--log-opt` sont exactement les mêmes!

.exercise[

- Envoyer un message de test:
  ```bash
    docker service create \
           --log-driver gelf --log-opt gelf-address=udp://127.0.0.1:12201 \
           alpine echo hello
  ```

  <!-- ```wait Detected task failure``` -->
  <!-- ```keys ^C``` -->

]

Ce message de test devrait s'afficher pareil dans les logs du conteneur Logstash.

--

En réalité, *plusieurs messages vont remonter, et continuerons d'arriver de temps en temps*

---

## Conditions de redémarrage

- Par défaut, si un conteneur sort (ou est tué par `docker kill`, ou s'il manque de mémoire...)
  le Swarm va le redémarrer (potentiellement sur une autre machine)

- Ce comportement peut être modifié en utilisant l'option de *condition de redémarrage*

.exercise[

- Changer la condition de redémarrage pour empêcher Swarm de relancer à l'infini notre conteneur:
  ```bash
  docker service update `xxx` --restart-condition none
  ```
]

Les conditions de redémarrage sont `none`, `any`, and `on-error`.

D'autres options existent comme `--restart-delay`, `--restart-max-attempts`, et `--restart-window`.

---

## Se connecter à Kibana


- L'interface web Kibana est exposée sur le port 5601 du cluster

.exercise[

- Se connecter au port 5601 du cluster

  - si vous utilisez "Play-With-Docker", cliquez sur le badge (5601) au dessus du terminal

  - sinon, ouvrez dans le navigateur l'url : http://(adresse-IP-noeud):5601

]

---

## "Configurer" Kibana

- Kibana devrait vous proposer de _"Configure an index pattern"_:
  <br/>dans la liste _"Time-field name"_, choisir "@timestamp" et cliquez
  le bouton "Create".

- Puis:

  - cliquer "Discover" (en haut à gauche),
  - cliquer "Last 15 minutes" (en haut à droite),
  - cliquer "Last 1 hour" (dans la liste au milieu),
  - cliquer "Auto-refresh" (coin supérieur droit),
  - cliquer "5 seconds" (en haut à gauche de la liste).

- Vous pouvez voir une série de barres vertes (avec une nouvelle barre toutes les minutes)

---

## Rediriger nos services vers GELF

- Nous allons dire à notre Swarm d'ajouter le log GELF à tous nos services

- C'est réalisé avec la commande `docker service update`

- Les options de log sont les mêmes qu'avant

.exercise[

- Activer le log GELF pour le service `rng`:
  ```bash
    docker service update dockercoins_rng \
           --log-driver gelf --log-opt gelf-address=udp://127.0.0.1:12201
  ```

]

Après env. 15 secondes, vous devriez voir les messages de log dans Kibana.

---

## Afficher nos logs de conteneur

- Retourner à Kibana

- Les logs de conteneur devrait s'afficher!

- On peut personnaliser l'interface web pour la rendre plus claire.

.exercise[

- Dans la colonne de gauche, bouger la souris sur les colonnes suivantes, et cliquer sur le bouton "Add" qui apparait:
  - host
  - container_name
  - message

<!--
  - logsource
  - program
  - message
-->

]

---

## .warning[Ne pas mettre à jour des services _stateful_]

- Que se serait-il passé si nous avions modifié le service Redis?

- Quand un service change, SwarmKit remplace un conteneur existant par un autre.

- C'est très bien pour des services _stateless_.

- Mais si vous changez un service à données persistentes (_stateful_), ses données vont être perdues dans l'opération.

- Mais si on met à jour notre service Redis, tous nos DockerCoins vont être perdus.

---


## Postface importante

**Ce n'est pas une installation de niveau "production".**

Il s'agit d'un exemple à but éducatif. Puisque nous avons
un seul serveur, nous avons installé une seule instance
ElasticSearch et une seule instance Logstash.

Dans une installation de "production", vous avez besoin
d'un cluster ElasticSearch (pour la haute disponibilité
et la capacité totale de stockage). Vous avez aussi
besoin de plusieurs isntances de Logstash.

Et si vous voulez résister aux pics de _logs_, vous aurez
besoin d'une sorte de file d'attente de messages: Redis
si c'est léger, Kafka si vous voulez garantir aucune perte.
Bonne chance.

<<<<<<< HEAD
Pour en savoir plus sur le pilote GELF, jetez un oeil sur
[ce billet de blog](
=======
If you want to learn more about the GELF driver,
have a look at [this blog post](
>>>>>>> master
https://jpetazzo.github.io/2017/01/20/docker-logging-gelf/).
