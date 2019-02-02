# Histoire des conteneurs ... et de Docker

---

## Premières expérimentations

* [IBM VM/370 (1972)](https://en.wikipedia.org/wiki/VM_%28operating_system%29)

* [Linux VServers (2001)](http://www.solucorp.qc.ca/changes.hc?projet=vserver)

* [Solaris Containers (2004)](https://en.wikipedia.org/wiki/Solaris_Containers)

* [FreeBSD jails (1999-2000)](https://www.freebsd.org/cgi/man.cgi?query=jail&sektion=8&manpath=FreeBSD+4.0-RELEASE)

Cela fait *très longtemps* que les conteneurs existent.

(Voir [cet excellent billet par Serge Hallyn](https://s3hh.wordpress.com/2018/03/22/history-of-containers/) pour plus de détails historiques.)

---

class: pic

## L'Âge du VPS (jusqu'à 2007-2008)

![lightcont](images/containers-as-lightweight-vms.png)

---

## Conteneurs = moins cher que les VMs

* Utilisateurs: fournisseurs d'hébergement.

* Audience hautement spécialisée avec une forte culture d'admin. système.

---

class: pic

## Période PAAS (2008-2018)


![heroku 2007](images/heroku-first-homepage.png)

---

## Conteneurs = plus facile que les VMs

* Je ne peux pas parler pour Heroku, mais les conteneurs étaient l'arme secrète de dotCloud (parmi d'autres).

* dotCloud maintenait un PaaS, via un moteur de conteneur personnalisé.

* Ce moteur était basé sur OpenVZ (et plus tard, LXC) et AUFS.

* Tout a commencé (vers 2008) par un simple script Python.

* En 2012, le moteur comptait plusieurs composants Python (env. 10)
  <br/>(et env. 100 micro-services!)

* Fin 2012, dotCloud reconstruit le moteur de conteneur.

* Le nom de code de ce projet est "Docker".

---

## Première version publique de Docker

* Mars 2013, Pycon, Santa Clara:
  <br/>"Docker" est montré en public pour la première fois.

* Il est publié avec une licence open source.

* Réactions et retours très positifs!

* L'équipe dotCloud est progressivement réaffectée au développement de Docker.

* La même année, dotCloud change de nom pour s'appeler Docker.

* En 2014, l'activité PaaS est revendue.

---

## Docker premiers jours (2013-2014)


---

## Premiers utilisateurs de Docker

* Gestionnaires de PAAS (Flynn, Dokku, Tsuru, Deis...)

* Utilisateurs de PAAS (ceux assez gros pour justifier la construction de leur propre PAAS)

* Services d'intégration continue

* développeurs, développeurs, développeurs

---

## Boucle de retours positifs

* En 2013, la technologie sous-tenant les conteneurs (cgroups, namespaces, stockage copy-on-write, etc.)

* La popularité croissante de Docker et des conteneurs a mis en lumière de nombreux bugs.

* En conséquence, ces bugs sont corrigés, résultant dans une meilleure stabilité des conteneurs.

* Aujourd'hui, tout fournisseur d'hébergement/cloud un peu sérieux peut lancer des conteneurs.

* Les conteneurs sont devenus un super outil pour déployer/transporter des applis vers/depuis les environnements on-prem/cloud.

---

## Maturité (2015-2016)

---

## Docker devient un standard d'industrie

* Docker atteint le jalon symbolique du 1.0

* Docker est maintenant supporté par les systèmes existants comme Mesos ou Cloud Foundry.

* Standardisation autour de l'OCI (Open Containers Initiative).

* De nouveaux moteurs de conteneurs sont développés.

* Création de la CNCF (Cloud Native Computing Foundation).

---

## Docker devient une plate-forme

* Le moteur de conteneur initial est maintenant nommé "Docker Engine".

* D'autres outils y sont ajoutés:
  * Docker Compose (anciennement "Fig")
  * Docker Machine
  * Docker Swarm
  * Kitematic
  * Docker Cloud (anciennement "Tutum")
  * Docker Datacenter
  * etc.

* Docker Inc. lance ses offres commerciales.
