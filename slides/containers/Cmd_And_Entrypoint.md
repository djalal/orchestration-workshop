
class: title

# `CMD` et `ENTRYPOINT`

![Container entry doors](images/entrypoint.jpg)

---

## Objectifs

Dans cette leçon, nous verrons deux instructions
importantes du `Dockerfile`:

`CMD` et `ENTRYPOINT`.

Ces instructions nous permettent de déclarer la
commande par défaut à lancer dans un conteneur.

---

## Définir une commande par défaut

Quand quelqu'un lancera notre conteneur, nous voulons le saluer avec un sympathique bonjour, et une fonte spéciale.

Pour ça, nous allons lancer:

```bash
figlet -f script hello
```

* `-f script` dit à figlet d'utiliser une fonte spécifique.

* `hello` est le message que nous voulons afficher.

---

## Ajouter `CMD` à notre Dockerfile

Notre nouveau `Dockerfile` aura cet aspect:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
CMD figlet -f script hello
```

* `CMD` définit une commande par défaut à lancer quand aucune n'est précisée.

* Elle peut apparaître n'importe où dans le fichier.

* Chaque `CMD` annulera et remplacera la précédente.

* Par conséquent, même si vous pouvez utiliser plusieurs fois `CMD`, c'est inutile au final.

---

## Générer et tester notre image

Essayons de lancer un _build_:

```bash
$ docker build -t figlet .
...
Successfully built 042dff3b4a8d
Successfully tagged figlet:latest
```

Et de le lancer:

```bash
$ docker run figlet
 _          _   _       
| |        | | | |      
| |     _  | | | |  __  
|/ \   |/  |/  |/  /  \_
|   |_/|__/|__/|__/\__/ 
```

---

## Surcharger `CMD`

Si nous voulons ouvrir un _shell_ dans notre conteneur (au lieu de
lancer `figlet`), il suffit de spécifier un autre programme à lancer:

```bash
$ docker run -it figlet bash
root@7ac86a641116:/# 
```

* On a indiqué `bash`

* Il a remplacé la valeur de `CMD`

---

## Utiliser `ENTRYPOINT`

Nous voulons être capable de spécifier un message différent en ligne de commande,
tout en gardant `figlet` et quelques paramètres par défaut.

Autrement dit, on aimerait taper quelque chose comme:

```bash
$ docker run figlet salut
           _            
          | |           
 ,   __,  | |       _|_ 
/ \_/  |  |/  |   |  |  
 \/ \_/|_/|__/ \_/|_/|_/
```

Nous utiliserons pour ça l'instruction `ENTRYPOINT` du Dockerfile.

---

## Ajouter `ENTRYPOINT` à notre Dockerfile

Notre nouveau Dockerfile aura cet aspect:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
ENTRYPOINT ["figlet", "-f", "script"]
```

* `ENTRYPOINT` définit une commande de base (et ses paramètres) pour le conteneur.

* Les arguments en ligne de commande sont ajoutés aux paramètres ci-dessus.

* Tout comme `CMD`, `ENTRYPOINT` peut apparaître n'importe où, et remplacera la valeur précédente.

Pourquoi avoir utilisé la syntaxe JSON pour notre `ENTRYPOINT`?

---

## Implications des syntaxes JSON vs simple

* Quand CMD ou ENTRYPOINT utilisent la syntaxe simple, ils sont encapsulés dans `sh -c`

* Pour éviter ce comportement, on peut utiliser la syntaxe JSON.

Et qu'est-ce qu'il se passerait avec une syntaxe simple dans `ENTRYPOINT`?

```bash
$ docker run figlet salut
```

On obtiendrait la commande suivante dans l'image `figlet`:

```bash
sh -c "figlet -f script" salut
```

---

## Générer et tester notre image

Lançons un _build_:

```bash
$ docker build -t figlet .
...
Successfully built 36f588918d73
Successfully tagged figlet:latest
```

Exécutons là:

```bash
$ docker run figlet salut
           _            
          | |           
 ,   __,  | |       _|_ 
/ \_/  |  |/  |   |  |  
 \/ \_/|_/|__/ \_/|_/|_/
```

---

## Usage conjoint de `CMD` et `ENTRYPOINT`

Et si nous voulions définir un message par défaut pour notre conteneur?

Alors nous utiliserions `ENTRYPOINT` et `CMD` ensemble.

* `ENTRYPOINT` va définir la commande de base pour notre conteneur.

* `CMD` définira les paramètres par défaut pour cette commande.

Ils doivent *tous les deux* utiliser la syntaxe JSON.

---

## `CMD` et `ENTRYPOINT` ensemble

Notre nouveau Dockerfile a cette tête:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN ["apt-get", "install", "figlet"]
ENTRYPOINT ["figlet", "-f", "script"]
CMD ["hello world"]
```

* `ENTRYPOINT` définit une commande de base (et ses paramètres) pour le conteneur.

* Si nous ne spécifions aucun argument supplémentaire au lancement du conteneur,
la valeur de `CMD` y est ajoutée.

* Autrement, nos arguments supplémentaires de ligne de commande remplacent `CMD`.

---

## Générer et tester notre image


Lançons un _build_:

```bash
$ docker build -t figlet .
...
Successfully built 6e0b6a048a07
Successfully tagged figlet:latest
```

Exécutons-là sans paramètres:

```bash
$ docker run figlet
 _          _   _                             _        
| |        | | | |                           | |    |  
| |     _  | | | |  __             __   ,_   | |  __|  
|/ \   |/  |/  |/  /  \_  |  |  |_/  \_/  |  |/  /  |  
|   |_/|__/|__/|__/\__/    \/ \/  \__/    |_/|__/\_/|_/
```

---

## Surcharger les paramètres par défaut de l'image

Maintenant, passons des arguments supplémentaires à l'image.

```bash
$ docker run figlet hola mundo
 _           _                                               
| |         | |                                      |       
| |     __  | |  __,     _  _  _           _  _    __|   __  
|/ \   /  \_|/  /  |    / |/ |/ |  |   |  / |/ |  /  |  /  \_
|   |_/\__/ |__/\_/|_/    |  |  |_/ \_/|_/  |  |_/\_/|_/\__/ 
```

Nous avons surchargé `CMD` tout en gardant `ENTRYPOINT`.

---

## Surcharger `ENTRYPOINT`

Et si nous voulons lancer un _shell_ dans notre conteneur?

On ne peut pas juste taper `docker run figlet bash` car
ça dirait juste à figlet d'afficher le mot "bash".

On utilise donc le paramètre `--entrypoint`:

```bash
$ docker run -it --entrypoint bash figlet
root@6027e44e2955:/# 
```

