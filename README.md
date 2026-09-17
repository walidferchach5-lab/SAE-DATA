# Jardin de Charlotte - deux SAE de données

Deux projets de BUT Informatique sur une même activité fictive, la boutique
d'une fleuriste lyonnaise. Le premier construit la base de données depuis un
cahier des charges ; le second la fait parler.

| Projet | Semestre | Sujet | Outils |
|---|---|---|---|
| [**SAE S1.04** - Conception et création d'une base de données](sae-s1.04-base-de-donnees) | S1 | Du MCD aux requêtes d'exploitation | Looping, Oracle, SQL Developer |
| [**SAE S2.04** - Tableau de bord](sae-s2.04-power-bi) | S2 | Cinq pages de visuels pour les dirigeants | Power BI Desktop, Oracle |

Walid Ferchach - BUT Informatique
Binôme S1.04 : Amdjed Loucif · Binôme S2.04 : Raphaël Ghisquière

## Le fil conducteur

« Le Jardin de Charlotte » vend des bouquets sur commande. Le client décrit
la composition de chaque bouquet, le nombre d'exemplaires qu'il en veut, et
choisit entre un retrait en magasin et une livraison chez un destinataire qui
n'est pas forcément lui. Chaque matin la fleuriste achète chez des grossistes
les fleurs des commandes du jour, et relève leur prix pour suivre ses coûts.

La même activité, donc, mais deux points de vue : **modéliser puis
interroger** en S1, **analyser et présenter** en S2.

## SAE S1.04 - Conception et création d'une base de données

Modélisation conceptuelle du cahier des charges, traduction en schéma Oracle,
import d'un jeu de données de 500 commandes, puis neuf requêtes
d'exploitation.

Ce que le dépôt contient : le MCD et son modèle Looping éditable, les scripts
de création commentés entité par entité, la procédure d'import des CSV
fournis, les requêtes R1 à R9 annotées de leurs résultats, et le rapport
rendu.

→ [Voir le projet](sae-s1.04-base-de-donnees)

## SAE S2.04 - Tableau de bord Power BI

Un rapport Power BI de cinq pages construit sur la version complète de la
base (5 000 commandes), avec les mesures DAX nécessaires aux indicateurs
demandés : chiffre d'affaires brut et net, retards de livraison, prix
d'achat des fleurs, marges par fournisseur.

→ [Voir le projet](sae-s2.04-power-bi)

## Note sur les données

Les jeux de données sont fournis par l'IUT pour l'exercice : les personnes,
entreprises et adresses qui y figurent sont fictives. Les sujets en PDF
restent la propriété de leurs auteurs et ne sont inclus que pour rendre les
projets lisibles.
