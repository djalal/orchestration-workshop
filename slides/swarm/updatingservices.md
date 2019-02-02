# Mettre à jour les services

- On doit mettre à jour l'interface web.

- Pour ce faire, le processus est comme suit:

  - _patcher_ le code

  - générer une nouvelle image (_build_)

  - stocker cette image à distance (_ship_)

  - lancer la nouvelle version (_run_)

---

## Modifier un seul service avec `service update`

- Pour mettre à jour un seul service, on pourrait procéder comme suit:
  ```bash
  export REGISTRY=127.0.0.1:5000
  export TAG=v0.2
  IMAGE=$REGISTRY/dockercoins_webui:$TAG
  docker build -t $IMAGE webui/
  docker push $IMAGE
  docker service update dockercoins_webui --image $IMAGE
  ```

- Assurez-vous de mettre le bon _tag_ sur l'image: modifier le `TAG` à chaque itération

  (Quand vous allez vérifier quelles images tournent, on a intérêt à disposer de _tags_ uniques et explicites)

---

## Modifier nos services avec `stack deploy`

- Avec l'intégration de Compose, tout ce que nous avons à faire est:
  ```bash
  export TAG=v0.2
  docker-compose -f composefile.yml build
  docker-compose -f composefile.yml push
  docker stack deploy -c composefile.yml nameofstack
  ```

--

- C'est exactement ce que nous avons utilisé plus tôt pour déployer l'appli

- Pas besoin d'apprendre de nouvelles commandes!

- Docker va calculer la différence pour chaque service et ne mettre à jour que ce qui a changé.

---

## _Patcher_ le code

- Essayons d'agrandir les chiffres sur l'axe Y!

.exercise[

- Mettre à jour la taille du texte sur notre _webui_
  ```bash
  sed -i "s/15px/50px/" dockercoins/webui/files/index.html
  ```

]

---

## Générer, livrer et lancer nos changements

- Quatre étapes:

  1. Définir (et exporter!) la variable d'envionnement `TAG`
  2. `docker-compose build`
  3. `docker-compose push`
  4. `docker stack deploy`

.exercise[

- Générer, livrer et lancer:
  ```bash
  export TAG=v0.2
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  docker stack deploy -c dockercoins.yml dockercoins
  ```

]

- Pour info: puisque nous changeons le _tag_ sur toutes les images dans cette démo v0.2, le _deploy_ va relancer tous les services.

---

## Tester nos changements

- Attendez au moins 10 secondes (pour laisser arriver la nouvelle version)

- Puis rechargez l'interface web

- Ou pianoter frénétiquement sur F5 (Cmd-R sur Mac)

- ... le texte de la légende sur la gauche finira par grossir!
