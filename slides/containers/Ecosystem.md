# L'écosystème de conteneurs

Dans ce chapitre, nous aborderons quelques acteurs de l'écosystème de conteneurs.

Nous avons (par opinion) décidé de nous concentrer sur deux groupes:

 - l'écosystème Docker,

 - la CNCF (Cloud Native Computing Foundation) et ses projets.

---

class: pic

## L'écosystème Docker

![The Docker ecosystem in 2015](images/docker-ecosystem-2015.png)

---

## Moby vs. Docker

- Docker Inc. (l'entreprise) a lancé Docker (le projet open-source).

- A un certain point, il est apparu nécessaire de différencier entre:

  - le projet open source (base de code, contributeurs, etc.),

  - le produit utilisé pour lancer les conteneurs (le moteur),

  - la plate-forme qui exploite les applications conteneurisées,

  - la marque.

---

class: pic

![Picture of a Tesla](images/tesla.jpg)

---

## Exercice de gestion de marque

Questions:

--

- Quelle est la marque de la voiture sur la diapo précédente?

--

- Quel type de moteur embarque-t-elle?

--

- Diriez-vous que c'est une voiture sûre ou pas?

--

- Plus dur: peut-on la conduire aux États-Unis de la côte Ouest à la côte Est?

--

Les réponses à ces questions font partie de la marque Tesla.

---

## Et si ...

- Les plans des voitures Tesla étaient disponibles gratuitement.

- Vous pouviez légalement construire votre propre Tesla.

- Vous étiez autorisé à la personnaliser complètement.

  (Placer un moteur à combustion, la conduire avec une manette de jeu ...)

- Vous pourriez même en vendre des versions spéciales.

--

- ... Et l'appeler votre version personnalisée de la "Tesla".

--

Est-ce qu'on donnerait les mêmes réponses aux questions sur la diapo précédente?

---

## De Docker à Moby

- Docker Inc. a décidé de scinder la marque.

- Moby est le projet open source

  (= des composants et bibliothèques à utiliser, recycler, personnaliser, vendre ...)

- Docker est fabriqué avec Moby.

- Quand Docker Inc. améliore les produits Docker, il améliore Moby.

  (Et vice-versa)


---

## Autres exemples

- *Read the Docs* est un projet open source pour générer et héberger des documentations.

- Vous pouvez l'héberger vous-même (sur vos propres serveurs).

- Vous pouvez aussi le faire héberger sur readthedocs.org.

- Les mainteneurs du projet open source reçoivent souvent
  des demandes de support de la part des usagers du produit hébergé...

- ... et les mainteneurs du produit hébergé reçoivent souvent
  des demandes de support des usagers d'instances auto-hébergés.

- Un autre exemple:

  *Wordpress.com est une plate-forme de blog, possédée et opérée par Automattic.
  Elle est basée sur le projet open-source Wordpress, un logiciel utilisé par les
  blogueurs (Wikipedia)*

---

## Docker CE vs Docker EE

- Docker CE = Community Edition.

- Disponible sur la plupart des distros Linux, Mac, Windows.

- Optimisé pour les développeurs et facile d'utilisation.

- Docker EE = Entreprise Edition.

- Disponible juste dans certaines distros Linux et les serveurs Windows.

  (Uniquement possible quand il existe un fort partenariat pour offrir un support d'entreprise.)

- Optimisé pour un usage en production.

- Contient des composants additionnels: scan de sécurité, RBAC ...

---

## La CNCF

- À but non-lucratif, membre de la Linux Foundation; créée en Décembre 2015.

  *La Cloud Native Computing Foundation construit des écosystèmes durables et promeut
  une communauté autour d'une constellation de projets de haute qualité qui orchestre
  les conteneurs dans une optique d'architecture pour microservices.*

  *CNCF est une fondation pour les logiciels open-source dédiée à rendre les infrastructures pour le cloud universelles et durables.*

- Là où est né Kubernetes (et bien d'autres projets depuis).

- Financé par les cotisations des entreprises privées adhérentes.

---

class: pic

![Cloud Native Landscape](https://landscape.cncf.io/images/landscape.png)

