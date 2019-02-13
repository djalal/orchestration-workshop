class: secrets

## Gestion des _secrets_

- Docker a son propre "coffre-fort à secrets" (pour stockage chiffré de clé-valeur)

- Vous pouvez y déposer autant de _secrets_ que vous souhaitez

- On peut ensuite associer ces secrets aux services

- Les secrets sont exposés comme des fichiers texte simples,
  <br/>mais ils sont conservés en mémoire (via `tmpfs`)

- Les secrets sont immuables (depuis Docker Engine 1.13)

- Un secret peut peser jusqu'à 500Ko

---

class: secrets

## Déclarer de nouveaux _secrets_

- On doit choisir un nom pour ce _secret_; et associer le contenu lui-même

.exercise[

- Assigner [un des quatre mots de passe les plus communs](https://www.youtube.com/watch?v=0Jx8Eay5fWQ) à un secret baptisé `piratemoi`:
  ```bash
  echo love | docker secret create piratemoi -
  ```

]

Si le secret est dans un fichier, on peut simplement pointer vers le chemin complet du fichier.

(Le chemin spécial `-` indique que la source est l'entrée standard _stdin_)

---

class: secrets

## Mieux déclarer ses _secrets_

- Choisir des mots de passe de paresseux conduit toujours à des intrusions

.exercise[

- Déclarer un meilleur mot de passe, et l'assigner à un autre _secret_:
  ```bash
  base64 /dev/urandom | head -c16 | docker secret create rienadeclarer -
  ```

]

Note: dans ce cas, on n'a même aucune idée du mot de passe. Mais Swarm, le sait, lui.

---

class: secrets

## Usage des _secrets_

- Les _secrets_ doivent être affectés de façon explicite aux services

.exercise[

- Déclarer un nouveau service de test avec les 2 secrets:
  ```bash
    docker service create \
           --secret piratemoi --secret rienadeclarer \
           --name dummyservice \
           --constraint node.hostname==$HOSTNAME \
           alpine sleep 1000000000
  ```

]

On force le conteneur à être sur la _node_ locale pour plus de convenance.
<br/>
(On va lancer un `docker exec` dans la foulée!)

---

class: secrets

## Accéder à nos secrets

- Les secrets sont disponibles dans `/run/secrets` (qui est en réalité un système de fichiers sur-mémoire)

.exercise[

- Trouver l'ID du conteneur pour le service de test:
  ```bash
  CID=$(docker ps -q --filter label=com.docker.swarm.service.name=dummyservice)
  ```

- Entrer dans le conteneur:
  ```bash
  docker exec -ti $CID sh
  ```

- Vérifier les fichiers dans `/run/secrets`

<!-- ```bash grep . /run/secrets/*``` -->
<!-- ```bash exit``` -->

]

---

class: secrets

## Renouveler les secrets

- On ne peut mettre à jour un _secret_

  (On dirait un inconvénient au premier abord; mais cela permet des _rollbacks_ propres si un changement de secret se passe mal)

- Vous pouvez ajouter un secret à un service avec `docker service update --secret-add`

  (Cela va redéployer le service; le _secret_ ne sera pas ajouté à la volée)

- Vous pouvez retirer un _secret_ avec `docker service update --secret-rm`

- Les _secrets_ peuvent être associés à des noms différents en utilisant un micro-format:
  ```bash
  docker service create --secret source=secretname,target=filename
  ```

---

class: secrets

## Changer notre mot de passe non sécurisé

- On doit remplacer notre _secret_ `piratemoi` avec une meilleure version.

.exercise[

- Retirer le secret `piratemoi` trop faible:
  ```bash
  docker service update dummyservice --secret-rm piratemoi
  ```

- Ajouter notre meilleur _secret_ à sa place:
  ```bash
  docker service update dummyservice \
         --secret-add source=rienadeclarer,target=piratemoi
  ```

]

Attendez que le service soit complètement mis à jour, avec par ex. `watch docker service ps dummyservice`.
<br/>(Avec Docker Engine 17.10 et plus, la CLI attendra pour vous!)

---

class: secrets

## Vérifier que notre mot de passe est maintenant plus fort!

- On va invoquer le pouvoir du `docker exec`!

.exercise[

- Récupérer l'ID de notre nouveau conteneur:
  ```bash
  CID=$(docker ps -q --filter label=com.docker.swarm.service.name=dummyservice)
  ```

- Vérifier le contenu des fichiers secrets:
  ```bash
  docker exec $CID grep -r . /run/secrets
  ```

]

---

class: secrets

## Les _secrets_ en pratique

- A consommer sans modération, jusqu'à stocker des fichiers de config complets

- Pour renouveler un secret `foo`, renommez-le plutôt `foo.N`, et l'attacher à `foo`

  (N peut être un compteur, un timestamp ...)

  ```bash
  docker service create --secret source=foo.N,target=foo ...
  ```

- On peut mettre à jour (ajouter+supprimer) en une seule commande:

  ```bash
  docker service update ... --secret-rm foo.M --secret-add source=foo.N,target=foo
  ```

- Pour plus de détails et d'exemples, [voir la documentation](https://docs.docker.com/engine/swarm/secrets/)
