class: self-paced

## Avant de continuer ...

Les prochains exercices supposent que vous avez un cluster Swarm de 5 noeuds.

Si vous venez d'un tutoriel précédent, et qus vous avez encore votre cluster: super!

Autrement: voyez la [partie n°1](#part-1) pour apprendre comment installer votre propre cluster.

On reprendra exactement où on vous a laissé, en supposant que vous avez:

 - un cluster Swarm de 2 ou 3 nodes,

 - un registre auto-hébergé,

 - l'appli DockerCoins qui tourne.

La prochaine diapo est un condensé si vous avez besoin d'un rattrapage.

---

class: self-paced

## Cours de rattrapage

Assuming you have 5 nodes provided by
[Play-With-Docker](https://www.play-with-docker/), do this from `node1`:

```bash
docker swarm init --advertise-addr eth0
TOKEN=$(docker swarm join-token -q manager)
for N in $(seq 2 5); do
  DOCKER_HOST=tcp://node$N:2375 docker swarm join --token $TOKEN node1:2377
done
git clone https://@@GITREPO@@
cd container.training/stacks
docker stack deploy --compose-file registry.yml registry
docker-compose -f dockercoins.yml build
docker-compose -f dockercoins.yml push
docker stack deploy --compose-file dockercoins.yml dockercoins
```

You should now be able to connect to port 8000 and see the DockerCoins web UI.
