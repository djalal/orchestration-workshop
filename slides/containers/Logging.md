# Gestion des _logs_

Dans ce chapitre, nous expliquerons les différentes manières d'envoyer des _logs_ depuis les conteneurs.

Nous verrons ensuite une méthode particulière en action, avec ELK et les pilotes de _logs_ de Docker.

---

## On peut envoyer des _logs_ de bien des manières

- La méthode la plus simple est d'écrire sur les sorties standard et d'erreur.

- Les applications peuvent écrire leur logs dans des fichiers locaux.

  (Ces fichiers sont soumis à une compression et une mise en rotation.)

- Il est aussi très commun (sur système UNIX) d'utiliser syslog.

  (Les logs sont collectés par syslogd ou un équivalent, tel journald)

- Pour d'importantes applis aux nombreux composants, il est commun de passer par un service de _logs_.

  (Le code utilise une bibliothèque pour envoyer des messages au service)

*Toutes ces méthodes sont possibles avec les conteneurs.*

---

## Écrire sur _stdout/stderr_

- Les sorties standard et erreur de conteneurs sont gérées par le moteur de conteneurs.

- Cela signifie que chaque ligne écrite par le conteneur est reçue par le moteur.

- Ce moteur peut alors se "débrouiller" avec ces lignes de _logs_.

- Avec Docker, la configuration par défaut est d'écrire ces _logs_ dans des fichiers locaux.

- Les fichiers peuvent être consultés avec `docker logs` (et les requêtes équivalentes de l'API).

- Ce comportement peut être personnalisé, comme on le verra plus tard.

---

## Écrire dans des fichiers locaux

- Si on écrit dans des fichiers, il est possible d'y accéder mais c'est assez laborieux.

  (On doit passer par `docker exec` ou `docker cp`.)

- En outre, si le conteneur s'arrête, on ne peut plus lancer `docker exec`.

- Pire, si le conteneur est effacé, les logs disparaîtront.

- Alors que faire pour les programmes qui peuvent uniquement écrire en local?

--

- Il y a plusieurs solutions.

---

## Utiliser un volume ou un point de montage

- Au lieu de stocker les _logs_ dans un dossier normal, on les place sur un volume.

- Le volume est accessible par d'autres conteneurs.

- On lance un exécutable tel que `filebeat` dans un autre conteneur accédant au même volume.

  (`filebeat` lit en continu les fichiers de _logs_ locaux, comme `tail -f`,
  et les envoie dans un système central tel que ElasticSearch.)

- On peut aussi passer par un point de montage, par ex. `-v /var/log/containers/www:/var/log/tomcat`.

- Le conteneur va écrire les fichiers de _logs_ dans un dossier exposé sur l'hôte.

- Les fichiers _logs_ vont apparaître sur l'hôte et être accessible directement sur l'hôte.

---

## Utiliser les services de journalisation

- On peut utiliser des frameworks (comme log4j) ou le paquet Python `logging`).

- Ces frameworks exigent de coder et/ou configurer notre application.

- Ces mécanismes sont valables aussi bien dans le conteneur qu'en dehors.

- Parfois, on peut exploiter le réseau de conteneurs pour simplifier de telles configurations.

- Par exemple, notre code peut envoyer des messages de _logs_ à un serveur appelé `log`.

- Le nom `log` sera résolu différemment selon qu'on est en développement, production, etc.

---

## Utiliser syslog

