-- =====================================================================
--  Jardin de Charlotte - SAE S1.04
--  03 - Import du jeu de donnees du binome (question 6)
--
--  Charge les 6 fichiers de data/ : 25 fleurs, 8 grossistes,
--  51 localites, 1823 achats, 500 commandes, 1282 bouquets et
--  3917 lignes de composition.
--
--  Les fichiers CSV ne sont pas au format des tables finales : ils
--  melangent plusieurs entites (commandes14.csv contient a la fois le
--  client et la commande) et compositions14.csv utilise un format
--  "creux" ou les colonnes de tete ne sont remplies qu'en debut de
--  bloc. On passe donc par des tables de travail TMP_*, chargees
--  telles quelles, puis on eclate leur contenu vers les tables du
--  schema.
--
--  MODE OPERATOIRE
--  1. Executer 01_schema.sql (sur un schema vide).
--  2. Executer l'etape A ci-dessous pour creer les tables TMP_*.
--  3. Dans SQL Developer : clic droit sur chaque table TMP_*,
--     "Importer des donnees...", choisir le CSV correspondant dans
--     data/, separateur ";", encodage UTF-8, format de date
--     JJ/MM/AAAA, et laisser la premiere ligne comme en-tete.
--  4. Executer les etapes B a G.
--  5. Executer l'etape H (verifications) puis l'etape I (nettoyage).
--
--  Correspondance fichier -> table de travail :
--     fleur14.csv        -> TMP_FLEURS
--     grossiste14.csv    -> TMP_GROSSISTES
--     livraison14.csv    -> TMP_LIVRAISONS
--     achats14.csv       -> TMP_ACHATS
--     commandes14.csv    -> TMP_COMMANDES
--     compositions14.csv -> TMP_COMPOSITIONS
-- =====================================================================


-- =====================================================================
--  ETAPE A - Tables de travail
--
--  Tout est charge en VARCHAR2 : on laisse les conversions de type et
--  de format de date aux etapes suivantes, ce qui evite que l'import
--  echoue sur une cellule vide ou un separateur decimal inattendu.
--
--  TMP_COMPOSITIONS porte en plus une colonne identite : le format
--  creux du fichier ne se lit que dans l'ordre des lignes, il faut donc
--  memoriser cet ordre a l'import (voir etape F).
-- =====================================================================

CREATE TABLE TMP_FLEURS (
    nomFleur    VARCHAR2(50),
    tarifFleur  VARCHAR2(20)
);

CREATE TABLE TMP_GROSSISTES (
    numSIREN  VARCHAR2(20),
    nom       VARCHAR2(50)
);

CREATE TABLE TMP_LIVRAISONS (
    codePostal      VARCHAR2(5),
    tarifLivraison  VARCHAR2(20)
);

CREATE TABLE TMP_ACHATS (
    dateAchat          VARCHAR2(20),
    numSIREN           VARCHAR2(20),
    nomFleur           VARCHAR2(50),
    nbrFleurs          VARCHAR2(20),
    prixAchatUnitaire  VARCHAR2(20)
);

CREATE TABLE TMP_COMMANDES (
    numCommande              VARCHAR2(20),
    nomClient                VARCHAR2(100),
    numTelClient             VARCHAR2(20),
    mailClient               VARCHAR2(150),
    adresseClient            VARCHAR2(150),
    codePostalClient         VARCHAR2(5),
    villeClient              VARCHAR2(50),
    dateCommande             VARCHAR2(20),
    datePaiement             VARCHAR2(20),
    dateRealisation          VARCHAR2(20),
    nomDestinataire          VARCHAR2(100),
    numTelDestinataire       VARCHAR2(20),
    adresseDestinataire      VARCHAR2(150),
    codePostalDestinataire   VARCHAR2(5),
    villeDestinataire        VARCHAR2(50),
    dateLivraisonEffective   VARCHAR2(20)
);

CREATE TABLE TMP_COMPOSITIONS (
    id_ligne     NUMBER GENERATED ALWAYS AS IDENTITY,  -- conserve l'ordre du fichier
    numCommande  VARCHAR2(20),
    numBouquet   VARCHAR2(20),
    nbrBouquets  VARCHAR2(20),
    nomFleur     VARCHAR2(50),
    nbrFleurs    VARCHAR2(20)
);

COMMIT;

-- >>> Importer ici les 6 fichiers CSV de data/ dans ces tables. <<<


-- =====================================================================
--  ETAPE B - Referentiels simples
-- =====================================================================

