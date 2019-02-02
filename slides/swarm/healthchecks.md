name: healthchecks

# Healthcheck et _rollback_ automatique

(Nouveau depuis Docker Engine 1.12)

- Des commandes exécutées à intervalles réguliers dans un conteneur.

- Doit retourner 0 ou 1 pour indiquer "Tout va bien" ou "Quelque chose "

- Doit s'exécuter rapidement (_timeout_ == erreurs)

- Exemple:
  ```bash
  curl -f http://localhost/_ping || false
  ```
  - l'option `-f` s'assure que `curl` retourne un statut non-nul pour 404 et autres erreurs
  - `|| false` garantit que tout code de sortie non nul se traduira par 1
  - `curl` doit être installé dans le conteneur à vérifier

---

## Définir ses _health checks_

- Dans un Dockerfile, avec l'instruction [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck)
  ```
  HEALTHCHECK --interval=1s --timeout=3s CMD curl -f http://localhost/ || false
  ```

- Depuis la ligne de commande, en lançant conteneurs ou services
  ```
  docker run --health-cmd "curl -f http://localhost/ || false" ...
  docker service create --health-cmd "curl -f http://localhost/ || false" ...
  ```

- Depuis les fichiers Compose, avec une section [healthcheck](https://docs.docker.com/compose/compose-file/#healthcheck) par service
  ```yaml
    www:
      image: hellowebapp
      healthcheck:
        test: "curl -f https://localhost/ || false"
        timeout: 3s
  ```

---

## Utiliser les _health checks_

- Avec `docker run`, tout contrôle de santé est purement informatif

  - `docker ps` affiche le dernier "bilan" de santé

  - `docker inspect` détaille certaines infos (comme la commande utilisée pour le contrôle)

- Avec `docker service`:

  - les tâches en mauvaise santé sont supprimées (i.e le service est redémarré)

  - les déploiements en échec peuvent être annulés automatiquement
    <br/>(en spécifiant *au moins* l'option `--update-failure-action rollback`)

---

## Activer les contrôles de santé et les _rollback_ auto

Voici un exemple complet utilisant la ligne de commande:

.small[
```bash
docker service update \
  --update-delay 5s \
  --update-failure-action rollback \
  --update-max-failure-ratio .25 \
  --update-monitor 5s \
  --update-parallelism 1 \
  --rollback-delay 5s \
  --rollback-failure-action pause \
  --rollback-max-failure-ratio .5 \
  --rollback-monitor 5s \
  --rollback-parallelism 0 \
  --health-cmd "curl -f http://localhost/ || exit 1" \
  --health-interval 2s \
  --health-retries 1 \
  --image votre-image:nouvelle-version votre_service
```
]

---

## Implémenter le _rollback_ automatique en pratique

Nous utiliserons comme exemple le fichier Compose suivant (`stacks/dockercoins+healthcheck.yml`):

```yaml
...
  hasher:
    build: dockercoins/hasher
    image: ${REGISTRY-127.0.0.1:5000}/hasher:${TAG-latest}
    healthcheck:
      test: curl -f http://localhost/ || exit 1
    deploy:
      replicas: 7
      update_config:
        delay: 5s
        failure_action: rollback
        max_failure_ratio: .5
        monitor: 5s
        parallelism: 1
...
```

---

## Activer l'auto-_rollback_ dans `dockercoins`

On a d'abord besoin d'indiquer un _healthcheck_ pour nos services.

.exercise[

- Entrer dans le dossier `stacks`:
  ```bash
  cd ~/container.training/stacks
  ```

- Déployer la _stack_ mise à jour avec les _healthchecks_ intégrés
  ```bash
  docker stack deploy --compose-file dockercoins+healthcheck.yml dockercoins
  ```

]

---

## Visualiser un _rollback_ automatisé

- Voici un bon exemple de l'importance des _healthchecks_

- Dans cette nouvelle version, une erreur va empêcher l'appli d'écouter sur le port correct

- Le conteneur va bien se lancer, sauf qu'aucune connexion sur le port 80 n'est possible

.exercise[

- Changer le port HTTP à écouter:
  ```bash
  sed -i "s/80/81/" dockercoins/hasher/hasher.rb
  ```

- Générer, livrer, et exécuter la nouvelle image:
  ```bash
  export TAG=v0.3
  docker-compose -f dockercoins+healthcheck.yml build
  docker-compose -f dockercoins+healthcheck.yml push
  docker service update --image=127.0.0.1:5000/hasher:$TAG dockercoins_hasher
  ```

]

---

## Options de la CLI pour _health checks_ et _rollbacks_

.small[
```
--health-cmd string                  Command to run to check health
--health-interval duration           Time between running the check (ms|s|m|h)
--health-retries int                 Consecutive failures needed to report unhealthy
--health-start-period duration       Start period for the container to initialize before counting retries towards unstable (ms|s|m|h)
--health-timeout duration            Maximum time to allow one check to run (ms|s|m|h)
--no-healthcheck                     Disable any container-specified HEALTHCHECK
--restart-condition string           Restart when condition is met ("none"|"on-failure"|"any")
--restart-delay duration             Delay between restart attempts (ns|us|ms|s|m|h)
--restart-max-attempts uint          Maximum number of restarts before giving up
--restart-window duration            Window used to evaluate the restart policy (ns|us|ms|s|m|h)
--rollback                           Rollback to previous specification
--rollback-delay duration            Delay between task rollbacks (ns|us|ms|s|m|h)
--rollback-failure-action string     Action on rollback failure ("pause"|"continue")
--rollback-max-failure-ratio float   Failure rate to tolerate during a rollback
--rollback-monitor duration          Duration after each task rollback to monitor for failure (ns|us|ms|s|m|h)
--rollback-order string              Rollback order ("start-first"|"stop-first")
--rollback-parallelism uint          Maximum number of tasks rolled back simultaneously (0 to roll back all at once)
--update-delay duration              Delay between updates (ns|us|ms|s|m|h)
--update-failure-action string       Action on update failure ("pause"|"continue"|"rollback")
--update-max-failure-ratio float     Failure rate to tolerate during an update
--update-monitor duration            Duration after each task update to monitor for failure (ns|us|ms|s|m|h)
--update-order string                Update order ("start-first"|"stop-first")
--update-parallelism uint            Maximum number of tasks updated simultaneously (0 to update all at once)
```
]