- Et si notre code (ou le programme qu'on fait tourner dans le conteneur) utilise syslog?

- Une possibilité serait de lancer un daemon syslog dans le conteneur.

- Et ce daemon peut être configuré pour écrire dans des fichiers locaux ou transmettrer les _logs_ à travers le réseau.

- Sous le capot, les clients syslog se connectent à une socket locale UNIX, `/dev/log`.

- On devra donc exposer une socket syslog au conteneur (via un volume ou un point de montage).

- Et terminer en créant un lien symbolique depuis `/dev/log` vers la socket syslog.

- Voilà!

---

## Utiliser les pilotes de journalisation

- Si on écrit sur stdout et stderr, le moteur de conteneur reçoit les messages de _log_.

- Le Docker Engine dispose d'un système de _log_ modulaire avec de nombreux plugins, dont:

  - json-file (par défaut)
  - syslog
  - journald
  - gelf
  - fluentd
  - splunk
  - etc.

- Chaque plugin peut traiter et transmettre les _logs_ à un autre processus ou système.

---

## Avertissement à propos de `json-file`

- Par défaut, la taille du fichier de log est illimitée.

- Cela signifie qu'un conteneur très bavard *videra* certainement tout l'espace disque.

  (ou un conteneur moins bavard aussi, mais dans un laps de temps très long.)

- La rotation de _logs_ peut-être activée avec l'option `max-size`.

- D'anciens fichiers de _logs_ peuvent être supprimés avec l'option `max-file`.

- Toutes ces options relatives à la journalisation peuvent être réglées par conteneur, ou globalement.

Exemple:
```bash
$ docker run --log-opt max-size=10m --log-opt max-file=3 elasticsearch
```

---

## Démo: envoyer les _logs_ à ELK

- Nous allons déployer la suite ELK.

- Elle acceptera les _logs_ via une socket GELK.

- Nous allons lancer quelques conteneurs avec le pilote de log `gelf`.

- Nous verrons alors nos logs dans Kibana, l'interface web fournie par ELK.

*Avant-propos important: ce n'est pas une installation "officielle" ou
"recommandée"; juste un exemple. Nous avons choisi ELK pour cette
démo par sa popularité et les demandes qu'il suscite; mais vous serez
aussi gagnant avec Fluent ou d'autres solutions de journalisation!*

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
  <br/> et affichées dans la sortie standard de Logstash pour débogage.

---

## Lancer ELK

- Nous allons utiliser un fichier Compose décrivant la solution ELK.

- The Compose file is in the container.training repository on GitHub.

```bash
$ git clone https://github.com/jpetazzo/container.training
$ cd container.training
$ cd elk
$ docker-compose up
```

- Jetons un oeil au fichier Compose pendant qu'il se déploie.

---

## Notre déploiement ELK basique

- Nous allons utiliser des images du Docker Hub: `elasticsearch`, `logstash`, `kibana`.

- Pas besoin de changer la configuration d'ElasticSearch.

- Mais nous devons donner à Kibana l'adresse d'ElasticSearch:

  - elle est indiquée dans la variable d'environnement `ELASTICSEARCH_URL`

  - par défaut, c'est `localhost:9200`, on va la changer en `elasticsearch:9200`.

  - On a besoin de configurer Logstash:

    - on lui passe un fichier de configuration entier via la ligne de commande,

    - c'est une bidouille pour éviter de générer une image juste pour la config.

---

## Envoyer des logs à ELK

- La solution ELK accepte des messages via une socket GELK.

- La socket GELF écoute sur le port UDP 12201.

- Pour envoyer un message, on a besoin de changer le pilote de journalisation utilisé par Docker.

- Cela peut être réalisé en global (en reconfigurant le moteur) ou par conteneur.

- Essayons de rédéfinir le pilote de journalisation pour un seul conteneur:

```bash
$ docker run --log-driver=gelf --log-opt=gelf-address=udp://localhost:12201 \
  alpine echo hello world
```

---

## Afficher les _logs_ dans ELK

- Se connecter à l'interface Kibana.

- Il est exposé sur le port 5601.

- Ouvrir http://X.X.X.X:5601.

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

- Notre message "Hello world" devrait y apparaître.

---

## Postface importante

**Ce n'est pas une installation de niveau "production".**

Il s'agit d'un exemple à but éducatif. Puisque nous avons
un seul serveur, nous avons installé une seule instance
ElasticSearch et une seule instante Logstash.

Dans une installation de "production", vous avez besoin
d'un cluster ElasticSearch (pour la haute disponibilité
et la capacité totale de stockage). Vous avez aussi
besoin de plusieurs isntances de Logstash.

Et si vous voulez résister aux pics de _logs_, vous aurez
besoin d'une sorte de file d'attente de messages: Redis
si c'est léger, Kafka si vous voulez garantir aucune perte.
Bonne chance.

Pour en savoir plus sur le pilote GELF, jetez un oeil sur
[ce billet de blog](
https://jpetazzo.github.io/2017/01/20/docker-logging-gelf/).