INSERT INTO FLEUR (nomFleur, tarifFleur)
SELECT TRIM(nomFleur), TO_NUMBER(TRIM(tarifFleur))
FROM   TMP_FLEURS
WHERE  nomFleur IS NOT NULL;

INSERT INTO GROSSISTE (numSIREN, nom)
SELECT TRIM(numSIREN), TRIM(nom)
FROM   TMP_GROSSISTES
WHERE  numSIREN IS NOT NULL;

COMMIT;


-- =====================================================================
--  ETAPE C - Localites
--
--  livraison14.csv ne donne que le code postal et le tarif : le nom de
--  la commune n'y figure pas. On le recupere ensuite dans les
--  commandes, ou chaque code postal apparait avec sa ville (adresse du
--  client ou du destinataire).
--  Les 4 codes postaux du referentiel qui n'apparaissent dans aucune
--  commande (69310, 69340, 69370, 69800) gardent une ville NULL : le
--  tarif est connu, mais aucune livraison n'y a encore eu lieu.
-- =====================================================================

INSERT INTO LOCALITE (codePostal, ville, tarifLivraison)
SELECT TRIM(codePostal), NULL, TO_NUMBER(TRIM(tarifLivraison))
FROM   TMP_LIVRAISONS
WHERE  codePostal IS NOT NULL;

UPDATE LOCALITE l
SET    ville = (
           SELECT MIN(v.ville)
           FROM (
               SELECT TRIM(codePostalClient)       AS cp, TRIM(villeClient)       AS ville
               FROM   TMP_COMMANDES
               WHERE  codePostalClient IS NOT NULL
               UNION
               SELECT TRIM(codePostalDestinataire) AS cp, TRIM(villeDestinataire) AS ville
               FROM   TMP_COMMANDES
               WHERE  codePostalDestinataire IS NOT NULL
           ) v
           WHERE v.cp = l.codePostal
       );

COMMIT;


