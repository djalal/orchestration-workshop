class: in-person

## Se connecter à notre environnement de test

.exercise[

- Connectez-vous sur la première VM (`node1`) avec votre client SSH

<!--
```bash
for N in $(awk '/\Wnode/{print $2}' /etc/hosts); do
  ssh -o StrictHostKeyChecking=no $N true
done
```

```bash
if which kubectl; then
  kubectl get deploy,ds -o name | xargs -rn1 kubectl delete
  kubectl get all -o name | grep -v service/kubernetes | xargs -rn1 kubectl delete --ignore-not-found=true
  kubectl -n kube-system get deploy,svc -o name | grep -v dns | xargs -rn1 kubectl -n kube-system delete
fi
```
-->

- Vérifiez que vous pouvez passer sur `node2` sans mot de passe:
  ```bash
  ssh node2
  ```
- Tapez `exit` ou `^D` pour revenir à `node1`

<!-- ```bash exit``` -->

]

Si quoique ce soit va mal - appelez à l'aide!

---

## Doing or re-doing the workshop on your own?

- Use something like
  [Play-With-Docker](https://play-with-docker.com/) or
  [Play-With-Kubernetes](https://training.play-with-kubernetes.com/)

  Zero setup effort; but environment are short-lived and
  might have limited resources

- Create your own cluster (local or cloud VMs)

  Small setup effort; small cost; flexible environments

- Create a bunch of clusters for you and your friends
    ([instructions](https://@@GITREPO@@/tree/master/prepare-vms))

  Bigger setup effort; ideal for group training

---

class: self-paced

## Get your own Docker nodes

- If you already have some Docker nodes: great!

- If not: let's get some thanks to Play-With-Docker

.exercise[

- Go to http://www.play-with-docker.com/

- Log in

- Create your first node

<!-- ```open http://www.play-with-docker.com/``` -->

]

You will need a Docker ID to use Play-With-Docker.

(Creating a Docker ID is free.)

---

## On travaillera (surtout) avec node1

*Ces remarques s'appliquent uniquement en cas de serveurs multiples, bien sûr.*

- Sauf contre-indication expresse, **toutes les commandes sont lancées depuis la première VM, `node1`**

- Tout code sera récupéré sur `node1` uniquement.

- En administration classique, nous n'avons pas besoin d'accéder aux autres serveurs.

- Si nous devions diagnostiquer une panne, on utiliserait tout ou partie de:

  - SSH (pour accéder aux logs de système, statut du _daemon_, etc.)

  - l'API Docker (pour vérifier les conteneurs lancés, et l'état du moteur de conteneurs)

---

## Terminaux

Once in a while, the instructions will say:
<br/>"Open a new terminal."

There are multiple ways to do this:

- create a new window or tab on your machine, and SSH into the VM;

- use screen or tmux on the VM and open a new window from there.

You are welcome to use the method that you feel the most comfortable with.

---

## Tmux cheatsheet

[Tmux](https://en.wikipedia.org/wiki/Tmux) is a terminal multiplexer like `screen`.

*You don't have to use it or even know about it to follow along.
<br/>
But some of us like to use it to switch between terminals.
<br/>
It has been preinstalled on your workshop nodes.*

- Ctrl-b c → creates a new window
- Ctrl-b n → go to next window
- Ctrl-b p → go to previous window
- Ctrl-b " → split window top/bottom
- Ctrl-b % → split window left/right
- Ctrl-b Alt-1 → rearrange windows in columns
- Ctrl-b Alt-2 → rearrange windows in rows
- Ctrl-b arrows → navigate to other windows
- Ctrl-b d → detach session
- tmux attach → reattach to session
