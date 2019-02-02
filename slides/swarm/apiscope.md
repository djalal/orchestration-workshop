## Un rappel sur la *visibilité*

- A l'installation, l'accès à l'API Docker est "tout ou rien"

- Quand quelqu'un accès à l'API Docker, il peut faire *n'importe quoi*

- Si vos développeurs utilisent l'API Docker pour déployer sur le cluster de dev...

  ... et que le cluster de dev est le même que le cluster de prod ...

  ... ça revient à donner aux devs l'accès aux données de production, mots de passe, etc.

- C'est assez simple d'éviter ça.

---

## Contrôle d'accès à l'API plus fin

Quelques solutions, par ordre croissant de flexibilité:

- Installer plusieurs clusters avec différent périmètre de sécurité

  (et différents identifiants d'accès pour chacun)

--

- Ajouter une couche supplémentaire d'abstraction (scripts sudo, _hooks_, ou un vrai PAAS)

--

- Activer les [plugins d'autorisation]

  - chaque requête vers l'API est filtrée par un ou plusieurs plugins(s)

  - par défaut, le champ *subject name* du certificat TLS client est utilisé comme identifiant

  - exemple: [user and permission management] dans [UCP]

[plugins d'autorisation]: https://docs.docker.com/engine/extend/plugins_authorization/
[UCP]: https://docs.docker.com/datacenter/ucp/2.1/guides/
[user and permission management]: https://docs.docker.com/datacenter/ucp/2.1/guides/admin/manage-users/
