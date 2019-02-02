# Gestion des secrets et chiffrement au repos

(Nouveau dans Docker Engine 1.13)

- Gestion des secrets = lier les secrets et les services quand il le faut, et en toute sécurité

- Chiffrement au repos = protéger contre le vol de données et l'espionnage

- Rappelez-vous:

  - le plan de contrôle est authentifié via un TLS mutuel, dont les certificats sont renouvelés tous les 90 jours

  - le plan de contrôle est chiffré en AES-GCM, et ses clés sont renouvelées toutes les 12 heures.

  - le plan de données n'est pas chiffré par défaut (pour raison de performance),
    <br/>mais nous avons vu plus haut comment l'activer avec une seule option
