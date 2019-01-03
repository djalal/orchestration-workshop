# Pilote réseau pour conteneur

Le Docker Engine prend en charge de nombreux pilotes réseau.

Certains pilotes sont inclus à l'installation:

* `bridge` (par défaut)

* `none`

* `host`

* `container`

Le pilote est indiqué avec `docker run --net ...`.

Les différents pilotes sont expliqués en détail dans les diapos suivantes.

---

## La passerelle par défaut (_bridge_)

* Par défaut, le conteneur dispose d'une interface `eth0` virtuelle.
  <br/>(En supplément de `lo`, sa propre interface de boucle interne).

* Cette interface est fournie par une paire `veth`.

* Elle est connectée au Docker _bridge_.
  <br/>(Appelé `docker0` par défaut; configurable avec `--bridge`.)

* L'allocation d'adresses IP se fait sur un sous-réseau privé interne.
  <br/>(Docker utilise 172.17.0.0/16 par défaut; configurable avec `--bip`.)

* Le trafic sortant passe à travers une règle iptables MASQUERADE.

* Le trafic entrant passe à travers une règle iptables DNAT.

* Le conteneur peut avoir ses propres routes, règles iptables, etc.

---

## Le pilote null

* On démarre le conteneur avec `docker run --net none ...`

* Il n'aura que l'interface de bouclage `lo`. Pas de `eth0`.

* Il ne peut ni recevoir ni envoyer de trafic réseau.

* Utile pour les logiciels isolés/suspects.

---

## Le pilote hôte

* On démarre le conteneur avec `docker run --net host ...`

* Il voit (et peut accéder) aux interfaces réseau de l'hôte.

* Il peut ouvrir n'importe quelle interface et port (pour le meilleur et pour le pire).

* Le trafic réseau se passe des couches NAT, bridge ou veth.

* Performance = native!

Cas d'usage:

* Applications sensibles à la performance (VOIP, jeu-vidéo, streaming...)

* découvertes d'homologue (par ex. mappage de port Erlang, Raft, Serf ...)

---

## Le pilote conteneur

* On démarre le conteneur avec `docker run --net container:id ...`

* Il recycle la pile réseau d'un autre conteneur.

* Il partage avec l'autre conteneur les mêmes interfaces, adresses IP, routes, règles iptables, etc.

* Ces conteneurs peuvent communiquer à travers leur interface `lo`.
  <br/>(i.e. l'un peut s'attacher à 127.0.0.1 et les autres peuvent s'y connecter.)

