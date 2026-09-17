# Jeu de données - binôme 14

Six fichiers CSV fournis par l'enseignant SQL, spécifiques au binôme, à
charger dans la base créée par [`../sql/01_schema.sql`](../sql/01_schema.sql).

**Format commun :** UTF-8, séparateur `;`, fins de ligne CRLF, première
ligne d'en-tête, dates au format `JJ/MM/AAAA`, séparateur décimal `.`.

Les personnes, entreprises et adresses qui y figurent sont fictives : il
s'agit de données générées pour l'exercice.

| Fichier | Lignes | Contenu |
|---|---:|---|
| `fleur14.csv` | 25 | Catalogue des fleurs et leur prix de vente |
| `grossiste14.csv` | 8 | Fournisseurs (SIREN + raison sociale) |
| `livraison14.csv` | 51 | Tarif de livraison par code postal |
| `commandes14.csv` | 500 | Commandes, client et destinataire sur une même ligne |
| `compositions14.csv` | 3 917 | Bouquets et leur composition, au format « creux » |
| `achats14.csv` | 1 823 | Relevés d'achats quotidiens chez les grossistes |

Période couverte : **décembre 2020 → juillet 2025**.

## Les trois points de vigilance

Aucun fichier n'est directement au format des tables finales. Trois écarts
expliquent le détour par des tables de travail dans
[`../sql/03_import_donnees.sql`](../sql/03_import_donnees.sql).

### 1. `commandes14.csv` mélange deux entités

Chacune des 500 lignes porte à la fois les coordonnées du client et celles
de la commande. Comme un client commande plusieurs fois, ses coordonnées y
sont répétées : les 500 lignes ne concernent que **125 clients distincts**.
Un `DISTINCT` sur l'adresse mail suffit à les dédoublonner - aucun mail
n'est associé à deux fiches divergentes.

Les colonnes du destinataire sont vides sur **134 commandes** : ce sont les
retraits en magasin, pour lesquels il n'y a ni adresse de livraison ni
frais. C'est exactement le critère `codePostalLivraison IS NULL` utilisé
par la requête R8. Les 366 autres commandes sont livrées.

### 2. `compositions14.csv` utilise un format « creux »

Les trois premières colonnes ne sont renseignées qu'à la première ligne de
chaque bouquet ; les lignes suivantes n'ajoutent qu'une fleur au bouquet
courant.

```
numCommande;numBouquet;nbrBouquets;nomFleur;nbrFleurs
1;1;1;Jasmin;10
;;;Crocus;4          <- toujours le bouquet 1 de la commande 1
1;2;2;Lys;5
;;;Paquerette;4      <- bouquet 2 de la commande 1
;;;Chrysantheme;5
```

Le fichier ne se lit donc que **dans l'ordre des lignes**, d'où la colonne
identité `id_ligne` de la table de travail et le `LAST_VALUE(... IGNORE
NULLS)` qui propage vers le bas la dernière valeur renseignée.

Les 3 917 lignes se répartissent en **1 282 bouquets** et **3 917 lignes de
composition** (chaque ligne du fichier porte une fleur).

### 3. `livraison14.csv` ne contient pas le nom des communes

Le fichier ne donne que le couple code postal / tarif. Le nom de la commune
est reconstitué depuis les commandes, où chaque code postal apparaît avec sa
ville - la correspondance y est bien de 1 pour 1. Quatre codes postaux du
référentiel (`69310`, `69340`, `69370`, `69800`) n'apparaissent dans aucune
commande et gardent donc une ville `NULL` : leur tarif est connu, mais
aucune livraison n'y a encore eu lieu.

## Intégrité vérifiée

Contrôles passés sur les fichiers avant import, tous sans écart :

- aucun doublon sur les clés primaires reconstituées
  (`ACHAT`, `COMPOSITION`) ;
- aucune référence orpheline : toutes les fleurs, tous les SIREN, tous les
  codes postaux et tous les numéros de commande cités existent bien dans
  leur référentiel ;
- cohérence chronologique respectée sur les 500 commandes :
  `dateCommande < dateRealisation ≤ dateLivraisonEffective` et
  `dateCommande ≤ datePaiement`. Les `CHECK` du schéma passent donc sans
  rejet.

Quatre commandes n'ont ni date de paiement ni date de réalisation : elles
sont restées en attente de règlement.
