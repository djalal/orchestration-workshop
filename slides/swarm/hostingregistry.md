# Héberger notre propre _Registry_

- On souhaite lancer un conteneur `registry`

- Il va stocker les images et _layers_ dans le système de fichiers local
  <br/>(mais on peut y ajouter un fichier de conf pour passer sur S3, Swift, etc.)

- Docker *exige* TLS pour communiquer avec le registre

  - excepté pour les registres sur `127.0.0.1` (i.e `localhost`)

  - ou avec l'option globale `--insecure-registry`

<!-- -->

- Notre stratégie: rendre public le conteneur du registre sur le port 5000,
  <br/>pour qu'il soit disponible via `127.0.0.1:5000` sur chaque _node_


---

## Déployer le registre

- Nous allons créer un service à instance unique, en publiant son port
  sur le cluster en entier

.exercise[

- Déclarer le service du registre:
  ```bash
  docker service create --name registry --publish 5000:5000 registry
  ```

- Essayer maintenant la commande suivante: on devrait voir `{"repositories":[]}`:
  ```bash
  curl 127.0.0.1:5000/v2/_catalog
  ```

]
