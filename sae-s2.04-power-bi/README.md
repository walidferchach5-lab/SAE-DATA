# SAE S2.04 - Tableau de bord Power BI

> Donner aux dirigeants du « Jardin de Charlotte » des visuels qui les aident
> à décider : où sont les ventes, où sont les retards de livraison, et
> combien coûtent réellement les fleurs.

**BUT Informatique, semestre 2 - ressource R2.06 Bases de données**
Walid Ferchach · Raphaël Ghisquière - groupe G3S2A, mars 2026

Suite du projet [SAE S1.04](../sae-s1.04-base-de-donnees), sur la même
activité fictive mais à une autre échelle : ici la base Oracle fournie
contient 5 000 commandes, 7 500 bouquets et 800 clients.

Le sujet complet : [`docs/sujet-sae-s2.04.pdf`](docs/sujet-sae-s2.04.pdf).

## Le fichier

[`jardin-de-charlotte.pbix`](jardin-de-charlotte.pbix) - à ouvrir avec Power
BI Desktop. Le modèle est en mode *import* : les données sont embarquées
dans le fichier, qui s'ouvre donc sans accès à la base Oracle. Il ne faut
une connexion que pour rafraîchir les données.

## Le modèle

Huit tables importées depuis Oracle via le connecteur « Base de données
Oracle », puis mises en relation :

| Table | Rôle |
|---|---|
| `SAE_CLIENT` | clients, avec leur code postal |
| `SAE_VILLE` | communes et tarif de livraison |
| `SAE_COMMANDEBOUQUET` | commandes, dates et montant |
| `SAE_BOUQUET` | bouquets d'une commande |
| `SAE_COMPOSITION` | fleurs d'un bouquet |
| `SAE_FLEUR` | catalogue et prix de vente |
| `SAE_GROSSISTE` | fournisseurs |
| `SAE_ACHATFLEUR` | relevés d'achats quotidiens |

Les mesures et colonnes calculées ajoutées par-dessus :

| Mesure | Ce qu'elle calcule |
|---|---|
| `CA Total` | chiffre d'affaires brut de la période sélectionnée |
| `CA Annee Precedente` | le même, décalé d'un an, pour le KPI de comparaison |
| `Evolution du CA depuis 2024` | variation du CA en pourcentage |
| `Montant Net Total` | montant brut augmenté des frais de livraison |
| `Moy_Bouquets_Par_Cmd` | nombre moyen de bouquets par commande |
| `Moy_Fleurs_Par_Cmd` | nombre moyen de fleurs par commande |
| `Jours_Retard` | écart entre livraison effective et date prévue |
| `Retard Moyen Jours` | moyenne de ce retard sur la sélection |
| `STATUTLIVRAISON` | à l'heure / en retard / non livrée |
| `Marge Unitaire` | prix de vente d'une fleur moins son prix d'achat moyen |
| `ClientUnique` | identifiant d'affichage d'un client |
| `MontantTotalAchat` | dépense d'achat cumulée |

Le tableau de bord s'appuie sur une hiérarchie de dates, ce qui permet de
descendre de l'année au trimestre puis au mois par simple exploration,
plutôt que de dupliquer les visuels à chaque niveau de granularité.

## Les cinq pages

Les visuels sont regroupés par question métier, et non dans l'ordre du
sujet. Une barre de navigation permet de passer d'une page à l'autre.

**Ventes & Clientèle** - la page d'entrée. Un KPI compare le CA à celui de
l'année précédente, puis l'évolution annuelle du nombre de commandes et de
clients, du chiffre d'affaires brut et net, la composition moyenne des
commandes (bouquets et fleurs), et le classement des meilleurs clients.

**Suivi des Livraisons** - le volume de livraisons dans le temps et par
ville destinataire, la répartition des commandes entre livrées à l'heure, en
retard et non livrées, et le retard moyen en jours par année puis par ville.
Un filtre de dates décline l'ensemble de la page sur une période.

**Historique des Achats** - l'évolution du prix d'achat moyen unitaire et les
volumes achetés par année. Un filtre permet de suivre une fleur en
particulier.

**Fournisseurs & Marges** - la marge unitaire par fleur, et deux treemaps qui
comparent les grossistes sur le budget dépensé et sur les quantités
fournies : un fournisseur peut peser lourd dans les dépenses sans livrer le
plus gros volume.

**Répartition des clients** - une carte des clients par code postal, doublée
d'un tableau croisé pour lire les valeurs exactes.

## Couverture du sujet

| Demande | Où |
|---|---|
| 1, 2. Commandes et clients par année | Ventes & Clientèle |
| 3. Clients par code postal | Répartition des clients |
| 4, 5. Montants bruts puis nets par année | Ventes & Clientèle |
| 6. Moyennes de bouquets et de fleurs, zoom mensuel | Ventes & Clientèle |
| 7. Livraisons par mois / trimestre / année | Suivi des Livraisons |
| 8. Livraisons par ville | Suivi des Livraisons |
| 9. À l'heure / en retard / non livrées, par année | Suivi des Livraisons |
| 10. Retard moyen en jours par année | Suivi des Livraisons |
| 11, 12. Prix d'achat et volumes, par fleur | Historique des Achats |
| D. Trois besoins libres | KPI de CA et meilleurs clients (Ventes & Clientèle), marges et comparaison des grossistes (Fournisseurs & Marges) |

Les points 11 et 12 demandaient de pouvoir choisir une fleur, et le point 6
de pouvoir zoomer sur une année : ces interactions passent par les filtres de
page et l'exploration de la hiérarchie de dates.

## Évaluation

Soutenance orale : justification des choix de représentation et
reconstruction en direct d'un visuel désigné par l'enseignant. Une part
notable de la note portait sur le design du tableau de bord - mise en forme,
disposition, lisibilité, titres et couleurs.