-- =====================================================================
--  ETAPE D - Clients
--
--  Les 500 lignes de commandes14.csv ne concernent que 125 clients :
--  un client qui a commande dix fois y apparait dix fois, avec les
--  memes coordonnees. Un DISTINCT sur le mail suffit donc a dedoublonner
--  (verifie : aucun mail n'est associe a deux fiches differentes).
-- =====================================================================

INSERT INTO CLIENT (
    mailClient, nomClient, adresseClient,
    codePostalClient, villeClient, numTelClient
)
SELECT DISTINCT
       TRIM(mailClient),
       TRIM(nomClient),
       TRIM(adresseClient),
       TRIM(codePostalClient),
       TRIM(villeClient),
       TRIM(numTelClient)
FROM   TMP_COMMANDES
WHERE  mailClient IS NOT NULL;

COMMIT;


-- =====================================================================
--  ETAPE E - Commandes
--
--  Une colonne de destinataire vide signifie un retrait en magasin :
--  pas d'adresse de livraison, donc pas de frais. On laisse dans ce cas
--  codePostalLivraison a NULL, ce qui est exactement le critere utilise
--  par la requete R8.
-- =====================================================================

INSERT INTO COMMANDE (
    numCommande, mailClient,
    dateCommande, datePaiement, dateRealisation, dateLivraisonEffective,
    nomDestinataire, adresseDestinataire, villeDestinataire,
    telDestinataire, codePostalLivraison
)
SELECT TO_NUMBER(TRIM(numCommande)),
       TRIM(mailClient),
       TO_DATE(TRIM(dateCommande),           'DD/MM/YYYY'),
       TO_DATE(TRIM(datePaiement),           'DD/MM/YYYY'),
       TO_DATE(TRIM(dateRealisation),        'DD/MM/YYYY'),
       TO_DATE(TRIM(dateLivraisonEffective), 'DD/MM/YYYY'),
       TRIM(nomDestinataire),
       TRIM(adresseDestinataire),
       TRIM(villeDestinataire),
       TRIM(numTelDestinataire),
       TRIM(codePostalDestinataire)
FROM   TMP_COMMANDES
WHERE  numCommande IS NOT NULL;

COMMIT;


-- =====================================================================
--  ETAPE F - Bouquets et compositions
--
--  compositions14.csv est organise par blocs : la premiere ligne d'un
--  bouquet porte son numero de commande, son numero et son nombre
--  d'exemplaires, les lignes suivantes ne portent que les fleurs qui
--  s'y ajoutent.
--
--      numCommande;numBouquet;nbrBouquets;nomFleur;nbrFleurs
--      1;1;1;Jasmin;10
--      ;;;Crocus;4          <- toujours le bouquet 1 de la commande 1
--      1;2;2;Lys;5
--      ;;;Paquerette;4      <- bouquet 2 de la commande 1
--
--  Les lignes de tete donnent directement les bouquets (etape F1).
--  Pour les compositions, il faut au contraire propager vers le bas la
--  derniere valeur renseignee : c'est le role de
--  LAST_VALUE(... IGNORE NULLS), dont la fenetre par defaut s'arrete a
--  la ligne courante et qui renvoie donc la derniere valeur non nulle
--  rencontree jusqu'ici (etape F2).
-- =====================================================================

-- F1 - un bouquet par ligne de tete de bloc
INSERT INTO BOUQUET (numCommande, numBouquet, nbrBouquets)
SELECT TO_NUMBER(TRIM(numCommande)),
       TO_NUMBER(TRIM(numBouquet)),
       TO_NUMBER(TRIM(nbrBouquets))
FROM   TMP_COMPOSITIONS
WHERE  numCommande IS NOT NULL;

-- F2 - une composition par ligne portant une fleur, rattachee au
--      dernier bouquet declare au-dessus d'elle
INSERT INTO COMPOSITION (numCommande, numBouquet, nomFleur, quantite)
SELECT cmd, bqt, nomFleur, qte
FROM (
    SELECT LAST_VALUE(TO_NUMBER(TRIM(numCommande)) IGNORE NULLS)
               OVER (ORDER BY id_ligne)  AS cmd,
           LAST_VALUE(TO_NUMBER(TRIM(numBouquet))  IGNORE NULLS)
               OVER (ORDER BY id_ligne)  AS bqt,
           TRIM(nomFleur)                AS nomFleur,
           TO_NUMBER(TRIM(nbrFleurs))    AS qte
    FROM   TMP_COMPOSITIONS
)
WHERE nomFleur IS NOT NULL;

COMMIT;


-- =====================================================================
--  ETAPE G - Achats chez les grossistes
-- =====================================================================

INSERT INTO ACHAT (numSIREN, nomFleur, dateAchat, prixAchatUnitaire, nbrFleurs)
SELECT TRIM(numSIREN),
       TRIM(nomFleur),
       TO_DATE(TRIM(dateAchat), 'DD/MM/YYYY'),
       TO_NUMBER(TRIM(prixAchatUnitaire)),
       TO_NUMBER(TRIM(nbrFleurs))
FROM   TMP_ACHATS
WHERE  numSIREN IS NOT NULL;

COMMIT;


-- =====================================================================
--  ETAPE H - Verifications
--
--  Volumes attendus :
--    FLEUR 25 | GROSSISTE 8 | LOCALITE 51 | CLIENT 125
--    COMMANDE 500 | BOUQUET 1282 | COMPOSITION 3917 | ACHAT 1823
-- =====================================================================

SELECT 'FLEUR'       AS table_chargee, COUNT(*) AS lignes FROM FLEUR
UNION ALL SELECT 'GROSSISTE',   COUNT(*) FROM GROSSISTE
UNION ALL SELECT 'LOCALITE',    COUNT(*) FROM LOCALITE
UNION ALL SELECT 'CLIENT',      COUNT(*) FROM CLIENT
UNION ALL SELECT 'COMMANDE',    COUNT(*) FROM COMMANDE
UNION ALL SELECT 'BOUQUET',     COUNT(*) FROM BOUQUET
UNION ALL SELECT 'COMPOSITION', COUNT(*) FROM COMPOSITION
UNION ALL SELECT 'ACHAT',       COUNT(*) FROM ACHAT;

-- Repartition livraison / retrait en magasin : 366 livrees, 134 retraits
SELECT CASE WHEN codePostalLivraison IS NULL
            THEN 'Retrait en magasin'
            ELSE 'Livraison' END AS mode,
       COUNT(*)                  AS nb_commandes
FROM   COMMANDE
GROUP BY CASE WHEN codePostalLivraison IS NULL
              THEN 'Retrait en magasin'
              ELSE 'Livraison' END;


-- =====================================================================
--  ETAPE I - Nettoyage
--
--  Les tables de travail n'ont plus d'utilite une fois les
--  verifications passees.
-- =====================================================================

DROP TABLE TMP_FLEURS;
DROP TABLE TMP_GROSSISTES;
DROP TABLE TMP_LIVRAISONS;
DROP TABLE TMP_ACHATS;
DROP TABLE TMP_COMMANDES;
DROP TABLE TMP_COMPOSITIONS;
