# Modèle du moindre privilège

- Toute la donnée importante est stockée dans le "journal Raft"

- Les noeuds des _managers_ y ont accès en lecture/écriture

- les noeuds type _workers_ n'ont aucun accès à cette donnée

- Les _workers_ ne font que recevoir le strict nécessaire pour savoir:

  - quels services exécuter
  - quelle configuration réseau installer pour ces services
  - quels secrets fournir à ces services

- Faire tomber un noeud _worker_ ne donne pas accès au cluster en entier
---

## Que puis-je faire si j'arrive à contrôler un _worker_?

- Je peux m'introduire dans les conteneurs lancés sur ce noeud

- Je peux accéder à la configuration et aux secrets utilisés par ces conteneurs

- Je peux inspecter le trafic réseau entre ces conteneurs

- Je ne peux pas inspecter ou interrompre le trafic réseau des autres conteneurs

  (la config réseau est fournie par les _managers_; le _spoofing_ d'ARP est impossible)

- Je ne peux pas déduire la topologie du cluster et sa taille

- Je peux uniquement collecter les adresses IP des managers.

---

## Directives pour l'isolation de processus

- Définir des niveaux de sécurité

- Définir des zones de sécurité

- Placer les _managers_ dans la plus haute zone de sécurité

- S'assurer que les applicatifs d'un certain niveau de sécurité ne tournent que sur une certaine zone

- Forcer ce comportement peut se faire via un [plugin d'autorisation](https://docs.docker.com/engine/extend/plugins_authorization/)

---

## Aller plus loin dans la sécurité de conteneur


.blackbelt[DC17US: Securing Containers, One Patch At A Time
([video](https://www.youtube.com/watch?v=jZSs1RHwcqo&list=PLkA60AVN3hh-biQ6SCtBJ-WVTyBmmYho8&index=4))]

.blackbelt[DC17EU: Container-relevant Upstream Kernel Developments
([video](https://dockercon.docker.com/watch/7JQBpvHJwjdW6FKXvMfCK1))]

.blackbelt[DC17EU: What Have Syscalls Done for you Lately?
([video](https://dockercon.docker.com/watch/4ZxNyWuwk9JHSxZxgBBi6J))]
