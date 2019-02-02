
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

## Build, ship, and run, for a single service

If we had only one service (built from a `Dockerfile` in the
current directory), our workflow could look like this:

```
docker build -t jpetazzo/doublerainbow:v0.1 .
docker push jpetazzo/doublerainbow:v0.1
docker service create jpetazzo/doublerainbow:v0.1
```

We just have to adapt this to our application, which has 4 services!

---

## Le plan

- Lancer un _build_ sur notre node locale (`node1`)

- Étiquetter les images pour les nommer `localhost:5000/<nom-du-service>`

- Téléverser sur le registre

- Créer les services grâce à ces images

---

## Which registry do we want to use?

.small[

- **Docker Hub**

  - hosted by Docker Inc.
  - requires an account (free, no credit card needed)
  - images will be public (unless you pay)
  - located in AWS EC2 us-east-1

- **Docker Trusted Registry**

  - self-hosted commercial product
  - requires a subscription (free 30-day trial available)
  - images can be public or private
  - located wherever you want

- **Docker open source registry**

  - self-hosted barebones repository hosting
  - doesn't require anything
  - doesn't come with anything either
  - located wherever you want

- **Lots of 3rd party cloud or self-hosted options**

  - AWS/Azure/Google Container Registry
  - GitLab, Quay, JFrog
  
]

---

class: extra-details

## Using Docker Hub

*If we wanted to use the Docker Hub...*

- We would log into the Docker Hub:
  ```bash
  docker login
  ```

- And in the following slides, we would use our Docker Hub login
  (e.g. `jpetazzo`) instead of the registry address (i.e. `127.0.0.1:5000`)

---

class: extra-details

## Using Docker Trusted Registry

*If we wanted to use DTR, we would...*

- Make sure we have a Docker Hub account

- [Activate a Docker EE subscription](
  https://hub.docker.com/enterprise/trial/)

- Install DTR on our machines

- Use `dtraddress:port/user` instead of the registry address

*This is out of the scope of this workshop!*
