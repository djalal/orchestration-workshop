# Labels

* Les labels servent à attacher des méta-données arbitraires aux conteneurs.

* Les labels sont des paires de clé/valeur.

* Ils sont spécifiés à la création du conteneur.

* On les consulte via `docker inspect`

* Ils peuvent aussi servir de filtres à certaines commandes (par ex. `docker ps`).

---

## Usage des labels

Lançons quelques conteneurs avec un label `owner`.

```bash
docker run -d -l owner=alice nginx
docker run -d -l owner=bob nginx
docker run -d -l owner nginx
```

Nous n'avons pas spécifié de valeur pour le label `owner` de notre dernier exemple.

Cela équivaut à spécifier une chaîne vide comme valeur du label.

---

## Consultation des labels

On peut lister les labels avec `docker inspect`.

```bash
$ docker inspect $(docker ps -lq) | grep -A3 Labels
            "Labels": {
                "maintainer": "NGINX Docker Maintainers <docker-maint@nginx.com>",
                "owner": ""
            },
```

On peut utiliser l'option `--format` pour lister les valeurs d'un label.

```bash
$ docker inspect $(docker ps -q) --format 'OWNER={{.Config.Labels.owner}}'
```

---

## Usage des labels et sélection de conteneurs

On peut lister les conteneurs qui ont un label spécifique.

```bash
$ docker ps --filter label=owner
```

Ou bien lister les conteneurs avec une valeur spécifique d'un label spécifique.

```bash
$ docker ps --filter label=owner=alice
```

---

## Cas d'usage des labels


* vhost HTTP pour une web app ou un service web.

  (Le label est utilisé pour générer la configuration pour NGINX, HAProxy, etc.)

* Planification de sauvegarde pour un service avec données persistantes.

  (Le label est utilisé par un _cronjob_ pour déterminer si/quand sauvegarder les données du conteneur.)

* Propriétaire d'un service

  (Pour calculer une facturation interne, ou qui alerter en cas de panne.)

* etc.
