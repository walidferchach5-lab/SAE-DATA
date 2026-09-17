-- =====================================================================
--  Jardin de Charlotte - SAE S1.04
--  01 - Creation du schema relationnel (Oracle)
--
--  Traduction du MCD (docs/mcd.png) en modele physique Oracle.
--  Les tables sont creees dans l'ordre des dependances : les
--  referentiels d'abord, puis les commandes, puis leur detail.
--
--  Repond a la question 4 du sujet (+ question 3 pour les contraintes
--  d'integrite non prises en charge par le MCD, signalees par "CI :").
-- =====================================================================


-- ---------------------------------------------------------------------
-- FLEUR  <- entite FLEUR
-- Catalogue des fleurs vendues. Le tarif de vente est unique et
-- constant pour une fleur donnee, contrairement au prix d'achat qui est
-- releve a chaque achat (voir la table ACHAT).
-- ---------------------------------------------------------------------
CREATE TABLE FLEUR (
    nomFleur    VARCHAR2(50),
    tarifFleur  NUMBER(5,2) NOT NULL,
    CONSTRAINT pk_fleur        PRIMARY KEY (nomFleur),
    -- CI : un prix de vente ne peut pas etre negatif.
    CONSTRAINT ck_fleur_tarif  CHECK (tarifFleur >= 0)
);


-- ---------------------------------------------------------------------
-- GROSSISTE  <- entite GROSSISTE
-- Fournisseurs aupres desquels la fleuriste achete ses fleurs chaque
-- matin. Identifies par leur numero SIREN.
-- ---------------------------------------------------------------------
CREATE TABLE GROSSISTE (
    numSIREN  VARCHAR2(20),
    nom       VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_grossiste  PRIMARY KEY (numSIREN)
);


-- ---------------------------------------------------------------------
-- LOCALITE  <- entite LOCALITE
-- Communes livrables (Lyon et metropole) et tarif de livraison qui leur
-- est applicable. Le code postal sert d'identifiant : dans le jeu de
-- donnees fourni, un code postal correspond a une seule commune.
-- ---------------------------------------------------------------------
CREATE TABLE LOCALITE (
    codePostal      VARCHAR2(5),
    ville           VARCHAR2(50),
    tarifLivraison  NUMBER(5,2) NOT NULL,
    CONSTRAINT pk_localite        PRIMARY KEY (codePostal),
    -- CI : un tarif de livraison est positif ou nul (livraison offerte).
    CONSTRAINT ck_localite_tarif  CHECK (tarifLivraison >= 0)
);


-- ---------------------------------------------------------------------
-- CLIENT  <- entite CLIENT
-- Coordonnees du client, saisies une seule fois puis reutilisees.
-- L'adresse mail sert d'identifiant naturel : c'est par ce canal que la
-- facture pour solde de tout compte est envoyee.
-- ---------------------------------------------------------------------
CREATE TABLE CLIENT (
    mailClient        VARCHAR2(150),
    nomClient         VARCHAR2(100) NOT NULL,
    adresseClient     VARCHAR2(150),
    codePostalClient  VARCHAR2(5),
    villeClient       VARCHAR2(50),
    numTelClient      VARCHAR2(20),
    CONSTRAINT pk_client  PRIMARY KEY (mailClient)
);


-- ---------------------------------------------------------------------
-- ACHAT  <- association ACHETER (GROSSISTE 0,n <-> 0,n FLEUR)
-- Un releve par jour, par grossiste et par type de fleur : la fleuriste
-- enregistre chaque matin ce qu'elle a achete et a quel prix, dans un
-- souci de suivi de ses couts.
-- La date fait partie de la cle : le meme grossiste peut revendre la
-- meme fleur un autre jour, a un autre prix.
-- ---------------------------------------------------------------------
CREATE TABLE ACHAT (
    numSIREN           VARCHAR2(20),
    nomFleur           VARCHAR2(50),
    dateAchat          DATE,
    prixAchatUnitaire  NUMBER(5,2) NOT NULL,
    nbrFleurs          NUMBER(5)   NOT NULL,
    CONSTRAINT pk_achat            PRIMARY KEY (numSIREN, nomFleur, dateAchat),
    CONSTRAINT fk_achat_grossiste  FOREIGN KEY (numSIREN) REFERENCES GROSSISTE(numSIREN),
    CONSTRAINT fk_achat_fleur      FOREIGN KEY (nomFleur) REFERENCES FLEUR(nomFleur),
    -- CI : un prix d'achat est positif, une quantite achetee est non nulle.
    CONSTRAINT ck_achat_prix       CHECK (prixAchatUnitaire >= 0),
    CONSTRAINT ck_achat_nbr        CHECK (nbrFleurs > 0)
);


-- ---------------------------------------------------------------------
-- COMMANDE  <- entite COMMANDE
--             + association PASSER   (report de mailClient)
--             + association LIVRER_A (report de codePostalLivraison)
--
-- Les coordonnees du destinataire sont portees par la commande et non
-- par le client : elles changent d'une commande a l'autre (bouquet
-- offert, livraison sur un lieu de travail, etc.). C'est aussi pourquoi
-- une commande ne comporte qu'un seul point de livraison.
--
-- Conventions de lecture des valeurs NULL, telles qu'elles decoulent du
-- sujet :
--   datePaiement           NULL -> commande en attente, non reglee,
--                                  donc non livrable
--   dateLivraisonEffective NULL -> commande pas encore soldee
--   codePostalLivraison    NULL -> retrait en magasin, pas de frais
-- ---------------------------------------------------------------------
CREATE TABLE COMMANDE (
    numCommande             NUMBER(5),
    mailClient              VARCHAR2(150) NOT NULL,
    dateCommande            DATE          NOT NULL,
    datePaiement            DATE,
    dateRealisation         DATE,
    dateLivraisonEffective  DATE,
    nomDestinataire         VARCHAR2(100),
    adresseDestinataire     VARCHAR2(150),
    villeDestinataire       VARCHAR2(50),
    telDestinataire         VARCHAR2(20),
    codePostalLivraison     VARCHAR2(5),
    CONSTRAINT pk_commande      PRIMARY KEY (numCommande),
    CONSTRAINT fk_cmd_client    FOREIGN KEY (mailClient)          REFERENCES CLIENT(mailClient),
    CONSTRAINT fk_cmd_localite  FOREIGN KEY (codePostalLivraison) REFERENCES LOCALITE(codePostal),

    -- CI non representables dans le MCD : coherence chronologique.
    -- Rappel : un CHECK est satisfait des qu'une des colonnes comparees
    -- est NULL. Les commandes non payees ou non livrees passent donc
    -- ces controles sans etre rejetees.

    -- Les bouquets ne sont jamais realises le jour meme : la fleuriste
    -- doit d'abord acheter le lendemain matin les fleurs necessaires.
    CONSTRAINT ck_cmd_realisation  CHECK (dateRealisation        >  dateCommande),
    -- On ne peut pas regler une commande avant de l'avoir passee.
    CONSTRAINT ck_cmd_paiement     CHECK (datePaiement           >= dateCommande),
    -- On ne peut pas livrer avant d'avoir commande...
    CONSTRAINT ck_cmd_livraison    CHECK (dateLivraisonEffective >= dateCommande),
    -- ... ni avant que les bouquets ne soient confectionnes.
    CONSTRAINT ck_cmd_liv_real     CHECK (dateLivraisonEffective >= dateRealisation)
);


-- ---------------------------------------------------------------------
-- BOUQUET  <- entite faible BOUQUET, identifiee relativement a COMMANDE
-- Les bouquets sont numerotes au sein de la commande : le bouquet 1 de
-- la commande 12 n'a rien a voir avec le bouquet 1 de la commande 13.
-- La cle est donc composee. nbrBouquets porte le nombre d'exemplaires
-- identiques commandes ("3 bouquets de type 1, 1 de type 2").
-- ---------------------------------------------------------------------
CREATE TABLE BOUQUET (
    numCommande  NUMBER(5),
    numBouquet   NUMBER(3),
    nbrBouquets  NUMBER(3) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_bouquet  PRIMARY KEY (numCommande, numBouquet),
    CONSTRAINT fk_bqt_cmd  FOREIGN KEY (numCommande) REFERENCES COMMANDE(numCommande),
    -- CI : commander zero exemplaire d'un bouquet n'a pas de sens.
    CONSTRAINT ck_bqt_nbr  CHECK (nbrBouquets > 0)
);


-- ---------------------------------------------------------------------
-- COMPOSITION  <- association COMPOSER (BOUQUET 1,n <-> 0,n FLEUR)
-- Recette du bouquet, c'est-a-dire la liste remise aux employes le
-- matin. Une fleur n'apparait qu'une fois par bouquet, d'ou sa presence
-- dans la cle primaire.
-- ---------------------------------------------------------------------
CREATE TABLE COMPOSITION (
    numCommande  NUMBER(5),
    numBouquet   NUMBER(3),
    nomFleur     VARCHAR2(50),
    quantite     NUMBER(3) NOT NULL,
    CONSTRAINT pk_composition   PRIMARY KEY (numCommande, numBouquet, nomFleur),
    CONSTRAINT fk_comp_bouquet  FOREIGN KEY (numCommande, numBouquet)
                                REFERENCES BOUQUET(numCommande, numBouquet),
    CONSTRAINT fk_comp_fleur    FOREIGN KEY (nomFleur) REFERENCES FLEUR(nomFleur),
    -- CI : une fleur listee dans une composition y figure au moins une fois.
    CONSTRAINT ck_comp_quantite CHECK (quantite > 0)
);


-- ---------------------------------------------------------------------
-- Index sur les cles etrangeres les plus sollicitees par les requetes
-- de la partie 2 : Oracle cree un index pour les cles primaires, mais
-- pas pour les cles etrangeres.
-- ---------------------------------------------------------------------
CREATE INDEX ix_cmd_client   ON COMMANDE(mailClient);
CREATE INDEX ix_cmd_localite ON COMMANDE(codePostalLivraison);
CREATE INDEX ix_comp_fleur   ON COMPOSITION(nomFleur);
CREATE INDEX ix_achat_fleur  ON ACHAT(nomFleur);

COMMIT;
