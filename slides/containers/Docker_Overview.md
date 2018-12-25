# Docker vu d'hélicoptère

Dans cette leçon, nous apprendrons:

* Pourquoi les conteneurs (_pitch_ d'ascenseur non-technique)

* Pourquoi les conteneurs (version technique du _pitch_ d'ascenseur)

* Comment Docker nous aide à les construire, transporter et lancer

* L'Histoire des conteneurs

On ne va pas (encore!) lancer Docker ou des conteneurs dans ce chapitre.

Pas de souci, nous y arriverons assez tôt!

---

## _Pitch_ d'ascenseur

### (pour votre manager, votre patron...)

---

## OK... Pourquoi ce buzz autour des conteneurs?

* L'industrie logicielle a changé

* Avant:
  * applications monolitiques
  * longs cycles de développements
  * environnement unique
  * montée en charge lente

* Maintenant:
  * services découplés
  * améliorations rapides, itératives
  * environnements multiples
  * montée en charge rapide

---

## Deployment becomes very complex
## Déployer devient très compliqué

* Nombreuses technos différentes:
  * langages
  * frameworks
  * bases de données

* Nombreux environnements différents:
  * espaces de développement individuels
  * pre-production, QA, staging...
  * production: on-prem, cloud, hybride

---

class: pic

## Le problème du déploiement

![problem](images/shipping-software-problem.png)

---

class: pic

## La matrice infernale

![matrix](images/shipping-matrix-from-hell.png)

---

class: pic

## Parallèle avec l'industrie du transport

![history](images/shipping-industry-problem.png)

---

class: pic

## Conteneurs pour transport intermodal

![shipping](images/shipping-industry-solution.png)

---

class: pic

## Un nouvel écosystème de transport

![shipeco](images/shipping-indsutry-results.png)

---

class: pic

## Un système de transport par conteneur pour les applications

![shipapp](images/shipping-software-solution.png)

---

class: pic

## Fin de la matrice infernale

![elimatrix](images/shipping-matrix-solved.png)

---

## Résultats

* [Passage "Dev à Prod" réduit de 9 mois à 15 minutes (ING)](
  https://www.docker.com/sites/default/files/CS_ING_01.25.2015_1.pdf)

* [Durée des traitements d'intégration continue réduite de 60% (BBC)](
  https://www.docker.com/sites/default/files/CS_BBCNews_01.25.2015_1.pdf)

* [Déployer 100 fois par jour au lieu d'une fois par semaine (GILT)](
  https://www.docker.com/sites/default/files/CS_Gilt%20Groupe_03.18.2015_0.pdf)

* [70% de consolidation d'infrastructure (MetLife)](
  https://www.docker.com/customers/metlife-transforms-customer-experience-legacy-and-microservices-mashup)

* [60% de consolidation d'infrastructure (Intesa Sanpaolo)](
  https://blog.docker.com/2017/11/intesa-sanpaolo-builds-resilient-foundation-banking-docker-enterprise-edition/)

* [Densité d'application 14x supérieure; 60% du datacenter legacy migré en 4 mois (GE Appliances)](
  https://www.docker.com/customers/ge-uses-docker-enable-self-service-their-developers)

* etc.

---

## _Pitch_ d'ascenseur

### (pour vos collègues développeurs et admin. système)

---

## Echapper à l'enfer des dépendances

1. Ecrire les instructions d'installation dans un fichier `INSTALL.txt`

2. Avec ce fichier, écrire un script `install.sh` qui va marcher *pour vous*

3. Traduire ce fichier en `Dockerfile`, le tester sur votre machine

4. Si le Dockerfile passe sur votre machine, il passera *n'importe où*

5. Réjouissez-vous, car vous êtes sauvé de l'enfer des dépendances et du "ça marche sur ma machine"

Plus jamais de "ça marchait en dev - c'est le problème des admins maintenant!"

---

## Intégrez des développeurs et contributeurs rapidement

1. Ecrire les Dockerfiles pour les composants applicatifs

2. Utiliser des images pré-générées du Docker Hub (mysql, redis, etc.)

3. Décrire votre suite logicielle avec un fichier Compose

4. Intégrer quelqu'un avec deux commandes:

```bash
git clone ...
docker-compose up
```

Avec ça, vous pouvez monter des environnements de développement, intégration ou QA en quelques minutes!

---

class: extra-details

## Implémenter facilement une CI stable

1. Montez un environnemen de test avec un Dockerfile ou un fichier Compose

2. Pour chaque lancement de test, montez un nouveau conteneur (ou une suite complète)

3. Chaque test est lancé dans un environnement propre.

4. Aucune pollution des précédents tests

Bien plus rapide et économique que de monter des VMs à chaque fois!

---

class: extra-details

## Use container images as build artefacts
## Utiliser des images de conteneurs comme artefacts de _build_

1. Générez votre appli à partir de Dockerfiles

2. Stockez les images résultantes dans un dépôt

3. Stockez les pour toujours (ou aussi longtemps que nécessaire)

4. Testez ces image en QA, CI ou intégration...

5. Lancez les mêmes images en production

6. Quelque chose est cassé? Repassez à l'image précédente.

7. Diagnostic d'une ancienne régression? Une ancienne image est toujours là pour vous!

Les images contiennent toutes les bibliothèques, dépendances, etc. nécessaire au lancement de l'appli.

---

class: extra-details

## Découplez la "plomberie" de la logique applicative

1. Ecrivez votre code pour qu'il se connecte à des services nommés ("db", "api", etc.)

2. Utilisez Compose pour démarrer votre suite

3. Docker va fournir un DNS pour conteneur pour résoudre ces noms de services

4. Vous pouvez maintenant monter en charge, ajouter des répartiteurs de charge, de la réplication... sans changer votre code.

Note: ce n'est pas couvert dans cet atelier d'introduction!

---

class: extra-details

## Qu'a apporté Docker à la table?

### Docker avant/après

---

class: extra-details

## Formats and APIs, before Docker
## Formats et APIs, avant Docker

* Aucun format d'échange standard.
  <br/>(Non, un fichier _tarball_ n'est pas un format!)

* Difficile d'utiliser des conteneurs pour les développeurs.
  <br/>(Quel est l'équivalent d'un `docker run debian`?)

* En conséquence, ils restent *cachés* des utilisateurs finaux.

* Aucun composant réutilisable, APIs ou outils.
  <br/>(Au mieux, abstractions de VMs, e.g libvirt)

Analogie:

* Transporter des conteneurs n'est pas une question de boîte d'acier.
* Ce sont des boîtes d'acier de taille standard, avec les mêmes crochets et trous.

---

class: extra-details

## Formats et APIs, après Docker

* Standardiser le format de conteneur, parce que les conteneurs n'étaient pas portables.

* Rendre les conteneurs facile à utiliser pour les développeurs.

* Focus sur les composants réutilisable, APIs et l'écosystème d'outils standard.

* Amélioration par rapport aux outils ad-hoc, interne et spécifique.

---

class: extra-details

## Livraison, avant Docker

* Déploiement par paquets: deb, rpm, gem, jar, homebrew...

* Enfer des dépendances

* "Ça marche chez moi."

* Base de livraison souvent réalisée de zéro (debootstrap...) et fragile.

---

class: extra-details

## Livraison, après Docker

* Livrez des images de conteneurs avec toutes leurs dépendances.

* De plus grosses images, mais sous-découpées en couches.

* Ne livre que les couches qui ont changé.

* Économise du disque, du réseau et de la mémoire.

---

class: extra-details

## Exemple

Couches (_Layers_):

* CentOS
* JRE
* Tomcat
* Dépendances
* Application JAR
* Configuration

---

class: extra-details

## Devs vs Ops, avant Docker

* On va livrer un fichier _tarball_ (ou un hash de commit) avec ses instructions.

* Avec un environnement de dev très différent de la production.

* Sauf que les admin. système n'ont pas toujours un environnement de test eux-mêmes...

* ... et quand ils l'ont, il peut différer de celui des devs.

* Donc les admin. système doivent déterminer les différences, et faire en sorte que ça marche...

* ... ou le renvoyer aux développeurs.

* Déployer du code est cause de friction et de délais.

---

class: extra-details

## Devs vs Ops, après Docker

* On va livrer une image de conteneur ou un fichier Compose.

* Un admin. système pourra toujours lancer cette image de conteneur.

* Un admin. système pourra toujours lancer ce fichier Compose.

* Les admin. doivent toujours adapter la configuration à l'environnement de prod,
mais ils ont au moins un point de référence.

* L'outillage des admin. système permet d'utiliser la même image en dev et prod.

* Les développeurs pourront plus facilement être mis en position de lancer les déploiements eux-mêmes.
