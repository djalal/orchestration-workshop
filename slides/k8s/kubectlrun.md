# Lancer nos premiers conteneurs sur Kubernetes

- Commençons par le commencement: on ne lance pas "un" conteneur

--

- On va lancer un _pod_, et dans ce _pod_, on fera tourner un seul conteneur

--

- Dans ce conteneur, qui est dans le _pod_, nous allons lancer une simple commande `ping`

- Puis nous allons démarrer plusieurs exemplaires du _pod_.

---

## Démarrer un simple pod avec `kubectl run`

- On doit spécifier au moins un *nom* et l'image qu'on veut utiliser.

.exercise[

- Lancer un ping sur `1.1.1.1`, le [serveur DNS public](https://blog.cloudflare.com/announcing-1111/) de Cloudflare:
  ```bash
  kubectl run pingpong --image alpine ping 1.1.1.1
  ```

<!-- ```hide kubectl wait deploy/pingpong --for condition=available``` -->

]

--

(A partir de Kubernetes 1.12, un message s'affiche nous indiquant que
`kubectl run` est déprécié. Laissons ça de côté pour l'instant.)

---

## Dans les coulisses de `kubectl run`

- Jetons un oeil aux ressources créées par `kubectl run`

.exercise[

- Lister tous types de ressources:
  ```bash
  kubectl get all
  ```

]

--

On devrait y voir quelque chose comme:
- `deployment.apps/pingpong` (le *deployment* que nous venons juste de déclarer)
- `replicaset.apps/pingpong-xxxxxxxxxx` (un *replica set* généré par ce déploiement)
- `pod/pingpong-xxxxxxxxxx-yyyyy` (un *pod* généré par le _replica set_)

Note: à partir de 1.10.1, les types de ressources sont affichés plus en détail.

---

## Que représentent ces différentes choses?

- Un _deployment_ est une structure de haut niveau

  - permet la montée en charge, les mises à jour, les retour-arrière

  - plusieurs déploiements peuvent être cumulés pour implémenter un
    [_canary deployment_](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)

  - délègue la gestion des _pods_ aux _replica sets_

- Un *replica set* est une structure de bas niveau

  - s'assure qu'un nombre de _pods_ identiques est lancé

  - permet la montée en chage

  - est rarement utilisé directement


- Un _replication controlller_ est l'ancêtre (déprécié) du _replica set_

---

## Notre déploiement `pingpong`

- `kubectl run` déclare un *deployment*, `deployment.apps/pingpong`

```
NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pingpong   1         1         1            1           10m
```

- Ce déploiement a généré un *replica set*, `replicaset.apps/pingpong-xxxxxxxxxx`

```
NAME                                  DESIRED   CURRENT   READY     AGE
replicaset.apps/pingpong-7c8bbcd9bc   1         1         1         10m
```

- Ce _replica set_ a créé un _pod_, `pod/pingpong-xxxxxxxxxx-yyyyy`

```
NAME                            READY     STATUS    RESTARTS   AGE
pod/pingpong-7c8bbcd9bc-6c9qz   1/1       Running   0          10m
```

- Nous verrons plus tard comment ces gars vivent ensemble pour:

  - la montée en charge, la haute disponibilité, les mises à jour en continu

---

## Afficher la sortie du conteneur

- Essayons la commande `kubectl logs`

- On lui passera soit un _nom de pod_ ou un _type/name_

  (Par ex., si on spécifie un déploiement ou un _replica set_, il nous sortira le premier _pod_ qu'il contient)

- Sauf instruction expresse, la commande n'affichera que les logs du premier conteneur du _pod_

  (Heureusement qu'il n'y en a qu'un chez nous!)

.exercise[

- Afficher le résultat de notre commande `ping`:
  ```bash
  kubectl logs deploy/pingpong
  ```

]

---

## Suivre les logs en temps réel

- Tout comme `docker logs`, `kubectl logs` supporte des options bien pratiques:

  - `-f`/`--follow` pour continuer à afficher les logs en temps réel (à la `tail -f`)

  - `--tail` pour indiquer combien de lignes on veut afficher (depuis la fin)

  - `--since` pour afficher les logs après un certain _timestamp_

.exercise[

- Voir les derniers logs de notre commande `ping`:
  ```bash
  kubectl logs deploy/pingpong --tail 1 --follow
  ```

<!--
```wait seq=3```
```keys ^C```
-->

]

---

## Escalader notre application

- On peut ajouter plusieurs exemplaires de notre conteneur (notre _pod_, pour être plus précis), avec la commande `kubectl scale`

.exercise[

- Escalader notre déploiement `pingpong`:
  ```bash
  kubectl scale deploy/pingpong --replicas 3
  ```

- Noter que cette autre commande fait exactement pareil:
  ```bash
  kubectl scale deployment pingpong --replicas 3
  ```

]

Note: et si on avait essayé d'escalader `replicaset.apps/pingpong-xxxxxxxxxx`?

On pourrait! Mais le *deployment* le remarquerait tout de suite, et le baisserait au niveau initial.

---

## Résilience

- Le *déploiement* `pingpong` affiche son _replica set_

- Le *replica set* s'assure que le bon nombre de _pods_ sont lancés

- Que se passe-t-il en cas de disparition inattendue de _pods_?

.exercise[

- Dans une fenêtre séparée, lister les _pods_ en continu:
  ```bash
  kubectl get pods -w
  ```

<!--
```wait Running```
```keys ^C```
```hide kubectl wait deploy pingpong --for condition=available```
```keys kubectl delete pod ping```
```copypaste pong-..........-.....```
-->

- Supprimer un _pod_
  ```
  kubectl delete pod pingpong-xxxxxxxxxx-yyyyy
  ```
]

---

## Et si on voulait que ça se passe différemment?

- Et si on voulait lancer un conteneur "one-shot" qui ne va *pas* se relancer?

- On pourrait utiliser `kubectl run --restart=OnFailure` or `kubectl run --restart=Never`

- Ces commandes iraient déclarer des *jobs* ou *pods* au lieu de *deployments*.

- Sous le capot, `kubectl run` invoque des _"generators"_ pour déclarer les descriptions de ressources.

- On pourrait aussi écrire ces descriptions de ressources nous-mêmes (typiquement en YAML),
  <br/>et les créer sur le cluster avec `kubectl apply -f` (comme on verra plus loin)

- Avec `kubectl run --schedule=...`, on peut aussi lancer des *cronjobs*

---

## Bon, et cet avertissement de déprécation?

- Comme nous avons vu dans les diapos précédentes, `kubectl run` peut faire bien des choses.

- Le type exact des ressources créées n'est pas flagrant.

- Pour rendre les choses plus explicites, on préfère passer par `kubectl create`:

  - `kubectl create deployment` pour créer un déploiement

  - `kubectl create job` pour créer un job

  - `kubectl create cronjob` pour lancer un _job_ à intervalle régulier
    <br/>(depuis Kubernetes 1.14)

- Finalement, `kubectl run` ne sera utilisé que pour démarrer des _pods_ à usage unique

  (voir https://github.com/kubernetes/kubernetes/pull/68132)

---

## Divers moyens de créer des ressources

- `kubectl run`

  - facile pour débuter
  - versatile

- `kubectl create <ressource>`

  - explicite, mais lui manque quelques fonctions
  - ne peut déclarer de CronJob avant Kubernetes 1.14
  - ne peut pas transmettre des arguments en ligne de commande aux déploiements

- `kubectl create -f foo.yaml` ou `kubectl apply -f foo.yaml`

  - 100% des fonctions disponibles
  - exige d'écrire du YAML

---

## Afficher les logs de multiple _pods_

- Quand on spécifie un nom de déploiement, les logs d'un seul _pod_ sont affichés

- On peut afficher les logs de plusieurs pods en ajoutant un *selector*

- Un sélecteur est une expression logique basée sur des *labels*

- Pour faciliter les choses, quand on lance `kubectl run monpetitnom`, les objets associés ont un label `run=monpetitnom`

.exercise[

- Afficher la dernière ligne de log pour tout _pod_ confondus qui a le label `run=pingpong`:
  ```bash
  kubectl logs -l run=pingpong --tail 1
  ```

]

---

### Suivre les logs de plusieurs pods

- Est-ce qu'on peut suivre les logs de tous nos _pods_ `pingpong`?

.exercise[

- Combiner les options `-l` and `-f`:
  ```bash
  kubectl logs -l run=pingpong --tail 1 -f
  ```

<!--
```wait seq=```
```keys ^C```
-->

]

*Note: combiner les options `-l` et `-f` est possible depuis Kubernetes 1.14!*

*Essayons de comprendre pourquoi ...*

---

class: extra-details

### Suivre les logs de plusieurs pods

- Voyons ce qu'il se passe si on essaie de sortir les logs de plus de 5 _pods_

.exercise[

- Escalader notre déploiement:
  ```bash
  kubectl scale deployment pingpong --replicas=8
  ```

- Afficher les logs en continu:
  ```bash
  kubectl logs -l run=pingpong --tail 1 -f
  ```

]

On devrait voir un message du type:
```
error: you are attempting to follow 8 log streams,
but maximum allowed concurency is 5,
use --max-log-requests to increase the limit
```

---

class: extra-details

## Pourquoi ne peut-on pas suivre les logs de plein de pods?

- `kubectl` ouvre une connection vers le serveur API par _pod_

- Pour chaque _pod_, le serveur API ouvre une autre connexion vers le kubelet correspondant.

- S'il y a 1000 pods dans notre déploiement, cela fait 1000 connexions entrantes + 1000 connexions au serveur API.

- Cela peut facilement surcharger le serveur API.

- Avant la version 1.14 de K8S, il a été décidé de ne pas autoriser les multiple connexions.

- A partir de 1.14, c'est autorisé, mais plafonné à 5 connexions.

  (paramétrable via `--max-log-requests`)

- Pour plus de détails sur les tenants et aboutissants, voir
  [PR #67573](https://github.com/kubernetes/kubernetes/pull/67573)

---

## Limitations de `kubectl logs`

- On ne voit pas quel _pod_ envoie quelle ligne

- Si les _pods_ sont redémarrés / remplacés, le flux de log se fige.

- Si de nouveaux _pods_ arrivent, on ne verra pas leurs logs.

- Pour suivre les logs de plusieur pods, il nous faut écrire un sélecteur

- Certains outils externes corrigent ces limitations:

  (par ex.: [Stern](https://github.com/wercker/stern))

---

class: extra-details

## `kubectl logs -l ... --tail N`

- En exécutant cette commande dans Kubernetes 1.12, plusieurs lignes s'affichent

- C'est une régression quand `--tail` et `-l`/`--selector` sont couplés.

- Ca affichera toujours les 10 dernières lignes de la sortie de chaque conteneur.

  (au lieu du nombre de lignes spécifiées en ligne de commande)

- Le problème a été résolu dans Kubernetes 1.13

*Voir [#70554](https://github.com/kubernetes/kubernetes/issues/70554) pour plus de détails.*

---

## Est-ce qu'on n'est pas en train de submerger 1.1.1.1?

- Si on y réfléchit, c'est une bonne question!

- Pourtant, pas d'inquiétude:

  *Le groupe de recherche APNIC a géré les adresses 1.1.1.1 et 1.0.0.1. Alors qu'elles étaient valides, tellement de gens les ont introduit dans divers systèmes, qu'ils étaient continuellement submergés par un flot de trafic polluant. L'APNIC voulait étudier cette pollution mais à chaque fois qu'ils ont essayé d'annoncer les IPs, le flot de trafic a submergé tout réseau conventionnel. *

  (Source: https://blog.cloudflare.com/announcing-1111/)

- Il est tout à fait improbable que nos pings réunis puissent produire
  ne serait-ce qu'un modeste truc dans le NOC chez Cloudflare!
