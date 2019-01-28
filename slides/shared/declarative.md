# Déclaratif vs Impératif

- Notre orchestrateur de conteneurs insiste fortement sur sa nature *déclarative*

- Déclaratif:

  *Je voudrais une tasse de thé*

- Impératif:

  *Faire bouillir de l'eau. Verser dans la théière. Ajouter les feuilles de thé. Infuser un moment. Servir dans une tasse.*

--

- Le mode déclaratif semble plus simple au début...

--

- ... tant qu'on sait comment préparer du thé


---

## Déclaratif vs Impératif

- Ce que le mode déclaratif devrait vraiment être:

  *Je voudrais une tasse de thé, obtenue en versant une infusion¹ de feuilles de thé dans une tasse.*

--

  *¹Une infusion est obtenue en laissant l'objet infuser quelques minutes dans l'eau chaude².*

--

  *²Liquide chaud obtenu en le versant dans un contenant³ approprié et le placer sur la gazinière.*

--

  *³Ah, finalement, des conteneurs! Quelque chose qu'on maitrise. Mettons-nous au boulot, n'est-ce pas?*

--

.footnote[Saviez-vous qu'il existait une [norme ISO](https://fr.wikipedia.org/wiki/ISO_3103) spécifiant comment infuser le thé?]

---

## Déclaratif vs Impératif

- Système impératifs:

  - plus simple

  - si une tache est interrompue, on doit la redémarrer de zéro

- Système déclaratifs:

  - si une tache est interrompue (ou si on arrive en plein milieu de la fête),
    on peut déduire ce qu'il  manque, et on complète juste par ce qui est nécessaire.

  - on doit être en mesure *d'observer* le système

  - ... et de calculer un "diff" entre *ce qui tourne en ce moment* et *ce que nous souhaitons*
