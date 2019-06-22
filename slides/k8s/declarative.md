## Déclaratif vs Impératif dans Kubernetes

- Pratiquement tout ce que nous lançons sur Kubernetes est déclaré dans une *spec*

- Tout ce qu'on peut faire est écrire un *spec* et la pousser au serveur API

 (en déclarant des ressources comme *Pod* ou *Deployment*)

- Le serveur API va valider cette spec (la rejeter si elle est invalide)

- Puis la stocker dans etcd

- Un *controller* va "repérer" cette spécification et réagir en conséquence

---

## Réconciliation d'état

- Gardez un oeil sur les champs `spec` dans les fichiers YAML plus tard!

- La *spec* décrit *comment on voudrait que ce truc tourne*

- Kubernetes va *réconcilier* l'état courant avec la *spec*
  <br>(techniquement, c'est possible via un tas de *controllers*)

- Quand on veut changer une ressources, on modifie la *spec*

- Kubernetes va alors *faire converger* cette ressource
