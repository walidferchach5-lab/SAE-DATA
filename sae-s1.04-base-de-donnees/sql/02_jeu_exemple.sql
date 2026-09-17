-- =====================================================================
--  Jardin de Charlotte - SAE S1.04
--  02 - Insertion du cas decrit dans le sujet (question 5)
--
--  Enonce :
--    Mme Juliette se presente au magasin le 01/10/2025 pour commander
--    deux bouquets, chacun constitue de dix roses et six tulipes. Ils
--    sont a livrer le 05/10/2025 a M. Jean, 60 grande rue, 69100
--    Villeurbanne, joignable au 0789012345. Chaque rose est vendue
--    2,00 EUR et chaque tulipe 1,50 EUR ; la livraison a Villeurbanne
--    coute 6,00 EUR. Mme Juliette paye le jour meme ; elle est
--    joignable au 0607890123, habite 7 rue du general Leclerc a
--    Villeurbanne, mail juliette@laposte.net.
--
--  Montant de cette commande :
--    bouquet  = 10 x 2,00 + 6 x 1,50 = 29,00 EUR
--    2 bouquets                      = 58,00 EUR
--    + livraison Villeurbanne        = 64,00 EUR
--
--  L'ordre des insertions suit les cles etrangeres : referentiels,
--  puis client, puis commande, puis bouquet, puis composition.
--
--  Note : le 05/10/2025 est la date de livraison *souhaitee*. Le modele
--  ne stocke que la date de livraison effective, qui reste donc NULL
--  tant que le transporteur n'a pas rapporte le bon de livraison signe.
--  La date de realisation est fixee a la veille de la livraison prevue.
--
--  ATTENTION - ordre d'execution
--  Ce script s'execute sur un schema vide, juste apres 01_schema.sql.
--  Il n'est pas cumulable avec 03_import_donnees.sql : le jeu de
--  donnees du binome utilise lui aussi les numeros de commande 1 a 500,
--  ainsi que les fleurs Rose / Tulipe et le code postal 69100.
--  Pour enchainer les deux, repasser par 00_drop.sql entre les deux.
-- =====================================================================


-- --- Referentiels ----------------------------------------------------

INSERT INTO LOCALITE (codePostal, ville, tarifLivraison)
VALUES ('69100', 'Villeurbanne', 6.00);

INSERT INTO FLEUR (nomFleur, tarifFleur) VALUES ('Rose',   2.00);
INSERT INTO FLEUR (nomFleur, tarifFleur) VALUES ('Tulipe', 1.50);


-- --- La cliente ------------------------------------------------------

INSERT INTO CLIENT (
    mailClient,
    nomClient,
    adresseClient,
    codePostalClient,
    villeClient,
    numTelClient
) VALUES (
    'juliette@laposte.net',
    'Mme Juliette',
    '7, rue du general Leclerc',
    '69100',
    'Villeurbanne',
    '0607890123'
);


-- --- La commande -----------------------------------------------------

INSERT INTO COMMANDE (
    numCommande,
    mailClient,
    dateCommande,
    datePaiement,
    dateRealisation,
    dateLivraisonEffective,
    nomDestinataire,
    adresseDestinataire,
    villeDestinataire,
    telDestinataire,
    codePostalLivraison
) VALUES (
    1,
    'juliette@laposte.net',
    TO_DATE('01/10/2025', 'DD/MM/YYYY'),  -- commande passee au magasin
    TO_DATE('01/10/2025', 'DD/MM/YYYY'),  -- reglee le jour meme
    TO_DATE('04/10/2025', 'DD/MM/YYYY'),  -- bouquets confectionnes la veille
    NULL,                                 -- pas encore livree
    'M. Jean',
    '60 grande rue',
    'Villeurbanne',
    '0789012345',
    '69100'
);


-- --- Les deux bouquets identiques ------------------------------------
-- Un seul bouquet "type 1", commande en deux exemplaires.

INSERT INTO BOUQUET (numCommande, numBouquet, nbrBouquets)
VALUES (1, 1, 2);


-- --- Sa composition --------------------------------------------------

INSERT INTO COMPOSITION (numCommande, numBouquet, nomFleur, quantite)
VALUES (1, 1, 'Rose', 10);

INSERT INTO COMPOSITION (numCommande, numBouquet, nomFleur, quantite)
VALUES (1, 1, 'Tulipe', 6);

COMMIT;


-- --- Verification ----------------------------------------------------
-- Doit retourner 64 EUR pour la commande 1.

SELECT cmd.numCommande,
       cl.nomClient,
       SUM(f.tarifFleur * c.quantite * b.nbrBouquets)                        AS montantBrut,
       NVL(l.tarifLivraison, 0)                                              AS fraisLivraison,
       SUM(f.tarifFleur * c.quantite * b.nbrBouquets) + NVL(l.tarifLivraison, 0) AS montantNet
FROM       COMMANDE    cmd
JOIN       CLIENT      cl ON cl.mailClient  = cmd.mailClient
JOIN       BOUQUET     b  ON b.numCommande  = cmd.numCommande
JOIN       COMPOSITION c  ON c.numCommande  = b.numCommande
                         AND c.numBouquet   = b.numBouquet
JOIN       FLEUR       f  ON f.nomFleur     = c.nomFleur
LEFT JOIN  LOCALITE    l  ON l.codePostal   = cmd.codePostalLivraison
WHERE cmd.numCommande = 1
GROUP BY cmd.numCommande, cl.nomClient, l.tarifLivraison;
