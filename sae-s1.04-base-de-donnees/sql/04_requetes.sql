-- =====================================================================
--  Jardin de Charlotte - SAE S1.04
--  04 - Exploitation de la base : requetes R1 a R9 (question 7)
--
--  A executer apres 01_schema.sql et 03_import_donnees.sql.
--  Les resultats commentes sont ceux obtenus sur le jeu de donnees du
--  binome 14 (data/), qui couvre decembre 2020 a juillet 2025.
--
--  Deux formules de montant reviennent tout au long du fichier :
--
--    montant brut = somme, sur les fleurs de la commande, de
--                   tarifFleur x quantite x nbrBouquets
--                   (une fleur compte autant de fois qu'il y a
--                    d'exemplaires du bouquet qui la contient)
--
--    montant net  = montant brut + tarifLivraison de la commune livree
--                   (nul en cas de retrait en magasin, d'ou le NVL sur
--                    une jointure externe vers LOCALITE)
-- =====================================================================


-- ---------------------------------------------------------------------
-- R1. Le nombre de commandes payees en 2021
--
-- datePaiement NULL = commande restee en attente : elle est ecartee
-- par la condition sur l'annee, sans avoir a le preciser.
--
-- Resultat : 127 commandes.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS nb_commandes_payees_2021
FROM   COMMANDE
WHERE  EXTRACT(YEAR FROM datePaiement) = 2021;


-- ---------------------------------------------------------------------
-- R2. Les 3 premiers codes postaux ou il y a le plus de livraisons
--
-- Une commande sans code postal de livraison est un retrait en
-- magasin : elle ne compte pas comme une livraison.
-- La jointure sur LOCALITE ne sert qu'a afficher le nom de la commune.
--
-- Resultat : 69230 Saint-Genis-Laval (27), 69680 Chassieu (24),
--            69006 Lyon 6eme (21).
-- ---------------------------------------------------------------------
SELECT cmd.codePostalLivraison AS code_postal,
       l.ville,
       COUNT(*)                AS nb_livraisons
FROM   COMMANDE cmd
JOIN   LOCALITE l ON l.codePostal = cmd.codePostalLivraison
WHERE  cmd.codePostalLivraison IS NOT NULL
GROUP BY cmd.codePostalLivraison, l.ville
ORDER BY nb_livraisons DESC
FETCH FIRST 3 ROWS ONLY;


-- ---------------------------------------------------------------------
-- R3. La fleur la plus utilisee en 2021
--
-- On compte les fleurs reellement confectionnees : une fleur presente
-- dans un bouquet commande en 3 exemplaires est utilisee 3 fois, d'ou
-- le produit quantite x nbrBouquets.
--
-- Resultat : le Tournesol, avec 438 fleurs utilisees.
-- ---------------------------------------------------------------------
SELECT c.nomFleur,
       SUM(c.quantite * b.nbrBouquets) AS nb_fleurs_utilisees
FROM   COMPOSITION c
JOIN   BOUQUET     b   ON b.numCommande   = c.numCommande
                      AND b.numBouquet    = c.numBouquet
JOIN   COMMANDE    cmd ON cmd.numCommande = b.numCommande
WHERE  EXTRACT(YEAR FROM cmd.dateCommande) = 2021
GROUP BY c.nomFleur
ORDER BY nb_fleurs_utilisees DESC
FETCH FIRST 1 ROWS ONLY;


-- ---------------------------------------------------------------------
-- R4. Le nombre moyen de bouquets par client
--
-- Lecture retenue : nombre total de bouquets commandes rapporte au
-- nombre de clients. On totalise donc d'abord par client, puis on fait
-- la moyenne de ces totaux -- et non la moyenne ligne a ligne de
-- nbrBouquets, qui donnerait le nombre moyen de bouquets par ligne de
-- commande.
--
-- Les clients n'ayant jamais commande ne sont pas comptes : dans ce
-- jeu de donnees, les 125 clients ont tous au moins une commande.
--
-- Resultat : 17,8 bouquets par client.
-- ---------------------------------------------------------------------
SELECT ROUND(AVG(total_bouquets), 2) AS nb_moyen_bouquets_par_client
FROM (
    SELECT cmd.mailClient,
           SUM(b.nbrBouquets) AS total_bouquets
    FROM   COMMANDE cmd
    JOIN   BOUQUET  b ON b.numCommande = cmd.numCommande
    GROUP BY cmd.mailClient
);


-- ---------------------------------------------------------------------
-- R5. Les fleurs jamais utilisees dans les bouquets
--
-- NOT IN est sans danger ici : nomFleur appartient a la cle primaire
-- de COMPOSITION, la sous-requete ne peut donc pas renvoyer de NULL.
--
-- Resultat attendu : Iris, Magnolia, Marguerite, Pensee.
-- ---------------------------------------------------------------------
SELECT nomFleur, tarifFleur
FROM   FLEUR
WHERE  nomFleur NOT IN (SELECT nomFleur FROM COMPOSITION)
ORDER BY nomFleur;


-- ---------------------------------------------------------------------
-- R6. La fleur preferee de chaque client
--
-- "La fleur qu'il a commande le plus de fois" est comprise comme la
-- fleur dont il a commande le plus d'exemplaires au total.
--
-- RANK() plutot que ROW_NUMBER() : en cas d'egalite parfaite entre
-- deux fleurs pour un meme client, les deux sont conservees, ce qui
-- evite d'en designer une arbitrairement.
--
-- Resultat : 131 lignes pour 125 clients -- six d'entre eux ont deux
-- fleurs a egalite en tete.
-- ---------------------------------------------------------------------
SELECT mailClient, nomClient, nomFleur, qte_totale
FROM (
    SELECT cmd.mailClient,
           cl.nomClient,
           c.nomFleur,
           SUM(c.quantite * b.nbrBouquets) AS qte_totale,
           RANK() OVER (
               PARTITION BY cmd.mailClient
               ORDER BY SUM(c.quantite * b.nbrBouquets) DESC
           ) AS rang
    FROM   COMMANDE    cmd
    JOIN   CLIENT      cl ON cl.mailClient  = cmd.mailClient
    JOIN   BOUQUET     b  ON b.numCommande  = cmd.numCommande
    JOIN   COMPOSITION c  ON c.numCommande  = b.numCommande
                         AND c.numBouquet   = b.numBouquet
    GROUP BY cmd.mailClient, cl.nomClient, c.nomFleur
)
WHERE rang = 1
ORDER BY nomClient;


-- ---------------------------------------------------------------------
-- R7. Numero de commande, date, nom du client et montant
--
-- Le montant affiche est le montant net, celui effectivement facture :
-- montant des fleurs plus frais de livraison eventuels.
-- LEFT JOIN sur LOCALITE pour ne pas perdre les retraits en magasin,
-- et NVL pour leur affecter 0 EUR de frais.
--
-- Resultat : les 500 commandes. Par exemple la commande 1 (Royer,
-- 01/12/2020) : 164,00 de fleurs + 10,00 de livraison = 174,00 EUR.
-- ---------------------------------------------------------------------
SELECT cmd.numCommande,
       cmd.dateCommande,
       cl.nomClient,
       SUM(f.tarifFleur * c.quantite * b.nbrBouquets)                            AS montant_brut,
       NVL(l.tarifLivraison, 0)                                                  AS frais_livraison,
       SUM(f.tarifFleur * c.quantite * b.nbrBouquets) + NVL(l.tarifLivraison, 0) AS montant_net
FROM       COMMANDE    cmd
JOIN       CLIENT      cl ON cl.mailClient  = cmd.mailClient
JOIN       BOUQUET     b  ON b.numCommande  = cmd.numCommande
JOIN       COMPOSITION c  ON c.numCommande  = b.numCommande
                         AND c.numBouquet   = b.numBouquet
JOIN       FLEUR       f  ON f.nomFleur     = c.nomFleur
LEFT JOIN  LOCALITE    l  ON l.codePostal   = cmd.codePostalLivraison
GROUP BY cmd.numCommande, cmd.dateCommande, cl.nomClient, l.tarifLivraison
ORDER BY cmd.numCommande;


-- ---------------------------------------------------------------------
-- R8. Le client qui a passe la commande la plus chere avec retrait
--     en magasin
--
-- Retrait en magasin = aucun code postal de livraison, donc aucun frais
-- a ajouter : le montant brut est ici le montant final.
--
-- Resultat : Boutique Esprit Boheme, commande 414 du 18/11/2024,
--            535,00 EUR.
-- ---------------------------------------------------------------------
SELECT cl.nomClient,
       cmd.numCommande,
       cmd.dateCommande,
       SUM(f.tarifFleur * c.quantite * b.nbrBouquets) AS montant
FROM   COMMANDE    cmd
JOIN   CLIENT      cl ON cl.mailClient  = cmd.mailClient
JOIN   BOUQUET     b  ON b.numCommande  = cmd.numCommande
JOIN   COMPOSITION c  ON c.numCommande  = b.numCommande
                     AND c.numBouquet   = b.numBouquet
JOIN   FLEUR       f  ON f.nomFleur     = c.nomFleur
WHERE  cmd.codePostalLivraison IS NULL
GROUP BY cmd.numCommande, cmd.dateCommande, cl.nomClient
ORDER BY montant DESC
FETCH FIRST 1 ROWS ONLY;


-- ---------------------------------------------------------------------
-- R9. Le client qui a passe la commande la plus chere, livraison ou
--     retrait confondus
--
-- Meme principe que R8, mais sans filtre et sur le montant net : les
-- frais de livraison font partie de ce que le client a paye.
--
-- Resultat : Moreau, commande 456 livree a Lyon 8eme, 640,00 EUR.
-- ---------------------------------------------------------------------
SELECT cl.nomClient,
       cmd.numCommande,
       cmd.dateCommande,
       NVL(l.ville, 'Retrait en magasin')                                        AS destination,
       SUM(f.tarifFleur * c.quantite * b.nbrBouquets) + NVL(l.tarifLivraison, 0) AS montant_net
FROM       COMMANDE    cmd
JOIN       CLIENT      cl ON cl.mailClient  = cmd.mailClient
JOIN       BOUQUET     b  ON b.numCommande  = cmd.numCommande
JOIN       COMPOSITION c  ON c.numCommande  = b.numCommande
                         AND c.numBouquet   = b.numBouquet
JOIN       FLEUR       f  ON f.nomFleur     = c.nomFleur
LEFT JOIN  LOCALITE    l  ON l.codePostal   = cmd.codePostalLivraison
GROUP BY cmd.numCommande, cmd.dateCommande, cl.nomClient, l.ville, l.tarifLivraison
ORDER BY montant_net DESC
FETCH FIRST 1 ROWS ONLY;
