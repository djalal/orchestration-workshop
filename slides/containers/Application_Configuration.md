# Configuration d'applications

Il y a de nombreuses façons de passer une configuration aux applications conteneurisées.

Il n'y a pas de "bonne manière", cela dépend de plusieurs facteurs, tels que:

* la taille de la configuration;

* les paramètres obligatoires et optionnels;

* la visibilité de la configuration (par conteneur, par app, par client, par site, etc.);

* la fréquence de changement de configuration.

---

## Paramètres en ligne de commande

```bash
docker run jpetazzo/hamba 80 www1:80 www2:80
```

* La configuration est fournie via des paramètres en ligne de commande.

* Dans l'exemple ci-dessus, `ENTRYPOINT` pointe sur un script qui va:
  - parser les paramètres,

  - générer un fichier de configuration,

  - démarrer le service réel.

---

## Pour et contre des paramètres en ligne de commande

* Convient pour les paramètres obligatoires (sans lesquels le service ne peut pas démarrer);

* Utile pour les services "boîte à outils" qui se lancent à de nombreuses reprises.

  (Parce qu'il n'y a pas d'autres étapes: juste à le lancer!)

* Pas terrible pour les configurations dynamiques ou plus conséquentes.

  (Toujours possible à réaliser, mais plus encombrant)

---

## Variables d'environnement

```bash
docker run -e ELASTICSEARCH_URL=http://es42:9201/ kibana
```

* Configuration fournie à travers des variables d'environnement.

* La variable d'environnement peut être utilisée directement par le programme,
<br/> ou par un script générant un fichier de configuration.

---

## Pour et contre des variables d'environnement

* Pertinent pour des paramètres optionnels (puisque l'image peut fournir des valeurs par défault)

* Aussi pratique pour des services se lançant de nombreuses fois.

  (C'est aussi simple que les paramètres en ligne de commande.)

* Super pour des services avec beaucoup de paramètres, mais vous voulez juste en changer quelques-uns.

  (Et garder les valeurs par défaut pour tout le reste.)

* Capacité à examiner les paramètres disponibles et leurs valeurs par défaut.

* Pas terrible pour les configurations dynamiques.

---

## Configuration incluse

```dockerfile
FROM prometheus
COPY prometheus.conf /etc
```

* La configuration est ajoutée à l'image.

* L'image peut avoir une configuration par défaut; la nouvelle config peut:
  - remplacer la configuration par défaut;
  - étendre celle-ci (si le code sait lire plusieurs fichiers de configuration)

---

## Pour et contre des configurations intégrées

* Permet une personnalisation avancée, et des fichiers de configuration complexes;

* Exige d'écrire un fichier de configuration (bien sûr!)

* Exige de générer une image pour démarrer le service

* Exige de générer une image pour reconfigurer le service

* Exige de générer une image pour mettre à jour le service

* Toute image pré-configurée peut-être stockée dans une Registry.

  (ce qui est super, mais nécessite une Registry)

---

## Configuration par volume

```bash
docker run -v appconfig:/etc/appconfig myapp
```

* La configuration est stockée dans un volume;

* Le volume est attaché au _container_;

* L'image peut avoir une configuration par défaut.

   (Mais cela demande un réglage non trivial, via plus de documentation.)

---

## Pour et contre des configurations par volume

* Permet une personnalisation avancée, et des fichiers de configuration complexes;

* Exige de déclarer un nouveau volume pour chaque différente configuration;

* Les services avec des configurations identiques peuvent ré-utiliser le même volume;

* Ne force pas à générer/regénérer une image lors des mises à jour ou reconfiguration;

* Une configuration peut être générée ou modifiée via un _container_ tiers.

---

## Configuration dynamique par volume

* C'est une technique puissante pour des configurations dynamiques et complexes;

* La configuration est stockée dans un volume;

* La configuration est générée/mise à jour depuis un _container_ spécial;

* L'application du _container_ détecte quand la configuration a changé;

  (et recharge automatiquement la configuration quand nécessaire.)

* La configuration peut être partagée entre service si besoin.

---

## Exemple de configuration dynamique par volume

Dans un premier terminal, démarrer un _load balancer_ avec une configuration initiale:

```bash
$ docker run --name loadbalancer jpetazzo/hamba \
  80 goo.gl:80
```

Dans un autre terminal, reconfigurer ce _load balancer_:

```bash
$ docker run --rm --volumes-from loadbalancer jpetazzo/hamba reconfigure \
  80 google.com:80
```

La configuration pourrait aussi mise à jour via une API REST.

(L'API REST tournant elle-même depuis un autre _container_.)

---

# Stockage des secrets

.warning[Idéalement, vous ne devriez pas transmettre de secrets (mot de passe, tokens, etc.) via:]

* la ligne de commande ou des variables d'environnement (quiconque avec un accès à l'API Docker peut les récupérer)

* des images, surtout celles stockées dans une Registry.

La gestion des secrets est mieux supportée avec un orchestrateur (type Swarm ou K8S).

Les orchestrateurs autorisent la transmission de secrets en "sens-unique".

Gérer les secrets de manière sécurisée sans orchestrateur peut se révéler "contrived" (TRAD).

Par ex.:

- lire le contenu du secret via _stdin_ quand le service démarre;

- passer le secret via un endpoint d'une API.
