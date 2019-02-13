# Mises à jour progressive

- Essayons de forcer une mise à jour de _hasher_ pour examiner le processus.

.exercise[

- Escalader d'abord _hasher_ à 7 replicas:
  ```bash
  docker service scale dockercoins_hasher=7
  ```

- Forcer une mise à jour progressive (qui remplace les conteneurs) vers une image différente:
  ```bash
  docker service update --image 127.0.0.1:5000/hasher:v0.1 dockercoins_hasher
  ```

]

- Vous pouvez lancer `docker events` sur un autre terminal de `node1` pour voir les actions du Swarm.

- Vous pouvez forcer `--force` pour remplacer les conteneurs sans changer la configuration.

---

## Changer la politique de mise à jour

- On peut jouer sur plein d'options sur les profils de mise à jour.
.exercise[

- Changer le parallélisme à 2, et le taux d'échec maximum à 25%:
  ```bash
    docker service update --update-parallelism 2 \
      --update-max-failure-ratio .25 dockercoins_hasher
  ```

]

- Aucun conteneur n'a été remplacé, c'est ce qu'on appelle une mise à jour "sans op".

- Les _patch_ de méta-données pures n'exigent aucune opération de l'orchestrateur

---

## Changer les règles depuis le fichier Compose

- Cette même politique peut aussi apparaître dans le fichier Compose.

- On le fait en ajoutant une clé `update_config` sous la clé `deploy`:

  ```yaml
    deploy:
      replicas: 10
      update_config:
        parallelism: 2
        delay: 10s
  ```

---

## Retour arrière

- A n'importe quel moment (par ex. avant la fin de la mise à jour), on peut tout annuler:

  - en modifiant le fichier Compose et relancer une mise à jour

  - en utilisant l'option `--rollback` de `service update`

  - en utilisant `docker service rollback`

.exercise[

- Essayer d'annuler la mise à jour du service _webui_
  ```bash
  docker service rollback dockercoins_webui
  ```

]

Que se passe-t-il avec le graphique de l'interface web?

---

## Les subtilités du _rollback_

- Le retour arrière annule la dernière définition du service

  - voir `PreviousSpec` dans `docker service inspect <nom_du_service>`

- Si nous nous représentons les mises à jour comme une pile:

  - ça ne va pas "dépiler" la dernière mise à jour

  - cela va "empiler" une copie de la dernière mise à jour tout en haut de la pile

  - _ergo_, opérer deux retours arrière successifs ne change rien.

- La "définition de service" inclut la cadence de déploiement.

- Chaque commande `docker service update` = une nouvelle définition de service

---

class: extra-details

## Chronologie d'une mise à jour

- SwarmKit va mettre à jour N instances à la fois
  <br/>(suivant la valeur de l'option `update-parallelism`)

- De nouvelles tâches sont créées, et leur état souhaité est réglé à `Ready`
  <br/>.small[(cela va télécharger l'image si nécessaire, s'assurer de la disponibilité des ressources, créer le conteneur ... sans encore le démarrer)]

- Si une nouvelle tâche échoue à atteindre le statut `Ready`, retour à l'étape précédente
  <br/>.small[(SwarmKit va persister à essayer, jusqu'à dépannage du problème, ou si l'état souhaité est mis à jour)]

- Quand de nouvelles tâches sont `Ready`, les anciennes sont passées en `Shutdown`

- Quand d'anciennes tâches sont `Shutdown`, le Swarm en démarre de nouvelles

- Puis il attend le délai indiqué dans `update-delay`, et poursuit avec le prochain groupe d'instances.
