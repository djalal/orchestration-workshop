## Toutes nouvelles versions!

- Engine 18.09
- Compose 1.23
- Machine 0.16

.exercise[

- Vérifier toutes les versions installées
  ```bash
  docker version
  docker-compose -v
  docker-machine -v
  ```

]

---

## Un moment, pardon, mais 18.09 ?!

--

- Docker 1.13 = Docker 17.03 (année.mois, comme Ubuntu)

- Chaque mois sort une version "edge" (avec les dernières nouveautés)

- Chaque trimestre sort une version "stable"

- Docker CE maintient ses versions pendant au moins 4 mois

- Docker EE maintient ses versions pendant au moins 12 mois

- Pour plus de détails, consultez le [billet de blog d'annonce de Docker EE](https://blog.docker.com/2017/03/docker-enterprise-edition/)

---

class: extra-details

## Docker CE vs Docker EE

- Docker EE:

  - $$$
  - certifié sur une sélection de distributions, de clouds et _plugins_
  - fonctions de gestion avancées (contrôle daccès fin, scans de sécurité, etc.)

- Docker CE:

  - gratuit
  - disponible via Docker for Desktop (éditions Mac etW Windows), et sur toutes les distributinos Linux majeures.
  - parfait pour développeurs individuels et petites organisations.

---

class: extra-details

## Pourquoi?

- Plus lisible pour les entreprises

  (i.e. les gentilles personnes qui sont assez sympas pour payer grassement nos services)

- Pas d'impact sur la communauté

  (en dehors du suffixe CE/EE et du changement de versioning)

- Les deux lignes exploitent les mêmes composants open source

  (containerd, libcontainer, swarmkit...)

- Calendrier de mise à jour plus prévisible (voir diapo suivante)

---

class: pic

![Docker CE/EE release cycle](images/docker-ce-ee-lifecycle.png)

---

## Qu'est-ce qui a été ajouté quand?

||||
| ---- | ----- | --- |
| 2015 |  1.9  | Réseaux superposés (multi-hôte), plugins réseau/IPAM
| 2016 |  1.10 | DNS dynamique embarqué
| 2016 |  1.11 | Répartition de charge DNS simple (_round robin_)
| 2016 |  1.12 | Mode Swarm, maillage de routage, réseaux chiffrés, _healthchecks_
| 2017 |  1.13 | _Stacks_, réseaux attachables, aplatissement d'image et compression
| 2017 |  1.13 | Swarm mode pour Windows Server 2016
| 2017 | 17.03 | Secrets, Raft chiffré
| 2017 | 17.04 | Retour arrière (_rollback_), préférences de placement ( non coercitives)
| 2017 | 17.06 | Configs swarm, _events_ avancés, _build_ multi-étapes, logs de services
| 2017 | 17.06 | Réseaux superposés Swarm, secrets pour Windows Server 2016
| 2017 | 17.09 | chown pour ADD/COPY, _start\_period_, signal de stop, overlay2 par défaut
| 2017 | 17.12 | containerd, isolation Hyper-V, maillage de routage pour Windows
| 2018 | 18.03 | Modèles pour secrets/configs, _stacks_ à multiple yamls, LCOW
| 2018 | 18.03 | Support stack natif pour K8S, `docker trust`, tmpfs, CLI pour _manifest_
