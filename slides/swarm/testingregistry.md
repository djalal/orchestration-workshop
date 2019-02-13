## Tester notre registre local

- On peut re-_tag_ une petite image, et la pousser dans le registre

.exercise[

- Vérifier qu'on a une image busybox, et y rajouter un _tag_:
  ```bash
  docker pull busybox
  docker tag busybox 127.0.0.1:5000/busybox
  ```

- La livrer sur le registre:
  ```bash
  docker push 127.0.0.1:5000/busybox
  ```

]

---

## Vérifier ce qui est dans le registre local

- L'API du _Registry_ a des points d'entrée pour vérifier son contenu

.exercise[

- Vérifier que notre image busybox est bien présente en local:
  ```bash
  curl http://127.0.0.1:5000/v2/_catalog
  ```

]

La commande curl devrait afficher:
```json
{"repositories":["busybox"]}
```
