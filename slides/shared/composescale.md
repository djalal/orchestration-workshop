## Relancer en arrière-plan

- Bien des options et des commandes dans Compose sont inspirées par celle de `docker`

.exercise[

- Démarrer l'appli en arrière-plan avec l'option `-d`:
  ```bash
  docker-compose up -d
  ```

- Vérifier que notre appli est lancée avec la commande `ps`:
  ```bash
  docker-compose ps
  ```

]

`docker-compose ps` montre aussi les ports exposés par l'application.

---

class: extra-details

## Afficher les logs

- La commande `docker-compose logs` marche comme `docker logs`


.exercise[

- Afficher tous les logs depuis la naissance du conteneur, et sortir juste après:
  ```bash
  docker-compose logs
  ```

- Suivre le flux de logs du conteneur, en commençant par les 10 dernières lignes de chaque conteneur:
  ```bash
  docker-compose logs --tail 10 --follow
  ```

<!--
```wait units of work done```
```keys ^C```
-->

]

Astuce: taper `^S` et `^Q` pour suspendre/reprendre l'affichage des logs.

---

## Montée en charge de l'application

- Notre but est de faire monter ce graphique de performance (sans changer une ligne de code!)

--

- Avant d'essayer de faire monter en charge l'application, voyons si plus de ressources sont nécessaires

  (CPU, RAM ...)

- Pour ça, nous allons lancer de bons vieux outils UNIX sur notre noeud Docker.

---

## Examiner l'usage de ressources

- Jetons un oeil au CPU, à la mémoire et aux E/S

.exercise[

- lancer `top` pour voir l'usage CPU et mémoire (on devrait voir des cycles de repos)

<!--
```bash top```

```wait Tasks```
```keys ^C```
-->

- lancer `vmstat 1` pour voir l'usage des entrées/sorties (si/so/bi/bo)
  <br/>(les 4 nombres devraient être quasiment à zéro, excepté `bo` pour le logging)

<!--
```bash vmstat 1```

```wait memory```
```keys ^C```
-->

]

Nous avons des ressources disponibles.

- Pourquoi?
- Comment les exploiter?

---

## Escalader les workers sur un seul noeud

- Docker Compose supporte la mise à l'échelle
- Escaladons `worker` et voyons ce qu'il se passe!

.exercise[

- Démarrer un conteneur `worker` supplémentaire:
  ```bash
  docker-compose up -d --scale worker=2
  ```

- Examiner le graphique de performance (on devrait voir un doublement)

- Examiner les logs agrégés de nos conteneurs (`worker_2` devrait y apparaître)

- Examiner l'impact sur la charge de CPU avec par ex. top (il devrait être négligable)

]

---

## Cumuler les workers

- Super, ajoutons encore plus de workers alors, et le tour est joué!

.exercise[

- Démarrer huit conteneurs de `worker` de plus:
  ```bash
  docker-compose up -d --scale worker=10
  ```

- Examiner le graphique de performance: est-ce que l'amélioration est x10?

- Examiner les logs agrégés de nos conteneurs

- Examiner l'impact sur la charge CPU et la mémoire

]

---

# Identifier les goulots d'étranglement

- Vous devriez constater un facteur de vitesse x3 (pas x10)

- Ajouter des workers ne s'est pas traduit pas un gain linéaire.

- *Quelque chose* d'autre nous ralentit donc.

--

- ... Mais quoi?

--

- Le code ne dispose d'aucun appareillage de mesure.

- Sortons donc notre analyseur de performance HTTP dernier cri!
  <br/>(i.e les bons vieux outils comme `ab`, `httping`, etc.)

---

## Accéder aux services internes

- `rng` et `hasher` sont exposés sur les ports 8001 et 8002

- C'est déclaré ainsi dans le fichier Compose:

  ```yaml
    ...
    rng:
      build: rng
      ports:
      - "8001:80"

    hasher:
      build: hasher
      ports:
      - "8002:80"
    ...
  ```

---

## Mesurer la latence sous contrainte

Nous utiliserons pour cela `httping`.

.exercise[

- Vérifier la latence de `rng`:
  ```bash
  httping -c 3 localhost:8001
  ```

- Vérifier la latence de `hasher`:
  ```bash
  httping -c 3 localhost:8002
  ```

]

`rng` révèle une latence bien plus grande que `hasher`.

---

## Hasardons-nous à des conclusions hâtives

- Le goulot d'étranglement semble être `rng`.

- Et si *à tout hasard*, nous n'avions pas assez d'entropie, et qu'on ne pouvait générer assez de nombres aléatoires?

- On doit escalader le service `rng` sur plusieurs machines!

Note: ceci est une fiction! Nous avons assez d'entropie. Mais on a besoin d'un prétexte pour monter en charge.

(En réalité, le code de `rng` exploite `/dev/urandom`, qui n'est jamais à court d'entropie...)
<br/>
...et c'est [tout aussi bon que `/dev/random`](https://www.slideshare.net/PacSecJP/filippo-plain-simple-reality-of-entropy).)
