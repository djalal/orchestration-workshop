
# Notre application de démo

- Nous allons cloner le dépôt Github sur notre `node1`

- Le dépôt contient aussi les scripts et outils à utiliser à travers la formation.

.exercise[

<!--
```bash
cd ~
if [ -d container.training ]; then
  mv container.training container.training.$RANDOM
fi
```
-->

- Cloner le dépôt sur `node1`:
  ```bash
  git clone https://@@GITREPO@@
  ```

]

(Vous pouvez aussi _forker_ le dépôt sur Github et cloner votre version si vous préférez.)


---

## Télécharger et lancer l'application


Démarrons-la avant de s'y plonger, puisque le téléchargement peut prendre un peu de temps...

.exercise[

- Aller dans le dossier `dockercoins` du dépôt cloné:
  ```bash
  cd ~/container.training/dockercoins
  ```

- Utiliser Compose pour générer et lancer tous les conteneurs:
  ```bash
  docker-compose up
  ```

<!--
```longwait units of work done```
-->

]

Compose indique à Docker de construire toutes les images de
conteneurs (en téléchargeant les images de base correspondantes),
puis de démarrer tous les conteneurs et d'afficher les logs
agrégés.

---

## Qu'est-ce que cette application?

--

- C'est un miner de DockerCoin! .emoji[💰🐳📦🚢]

--

- Non, on ne paiera pas le café avec des DockerCoins

--

- Comment DockerCoins fonctionne

  - générer quelques octets aléatoires

  - calculer une somme de hachage

  - incrémenter un compteur (pour suivre la vitesse)

  - répéter en boucle!

--

- DockerCoins n'est *pas* une crypto-monnaie

  (les seuls points communs étant "aléatoire", "hachage", et "coins" dans le nom) </lol>

---

## DockerCoins à l'âge des microservices

- DockerCoins est composée de 5 services:

  - `rng` = un service web générant des octets au hasard

  - `hasher` = un service web calculant un hachage basé sur les données POST-ées

  - `worker` = un processus en arrière-plan utilisant `rng` et `hasher`

  - `webui` = une interface web pour le suivi du travail

  - `redis` = base de données (garde un décompte, mis à jour par `worker`)

