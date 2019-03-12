# Installer Kubernetes

- Comment avons-nous installé les clusters Kubernetes à qui on parle?

--

<!-- ##VERSION## -->

- On est passé par `kubeadm` sur des VMs fraîchement installées avec Ubuntu LTS

    1. Installer Docker

    2. Installer les paquets Kubernetes

    3. Lancer `kubeadm init` sur la première node (c'est ce qui va déployer le plan de contrôle)

    4. Installer Weave (la couche réseau _overlay_)
       <br/>
      (cette étape consiste en une seule commande `kubectl apply`; voir plus loin)

    5. Lancer `kubeadm join` sur les autres _nodes_ (avec le jeton fourni par `kubeadm init`)

    6. Copier le fichier de configuration généré par `kubeadm init`

- Allez voir [README d'installation des VMs](https://@@GITREPO@@/blob/master/prepare-vms/README.md) pour plus de détails.

---

## Inconvénients `kubeadm`

- N'installe ni Docker ni autre moteur de conteneurs

- N'installe pas de réseau _overlay_

- N'installe pas de mode multi-maître (pas de haute disponibilité)

--

  (En tout cas... pas encore!) Même si c'est une fonction [expérimentale en version 1.12](https://kubernetes.io/docs/setup/independent/high-availability/).)

--

  "C'est quand même le double de travail par rapport à un cluster Swarm 😕" -- Jérôme


---

## Autres options de déploiement

- Si vous êtes sur Azure:
  [AKS](https://azure.microsoft.com/services/kubernetes-service/)

- Si vous êtes sur Google Cloud:
  [GKE](https://cloud.google.com/kubernetes-engine/)

- Si vous êtes sur AWS:
  [EKS](https://aws.amazon.com/eks/),
  [eksctl](https://eksctl.io/),
  [kops](https://github.com/kubernetes/kops)

- Sur votre machine locale:
  [minikube](https://kubernetes.io/docs/setup/minikube/),
  [kubespawn](https://github.com/kinvolk/kube-spawn),
  [Docker Desktop](https://docs.docker.com/docker-for-mac/kubernetes/)

- Si vous avez un déploiement spécifique:
  [kubicorn](https://github.com/kubicorn/kubicorn)

  Sans doute à ce jour l'outil le plus proche  d'une solution multi-cloud/hybride, mais encore en développement.

---

## Encore plus d'options de déploiement

- Si vous aimez Ansible:
  [kubespray](https://github.com/kubernetes-incubator/kubespray)


- Si vous aimez Terraform:
  [typhoon](https://github.com/poseidon/typhoon)


- Si vous aimez Terraform et Puppet:
  [tarmak](https://github.com/jetstack/tarmak)

- Vous pouvez aussi apprendre à installer chaque composant manuellement, avec l'excellent tutoriel
[Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

 *Kubernetes The Hard Way est optimisé pour l'apprentissage, ce qui implique de prendre les détours obligatoires à la compréhension de chaque étape nécessaire pour la construction d'un cluster Kubernetes.*

- Il y a aussi nombre d'options commerciales disponibles!

- Pour une liste plus complète, veuillez consulter la documentation Kubernetes:
  <br/>
  on y trouve un super guide pour [choisir la bonne piste](https://kubernetes.io/docs/setup/pick-right-solution/)
