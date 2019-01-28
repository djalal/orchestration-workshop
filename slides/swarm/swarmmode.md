# Mode Swarm

- Depuis la version 1.12, le Docker Engine embarque SwarmKit

- Toutes les fonctions SwarmKit sont mise en "sommeil" jusqu'à activer le "Mode Swarm"

- Exemples de commandes Swarm Mode:

  - `docker swarm` (active le mode Swarm; rejoint un Swarm; ajuste les paramètres du cluster)

  - `docker node` (affiche les nodes; désigne les managers; gère les nodes)

  - `docker service` (crée et gère les services)

- L'API Docker expose les mêmes concepts

- L'API SwarmKit est aussi exposée (sur une socket séparée)

---

## Le mode Swarm doit être activé expressément

- Par défaut, tout ce code nouveau est inactif

- Le mode Swarm doit être activé, "déverrouillant" ainsi les fonctions SwarmKit
  <br/>(services, réseaux superposés prêts à l'emploi, etc.)

.exercise[

- Essayer une commande spéciale Swarm:
  ```bash
  docker node ls
  ```

<!-- Ignore errors: ```wait not a swarm manager``` -->

]

--

Vous aurez un message d'erreur:
```
Error response from daemon: This node is not a swarm manager. [...]
```