- Ces 5 services sont visibles dans le fichier Compose de l'application,
  [docker-compose.yml](
  https://@@GITREPO@@/blob/master/dockercoins/docker-compose.yml)

---

## Comment fonctionne DockerCoins

- `worker` invoque le service web `rng` pour générer quelques octets aléatoires

- `worker` invoque le service web `hasher` pour générer un hachage de ces octets

- `worker` reboucle de manière infinie sur ces 2 tâches

- chaque seconde, `worker` écrit dans `redis` pour indiquer combien de boucles ont été réalisées

- `webui` interroge `redis`, pour calculer et exposer la "vitesse de hachage" dans notre navigateur

*(Voir le diagramme en diapo suivante!)*

---

class: pic

![Diagramme montrant les 5 conteneurs de notre application](images/dockercoins-diagram.svg)

---

## _Service discovery_ au pays des conteneurs

- Comment chaque service trouve l'adresse des autres?

--

- On ne code pas en dur des adresses IP dans le code.

- On ne code pas en dur des FQDN dans le code, non plus.

- On se connecte simplement avec un nom de service, et la magie du conteneur fait le reste

  (Par magie du conteneur, nous entendons "l'astucieux DNS embarqué dynamique")

---

## Exemple dans `worker/worker.py`

```python
redis = Redis("`redis`")


def get_random_bytes():
    r = requests.get("http://`rng`/32")
    return r.content


def hash_bytes(data):
    r = requests.post("http://`hasher`/",
                      data=data,
                      headers={"Content-Type": "application/octet-stream"})
```

(Code source complet disponible [ici](
https://@@GITREPO@@/blob/8279a3bce9398f7c1a53bdd95187c53eda4e6435/dockercoins/worker/worker.py#L17
))

---

class: extra-details

## Liens, nommage et découverte de service

- Les conteneurs peuvent avoir des alias de réseau (résolus par DNS)

- Compose dans sa version 2+ rend chaque conteneur disponible via son nom de service

- Compose en version 1 rendait obligatoire la section "links"

- Les alias de réseau sont automatiquement préfixé par un espace de nommage

  - vous pouvez avoir plusieurs applications déclarées via un service appelé `database`

  - les conteneurs dans l'appli bleue vont atteindre `database` via l'IP de la base de données bleue

  - les conteneurs dans l'appli verte vont atteindre `database` via l'IP de la base de données verte

---

## Montrez-moi le code!

- Vous pouvez ouvrir le dépôt Github avec tous les contenus de cet atelier:
  <br/>https://@@GITREPO@@

- Cette application est dans le sous-dossier [dockercoins](
  https://@@GITREPO@@/tree/master/dockercoins)

- Le fichier Compose ([docker-compose.yml](
  https://@@GITREPO@@/blob/master/dockercoins/docker-compose.yml))
  liste les 5 services

- `redis` utilise une image officielle issue du Docker Hub

- `hasher`, `rng`, `worker`, `webui` sont générés depuis un Dockerfile

- Chaque Dockerfile de service et son code source est stocké dans son propre dossier

  (`hasher` est dans le dossier [hasher](https://@@GITREPO@@/blob/master/dockercoins/hasher/),
  `rng` est dans le dossier [rng](https://@@GITREPO@@/blob/master/dockercoins/rng/), etc.)

---

class: extra-details

## Version du format de fichier Compose

*Uniquement pertinent si vous avez utilisé Compose avant 2016...*

- Compose 1.6 a introduit le support d'un nouveau format de fichier Compose (alias "v2")

- Les services ne sont plus au plus haut niveau, mais dans une section `services`.

- Il doit y avoir une clé `version` tout en haut du fichier, avec la valeur `"2"` (la chaîne de caractères, pas le chiffre)

- Les conteneurs sont placés dans un réseau dédié, rendant les _links_ inutiles

- Il existe d'autres différences mineures, mais la mise à jour est facile et assez directe.

---

## Notre application à l'oeuvre

- A votre gauche, la bande "arc-en-ciel" montrant les noms de conteneurs

- A votre droite, nous voyons la sortie standard de nos conteneurs

- On peut voir le service `worker` exécutant des requêtes vers `rng` et `hasher`

- Pour `rng` et `hasher`, on peut lire leur logs d'accès HTTP

---

## Se connecter à l'interface web

- "Les logs, c'est excitant et drôle" (Citation de personne, jamais, vraiment)

- Le conteneur `webui` expose un écran de contrôle web; allons-y voir.

.exercise[

- Avec un navigateur, se connecter à `node1` sur le port 8000

- Rappel: les alias `nodeX` ne sont valides que sur les noeuds eux-mêmes.

- Dans votre navigateur, vous aurez besoin de taper l'adresse IP de votre noeud.

<!-- ```open http://node1:8000``` -->

]

Un diagramme devrait s'afficher, et après quelques secondes, une courbe en bleu
va apparaître.

---

class: self-paced, extra-details

## Si le graphique ne se charge pas

Si tout ce que vous voyez est une erreur `Page not found`, cela peut être à cause
de votre Docker Engine qui tourne sur une machine différente. Cela peut être le cas si:

- vous utilisez Docker Toolbox

- vous utilisez une VM (locale ou distante) créée avec Docker Machine

- vous contrôlez un Docker Engine distant

Quand vous lancez DockerCoins en mode développement, les fichiers statiques
de l'interface web sont appliqués au conteneur via un volume. Hélas, les
volumes ne fonctionnent que sur un environnement local, ou quand vous passez
par Docker for Desktop.

Comment corriger cela?

Arrêtez l'appli avec `^C`, modifiez `dockercoins.yml`, commentez la section `volumes`, et relancez le tout.

---

class: extra-details

## Pourquoi le rythme semble irrégulier?

- On *dirait peu ou prou* que la vitesse est de 4 hachages/seconde.

- Ou plus précisément: 4 hachages/secondes avec des trous reguliers à zéro

- Pourquoi?

--

class: extra-details

- L'appli a en réalité une vitesse constante et régulière de 3.33 hachages/seconde.
  <br/>
  (ce qui correspond à 1 hachage toutes les 0.3 secondes, pour *certaines raisons*)

- Oui, et donc?

---

class: extra-details

## La raison qui fait que ce graphe n'est *pas super*

- Le worker ne met pas à jour le compteur après chaque boucle, mais au maximum une fois par seconde.

- La vitesse est calculée par le navigateur, qui vérifie le compte à peu près une fois par seconde.

- Entre 2 mise à jours consécutives, le compteur augmentera soit de 4, ou de 0 (zéro).

- La vitesse perçue sera donc 4 - 4 - 0 - 4 - 4 - 0, etc.

- Que peut-on conclure de tout cela?

--

class: extra-details

- "Je suis carrément incapable d'écrire du bon code frontend" 😀 — Jérôme

---

## Arrêter notre application

- Si nous stoppons Compose (avec `^C`), il demandera poliment au Docker Engine d'arrêter l'appli

- Le Docker Engine va envoyer un signal `TERM` aux conteneurs

- Si les conteneurs ne quittent pas assez vite, l'Engine envoie le signal `KILL`

.exercise[

- Arrêter l'application en tapant `^C`

<!--
```keys ^C```
-->

]

--

Certains conteneurs quittent immédiatement, d'autres prennent plus de temps.
Les conteneurs qui ne gèrent pas le `SIGTERM` finissent pas être tués après 10 secs. Si nous sommes vraiment impatients, on peut taper `^C` une seconde fois!
