## Versions installées

- Kubernetes 1.14.3
- Docker Engine 18.09.6
- Docker Compose 1.21.1

<!-- ##VERSION## -->

.exercise[

- Vérifier toutes les versions installées:
  ```bash
  kubectl version
  docker version
  docker-compose -v
  ```

]

---

class: extra-details

## Compatibilité entre Kubernetes et Docker

- Kubernetes 1.13.x est uniquement validé avec les versions Docker Engine [jusqu'à to 18.06](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.13.md#external-dependencies)

- Kubernetes 1.14 est validé avec les versions Docker Engine versions [jusqu'à 18.09](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.14.md#external-dependencies)
  <br/>
  (la dernière version stable quand Kubernetes 1.14 est sorti)

- Est-ce qu'on vit dangereusement en installant un Docker Engine "trop récent"?

--

class: extra-details

- Que nenni!

- "Validé" = passe les tests d'intégration continue très intenses (et coûteux)

- L'API Docker est versionnée, et offre une comptabilité arrière très forte.

  (Si un client "parle" l'API v1.25, le Docker Engine va continuer à se comporter de la même façon)
