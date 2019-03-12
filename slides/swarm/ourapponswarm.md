
# Notre appli sur Swarm

Dans cette partie, nous allons:

- **générer** les images pour notre appli,

- **envoyer** ces images dans un registre,

- **lancer** les services basés sur ces images.

---

## Pourquoi le besoin de transférer nos images?

- Avec `docker-compose up`, les images sont générées pour nos services

- Ces images sont présentes uniquement sur la node locale

- Nous avons besoin de distribuer ces images à travers tout le Swarm

- Le plus simple pour ceci est d'utiliser un Registry Docker

- Une fois nos images transférées sur un registre, nous les téléchargeons
au moment de créer nos services.

---

class: extra-details

## Builder, transférer et lancer, pour un seul service

Si nous avions seulement un service (généré à partir d'un `Dockerfile`
dans le dossier en cours), notre processus aurait cette tête:

```
docker build -t jpetazzo/doublerainbow:v0.1 .
docker push jpetazzo/doublerainbow:v0.1
docker service create jpetazzo/doublerainbow:v0.1
```

Il nous reste juste à l'adapter à notre application, qui comporte 4 services!

---

## Le plan

- Lancer un _build_ sur notre node locale (`node1`)

- Étiquetter les images pour les nommer en `localhost:5000/<nom-du-service>`

- Téléverser dans le registre

- Créer les services grâce à ces images

---

## Quel registre devons-nous utiliser?

.small[

- **Docker Hub**

  - hébergé par Docker Inc.
  - exige un compte (gratuit, sans carte bancaire)
  - images publiques (sauf si vous payez)
  - localisé chez AWS sur EC2 us-east-1

- **Docker Trusted Registry**

  - produit commercial auto-hébergé
  - exige un abonnement (avec essai gratuit de 30 jours)
  - images publiques ou privées
  - localisé où vous le souhaitez

- **Docker open source registry**

  - stockage d'image basique en mode auto-hébergé
  - n'exige rien du tout, aucun pré-requis
  - n'offre pas grand-chose non plus
  - localisé où vous voulez

- **Tout plein d'autres options dans le cloud ou pas**

  - AWS/Azure/Google Container Registry
  - GitLab, Quay, JFrog
  - Portus, Harbor
]

---

class: extra-details

## Utiliser Docker Hub

*Si on voulait passer par Docker Hub...*

- On devrait se connecter au Docker Hub
  ```bash
  docker login
  ```

- Et dans les diapos suivantes, on pourrait utiliser notre compte Docker Hub

  (par ex., `jpetazzo` au lieu de l'adresse du registre, i.e `127.0.0.1:5000`)

---

class: extra-details

## Utiliser Docker Trusted Registry

*Si on voulait utiliser DTR, on devrait...*

- S'assurer d'avoir un compte Docker Hub

- [Activer un abonnement Docker EE](
  https://hub.docker.com/enterprise/trial/)

- Installer DTR sur nos machines

- Marquer `dtraddress:port/user` au lieu de l'adresse du registre

*Tout ça est hors de notre périmètre*
