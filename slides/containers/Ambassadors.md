
class: title

# Ambassadeurs

![Two serious-looking persons shaking hands](images/title-ambassador.jpg)

---

## Le modèle Ambassadeur

On appelle "Ambassadeur" tout conteneur qui agit en "proxy" ou "déguisement" d'un autre service.

Il encapsule les détails de connexion pour ces services, et peut aider à:

* la découverte (où mon service est vraiment en train de tourner?)

* la migration (que faire si mon service doit être déplacé pendant son utilisation?)

* le basculement (comment savoir à quelle instance d'un service je dois me connecter?)

* la répartition de charge (comment partager mes requêtes à travers plusieurs instances d'un service?)

* l'authentification (que faire si mon service exige des accès, certificats ou autre?)

---

## Introduction aux ambassadeurs

Le modèle d'ambassadeur:

* tire avantage du système de nommage "par conteneur" de Docker,
et encapsule les connexions entre services.

* permet de gérer les services sans coder les informations de connexion en dur dans les applications.

Pour ce faire, au lieu de se connecter directement aux conteneurs, on intercale
des conteneurs ambassadeurs.

---

class: pic

![ambassador](images/ambassador-diagram.png)

---

## Intéragir avec les ambassadeurs

* Le conteneur web utilise le réseau classique Docker pour
se connecter à l'ambassadeur.

* Le conteneur de base de données échange aussi avec un ambassadeur.

* Pour les deux conteneurs, l'ambassadeur est totalement transparent.
  <br/>
  (Il n'y a aucune différence entre un traitement normal
  et un traitement via un ambassadeur.)

* Si le conteneur de BDD est déplacé (ou si un basculement arrive), sa nouvelle
localisation sera suivie par les conteneurs ambassadeurs, et le conteneur
application web sera encore capable de se connecter, sans reconfiguration.

---

## Ambassadeur pour simple service de localisation

Cas d'usage:

* mon code d'application se connecte à `redis` sur le port par défaut (6379),
* mon service Redis tourne sur une autre machine, sur un port non conventionnel (par ex. 12345)
* Je veux utiliser un ambassadeur pour permettre à mon application de se connecter sans modification.

Le conteneur ambassadeur devra:

* être placé au plus proche de mon appli,
* se nommer `redis` (ou lié en tant que `redis`),
* écouter sur le port 6379,
* transmettre les connexions au service Redis réel.

---

## Ambassadeur pour migration de service

Cas d'usage:

* mon application se connecte toujours à `redis`,
* mon service Redis tourne quelque part d'autre,
* mon service Redis est déplacé sur un autre hôte+port,
* la localisation du service Redis m'est fournie via par ex. les champs DNS SRV
* je veux utiliser un ambassadeur pour me connecter automatiquement au nouveau serveur, avec un minimum de coupure.

Le conteneur ambassadeur devra:

* ressembler au précédent conteneur,
* faire tourner une routine supplémentaire pour surveiller les champs DNS SRV,
* mettre à jour la destination cible quand les champs DNS SRV changent.

---

## Ambassadeurs pour injection d'accès

Cas d'usage:

* mon code d'application se connecte toujours à `redis`,
* mon code d'application ne fournit pas d'identifiants Redis,
* mon service Redis en production requiert des identifiants,
* mon service Redis de _staging_ requiert des identifiants différents,
* je veux utiliser un ambassadeur pour extraire la logique de gestion des identifiants

Le conteneur ambassadeur devra:

* utiliser le nom `redis` (ou un alias),
* transmettre les identifiants à utiliser,
* lancer un proxy spécifique qui accepte les connexions sur le port Redis par défaut,
* opérer l'authentification avec le service Redis de cible avant de transmettre le trafic.

---

## Ambassadeurs de répartition de charge

Cas d'usage:

* mon code d'application se connecte à un service web nommé `api`,
* je veux lancer plusieurs instances de ma couche `api`,
* ces instances tournent sur des hôtes et ports différents,
* je veux utiliser un ambassadeur pour cacher ces détails à mon code.

Le conteneur ambassadeur devra:

* utiliser le nom `api` (ou un alias),
* passer la liste des instances `api` à utiliser (de façon statique ou dynamique)
* faire tourner un répartiteur de charge (par ex. HAProxy ou NGiNX),
* partager les requêtes entre les instances `api` de façon transparente.

---

## "Ambassadeur" est un *modèle de conception*

Il existe de nombreuses implémentations possibles.

Différents déploiements utiliseront différents technologies sous-jacentes.

* Des déploiements dans vos locaux au sein d'un réseau de confiance peuvent
suivre la localisation des conteneurs dans par ex. Zookeeper, et générer
les configurations HAproxy à chaque fois qu'une clé de localisation change.
* On pourra ajouter un chiffrement TLS aux déploiements dans un cloud public
ou à travers des réseaux risqués.
* Des déploiements spéciaux peuvent utiliser un protocole de découverte
sans maître tel avahi pour inscrire et découvrir des services.
* Il est aussi possible de procéder à une reconfiguration ponctuelle des
ambassadeurs. C'est relativement moins dynamique mais cela demande
beaucoup moins de pré-requis.
* On peut utiliser les ambassadeurs en plus ou à la place des réseaux superposés.

---

## Service de maillage

* Un _service mesh_ est une couche réseau configurable.

* Cette couche fournit le service de découverte, la haute disponibilité, la répartition de charge, l'observabilité...

* Les _service meshes_ sont particulièrement utiles pour les applications en microservices.

* Les _service meshes_ sont souvent installés en position de proxy.

* Les applications se connectent au service de maillage, qui va relayer la requête vers sa cible.

*Ça vous dit quelque chose?*

---

## Ambassadeurs et service meshes

* En utilisant un _service mesh_, un "conteneur side-car" est souvent utilisé comme proxy

* Nos services s'y connectent en transparence à ce conteneur side-car

* Ce conteneur side-car détermine où transmettre le trafic réseau

... Ça vous dit quelque chose?

(Ça devrait, parce que les services de maillage sont par nature des ambassadeurs au niveau d'un cluster ou d'une appli)

---

## Ambassadeur et maillage de service

* En utilisant un _service mesh_, on passe souvent par un conteneur "sidecar" qui agit comme proxy

* Nos services se connectent alors en transparence à ce conteneur "sidecar"

* Ce conteneur _sidecar_ détermine où transmettre le trafic 

... Ça vous rappelle quelque chose?

(Cela devrait, car les _service mesh_ sont techniquement des ambassadeurs à l'échelle d'un cluster)

---

## Quelques _service mesh_ populaires

... et des projets du domaine:

* [Consul Connect](https://www.consul.io/docs/connect/index.html)
  <br/>
  Sécurisation transparente des connexions service-à-service par mTLS.

* [Gloo](https://gloo.solo.io/)
  <br/>
  Passerelle d'API pour interconnecter les applications tournant sur des VMs ou des conteneurs ou en _serverless_.

* [Istio](https://istio.io/)
  <br/>
  Un _service mesh_ populaire

* [Linkerd](https://linkerd.io/)
  <br/>
  Un autre _service mesh_ populaire

---


## En savoir plus sur les _service mesh_

Quelques billets de blog à propos des _service mesh_:

* [Containers, microservices, and service meshes](http://jpetazzo.github.io/2019/05/17/containers-microservices-service-meshes/)
  <br/>
  Fournit du context historique: comment on faisait avant que les _service mesh_ soient inventés?

* [Do I Need a Service Mesh?](https://www.nginx.com/blog/do-i-need-a-service-mesh/)
  <br/>
  Explique le but des _service mesh_. Prend en exemple quelques fonctions de NGiNX.

* [Do you need a service mesh?](https://www.oreilly.com/ideas/do-you-need-a-service-mesh)
  <br/>
  Inclut une vue d'ensemble  et des définitions.

* [What is Service Mesh and Why Do We Need It?](https://containerjournal.com/2018/12/12/what-is-service-mesh-and-why-do-we-need-it/)
  <br/>
  Comprend une démo étape-par-étape de Linkerd.

Et une vidéo:

* [What is a Service Mesh, and Do I Need One When Developing Microservices?](https://www.datawire.io/envoyproxy/service-mesh/)

---

## Résumé de section

Nous avons appris comment:

* comprendre le motif de conception d'ambassadeur et comment l'utiliser (portabilité de service).

Pour plus d'information sur le _pattern_ ambassadeur, incluant des demos sur Swarm et ECS:

* [SwarmWeek video about Swarm+Compose](https://youtube.com/watch?v=qbIvUvwa6As)

