class: btp-manual

## Intégration avec Compose

- On a vu comment _build_ à la main, étiquetter et pousser les images dans un registre.

- Mais ...

--

class: btp-manual

*Je suis tellement content que mon déploiement se base sur des scripts Shell de taille astronomique*

*(par M. Personne, vraiment)*

--

class: btp-manual

- Voyons voir comment simplifier ce processus!

---

# Les _Stacks_ Swarm

- Compose est super pour le développement local

- On peut aussi gérer le cycle de vie des images avec

  (i.e générer les images et les pousser dans un registre)

- Les fichiers Compose en *v2* sont bons dans le développement local

- Les fichiers Compose en *v3* sont orientés vers le déploiement en production!

---

## Fichier Compose version 3

(Nouveau dans Docker Engine 1.13)

- Pratiquement identique à la version 2

- Peut être directement appliqué à un cluster Swarm avec les commandes `docker stack ...`

- Introduit une section `deploy` pour spécifier les options Swarm

- Les limites de ressources sont placées dans cette section `deploy`

- Voir [ici](https://github.com/docker/docker.github.io/blob/master/compose/compose-file/compose-versioning.md#upgrading) pour une liste complète de changements

- Supplante les *Distributed Application Bundles*

  (Un format JSON décrivant une application; pouvait à l'origine être généré depuis un fichier Compose)

---

## Notre première _stack_

On a besoin d'un registre pour déplacer les images de point en point.

Sans ce fichier _stack_, on devrait taper les commandes suivantes:

```bash
docker service create --publish 5000:5000 registry
```

Dès lors, nous allons le déployer avec le fichier de _stack_ suivant:

```yaml
version: "3"

services:
  registry:
    image: registry
    ports:
      - "5000:5000"
```

---

## Vérifier nos fichiers _stack_

- Tous les fichiers _stack_ que nous utiliserons sont stockés dans le dossier `stacks`

.exercise[

- Aller dans le dossier `stack`:
  ```bash
  cd ~/container.training/stacks
  ```

- Parcourir `registry.yml`
  ```bash
  cat registry.yml
  ```

]

---

## Déployer notre première _stack_

- Toutes les commandes de manipulation de _stacks_ commencent avec `docker stack`

- En coulisses, ça se traduit par des commandes `docker service`

- Une _stack_ porte un nom principal (qui sert aussi de _namespace_)

- Une _stack_ est portée avant tout par un fichier Compose de version 3 comme dit plus haut

.exercise[

- Déployer notre registre local:
  ```bash
  docker stack deploy --compose-file registry.yml registry
  ```

]

---

## Inspecter les _stacks_

- `docker stack ps` affiche l'état détaillé de tous les services d'une _stack_

.exercise[

- Vérifier que notre registre tourne correctement:
  ```bash
  docker stack ps registry
  ```

- Confirmer que nous avons le même affichage avec la commande:
  ```bash
  docker service ps registry_registry
  ```

]

---

class: btp-manual

## Particularités d'un déploiement de _stack_

Notre registre n'est pas *exactement* identique à celui déployé par `docker service create`!

- Chaque _stack_ possède sont propre réseau superposé (_overlay_)

- Les services de la _stack_ sont connectés à ce réseau
  <br/>(sauf si spécifié autrement dans le fichier Compose)

- Les services récupèrent des alias de réseau correspondant à leur nom dans le fichier COmpose
  <br/>(tout comme quand Compose lance une appli en version 2)

- Les services sont nommés explicitement `<nom_de_stack>_<nom_de_service>`

- Les services et tâches récupèrent aussi un label interne indiquant à quelle _stack_ ils appartiennent

---

class: btp-auto

## Tester notre registre local

- Accéder au port 5000 *de n'importe quelle node* nous redirige vers le registre

- Par conséquent, on peut indiquer `localhost:5000` ou `127.0.0.1:5000` comme notre registre

.exercise[

- Envoyer la requête API qui suit au registre:
  ```bash
  curl 127.0.0.1:5000/v2/_catalog
  ```

]

Ça devrait renvoyer:

```json
{"repositories":[]}
```

Si ça ne marche pas, ré-essayer encore; le conteneur est peut-être en cours de démarrage.

---

class: btp-auto

## Pousser une image vers notre registre local

- On peut re-_tag_ une petite image, et la pousser vers le registre.

.exercise[

- Charger l'image busybox, et la re-_tag_:
  ```bash
  docker pull busybox
  docker tag busybox 127.0.0.1:5000/busybox
  ```

- La transférer:
  ```bash
  docker push 127.0.0.1:5000/busybox
  ```

]

---

class: btp-auto

## Vérifier ce qui est dans notre registre local

- L'API Registre a des points d'entrée pour sélectionner son contenu.

.exercise[

- S'assurer que notre image busybox est maintenant dans notre registre local:
  ```bash
  curl http://127.0.0.1:5000/v2/_catalog
  ```

]

La commande curl devrait maintenant afficher:
```json
"repositories":["busybox"]}
```

---

## Générer et pousser les services d'une _stack_

- Avec le fichier Compose version 2 et plus, vous pouvez spécifier *à la fois* `build` et `image`

- Quand les deux clés sont utilisées:

  - Compose fait "comme si de rien n'était" (activer le `build`)

  - mais l'image résultante sera nommée selon la valeur de la clé `image`
    <br/>
    (au lieu de `<nom-du-projet>_<nom-du-service>:latest`)

  - avec l'avantage qu'on peut la pousser dans un registry avec `docker-compose push`

- Exemple:

  ```yaml
    webfront:
      build: www
      image: myregistry.company.net:5000/webfront
  ```

---

## Utiliser Compose pour générer et pousser les images

.exercise[

- Essayer:
  ```bash
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  ```

]

Voyons voir à quoi ressemble le fichier `dockercoins.yml` pendant que les images sont construites et poussées.

---

```yaml
version: "3"

services:
  rng:
    build: dockercoins/rng
    image: ${REGISTRY-127.0.0.1:5000}/rng:${TAG-latest}
    deploy:
      mode: global
  ...
  redis:
    image: redis
  ...
  worker:
    build: dockercoins/worker
    image: ${REGISTRY-127.0.0.1:5000}/worker:${TAG-latest}
    ...
    deploy:
      replicas: 10
```

---

## Déployer l'application

- Maintenant que les images sont sur le registre, on peut déployer notre _stack_ applicative.

.exercise[

- Créer la _stack_ applicative:
  ```bash
  docker stack deploy --compose-file dockercoins.yml dockercoins
  ```

]

On peut maintenant se connecter à n'importe quel noeud sur le port 8000, et revoir le graphe familier du hachage.

---

## Maintenir plusieurs environnements

Plusieurs méthodes existent pour gérer les variations entre environnements.

- Compose charge `docker-compose.yml` et (s'il existe) `docker-compose.override.yml`

- Compose va charger plusieurs fichiers en accumulant l'option `-f` ou la variable d'environnement `COMPOSE_FILE`

- Les fichiers Compose peuvent *étendre* d'autres fichier Compose, pour y inclure des services:

  ```yaml
    web:
      extends:
        file: common-services.yml
        service: webapp
  ```

Voir [cette page de documentation](https://docs.docker.com/compose/extends/) pour plus de détails sur ces techniques.

---

class: extra-details

## Bon à savoir ...

- Un fichier Compose en version 3 comporte une section `deploy`

- Les versions plus récentes (3.1, ...) ajoutent plus de fonctions (secrets, configs, etc.)

- Mettre à jour la _stack_ consiste à relancer `docker stack deploy`

- On peut changer le service à coups de `docker service update` ...

- ... Mais tout changement sera annulé après chaque `docker stack deploy`

  (C'est le comportement attendu, si on y réfléchit bien!)

- `extends` ne marche pas avec `docker stack deploy`

  (Mais vous pouvez passer par `docker-compose config` pour "applatir" votre conf)

---

## Résumé

- On a vu comment installer un Swarm

- On l'a utilisé pour héberger notre propre _Registry_

- On a généré nos images de conteneurs

- On a utilisé la _Registry_ pour héberger ces images

- On a déployé et escaladé notre application

- On a vu comment exploiter Compose pour simplifier les déploiements

- Super boulot à toute l'équipe!
