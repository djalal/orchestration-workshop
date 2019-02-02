name: cicd

# CI/CD avec Docker et l'orchestration

Une note rapide à propos de l'intégration rapide et du déploiement

- Vous n'allez pas monter dans cet atelier vos propres automatisations CI/CD

- On va tricher un peu en générant les images sur les serveurs hôtes et non sur l'outil "CI".

- Docker et l'orchestration fonctionne avec tous les outils de CI et de déploiement.

---

## Processus générique CI/CD

- En premier, c'est à la CI de _build_ les images, puis de lancer les tests *à l'intérieur*, avant de les pousser vers la _Registry_

- En cas de scan de sécurité, faites-le sur les images générées, après les tests mais avant de les pousser.

- En option, déployer en continu depuis votre CI, si les phases de build/test/push passent

- L'outil de CD accèderait ensuite aux noeuds via SSH, ou exploiterait la ligne de commande Docker pour discuter avec le moteur de conteneur distant.

- Si disponible, on passerait par l'API TCP du Docker Engine (où l'API Swarm vit aussi)

- Docker KBase [Development Pipeline Best Practices](https://success.docker.com/article/dev-pipeline)

- Docker KBase [Continuous Integration with Docker Hub](https://success.docker.com/article/continuous-integration-with-docker-hub)

- Docker KBase [Building a Docker Secure Supply Chain](https://success.docker.com/article/secure-supply-chain)

---

class: pic

![CI-CD with Docker](images/ci-cd-with-docker.png)
