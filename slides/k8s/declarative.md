## Déclaratif vs Impératif dans Kubernetes

- Pratiquement tout ce que nous lançons sur Kubernetes est déclaré dans une *spec*

- Gardez un oeil sur les champs `spec` dans les fichiers YAML plus tard!

- La *spec* décrit *comment on voudrait que ce truc tourne*

- Kubernetes va *réconcilier* l'état courant avec la *spec*
  <br>(techniquement, c'est possible via un tas de *controllers*)

- Quand on veut changer une ressources, on modifie la *spec*

- Kubernetes va alors *faire converger* cette ressource
