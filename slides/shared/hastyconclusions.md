## Hasardons-nous à des conclusions hâtives

- Le goulot d'étranglement semble être `rng`.

- Et si *à tout hasard*, nous n'avions pas assez d'entropie, et qu'on ne pouvait générer assez de nombres aléatoires?

- On doit escalader le service `rng` sur plusieurs machines!

Note: ceci est une fiction! Nous avons assez d'entropie. Mais on a besoin d'un prétexte pour monter en charge.

(En réalité, le code de `rng` exploite `/dev/urandom`, qui n'est jamais à court d'entropie...)
<br/>
...et c'est [tout aussi bon que `/dev/random`](https://www.slideshare.net/PacSecJP/filippo-plain-simple-reality-of-entropy).)