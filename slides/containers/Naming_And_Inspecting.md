
class: title

# Nommage et examen de conteneurs

![Markings on container door](images/title-naming-and-inspecting-containers.jpg)

---

## Objectifs

Dans cette leçon, nous apprendrons un important
concept de Docker: *nommer* les conteneurs.

Le nommage nous permet de:

* manipuler facilement un conteneur;

* assurer l'unicité d'un conteneur spécifique.

Nous verrons aussi la commande `inspect`, qui donne un tas de détails sur un conteneur.

---

## Nommer nos conteneurs

Jusque là, nous avons fait référence à nos conteneurs via leur ID.

Nous avons copié/collé leur ID, ou utilisé leur préfixe court.

Mais chaque conteneur peut aussi être manipulé par son nom.

Si un conteneur est nommé `thumbnail-worker`, je peux lancer:

```bash
$ docker logs thumbnail-worker
$ docker stop thumbnail-worker
etc.
```

---

## Nommage par défaut

Quand on crée un conteneur, si on ne donne pas un nom explicite,
Docker va en choisir un pour nous.

Ce sera un nom composé de deux mots tirés au sort:

* Une humeur (furieux, joueur, suspicieux, ennuyant...)

* Le nom d'un inventeur célèbre (tesla, darwin, wozniak...)

Exemples: `happy_curie`, `clever_hopper`, `jovial_lovelace` ...

---

## Spécifier un nom

Vous pouvez forcer le nom d'un conteneur à sa création.

```bash
$ docker run --name ticktock jpetazzo/clock
```

Si vous spécifiez un nom qui existe déjà, Docker refusera
de créer un conteneur.

Cela nous permet d'assurer l'unicité d'une certaine ressource.

---

## Renommer les conteneurs

* Vous pouvez renommer des conteneurs avec `docker rename`.

* Cela permet de "libérer" un nom sans détruire le conteneur associé.

---

## Inspecter un conteneur

La commande `docker inspect` va afficher un tableau JSON très détaillé.

```bash
$ docker inspect <containerID>
[{
...
(nombreuses pages de JSON ici)
...
```

Il y a plusieurs façons d'exploiter ces informations.

---

## Parser le JSON via le _shell_

* On *pourrait* filtrer la sortie de `docker inspect` avec grep, cut ou awk.

* N'en faites rien, s'il-vous-plaît.

* C'est douloureux.

* Si vous devez vraiment parser du JSON via le _shell_, prenez JQ! (c'est super)

```bash
$ docker inspect <containerID> | jq .
```

* On verra une meilleure solution qui ne demande aucun outil supplémentaire.

---

## Usage de `--format`

On peut spécifier un chaîne de format, qui sera interprétée par
la librairie Go _text/template_.

```bash
$ docker inspect --format '{{ json .Created }}' <containerID>
"2015-02-24T07:21:11.712240394Z"
```

* La syntaxe générique est d'entourer l'expression avec des doubles accolades.

* L'expression doit débuter par un point, représentant l'objet JSON.

* Puis chaque champ ou propriété peut être référencé via la notation par point.

* Le mot-clé optionnel `json` force une réponse au format JSON valide.
  <br/>(par ex. dans notre cas, il est entouré d'apostrophes doubles)